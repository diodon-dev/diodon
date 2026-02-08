/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2011-2013 Diodon Team <diodon-team@lists.launchpad.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
 * License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Diodon
{
    /**
     * Global LRU (Least Recently Used) cache for image PNG data.
     *
     * Replaces the fragile two-tier caching (instance _cached_png +
     * static single-slot cache) with a single bounded cache.
     *
     * Designed for immutability: all data stored as GLib.Bytes
     * (ref-counted, zero-copy sharing). Hard memory limit prevents
     * unbounded growth — evicts least-recently-used entries when full.
     *
     * Typical usage: 64 MB limit ≈ 6 cached 4K PNG images.
     * Only the actively-served image needs to be in cache;
     * everything else is fetched from Zeitgeist on demand.
     */
    public class ImageCache : GLib.Object
    {
        /** Default hard limit: 64 MB */
        public const int64 DEFAULT_MAX_BYTES = 64 * 1024 * 1024;

        /**
         * A single cache entry: PNG data keyed by content checksum.
         */
        private class CacheEntry
        {
            public string checksum;
            public GLib.Bytes png_data;
            public int width;
            public int height;
            public int64 size;

            public CacheEntry(string checksum, GLib.Bytes png_data, int width, int height)
            {
                this.checksum = checksum;
                this.png_data = png_data;
                this.width = width;
                this.height = height;
                this.size = (int64) png_data.get_size();
            }
        }

        // LRU ordering: checksums from most-recently-used (head)
        // to least-recently-used (tail). Used for eviction.
        private GLib.Queue<string> _lru_order;

        // O(1) lookup by checksum
        private GLib.HashTable<string, CacheEntry> _entries;

        // Current total bytes of all cached PNG data
        private int64 _current_bytes;

        // Hard memory limit
        private int64 _max_bytes;

        // Singleton instance
        private static ImageCache? _instance = null;

        /**
         * Get the global singleton cache instance.
         *
         * Thread-safe: GLib guarantees static variable initialization
         * is atomic on POSIX. All callers share one cache.
         */
        public static ImageCache get_default()
        {
            if (_instance == null) {
                _instance = new ImageCache(DEFAULT_MAX_BYTES);
            }
            return _instance;
        }

        /**
         * Create a cache with the given byte limit.
         * Prefer get_default() for production; this constructor
         * exists for testing with custom limits.
         */
        public ImageCache(int64 max_bytes)
        {
            _max_bytes = max_bytes;
            _current_bytes = 0;
            _lru_order = new GLib.Queue<string>();
            _entries = new GLib.HashTable<string, CacheEntry>(
                GLib.str_hash, GLib.str_equal);
        }

        /**
         * Insert or update a PNG entry in the cache.
         * Evicts least-recently-used entries until the new entry fits
         * within the memory limit.
         *
         * @param checksum content checksum (SHA1 of raw pixels)
         * @param png_data immutable PNG bytes (GLib.Bytes for zero-copy)
         * @param width original image width in pixels
         * @param height original image height in pixels
         */
        public void put(string checksum, GLib.Bytes png_data, int width, int height)
        {
            // Remove existing entry first (updates LRU position)
            remove(checksum);

            var entry = new CacheEntry(checksum, png_data, width, height);

            // Don't cache entries larger than the entire limit
            if (entry.size > _max_bytes) {
                debug("Image %s exceeds cache limit, not caching", checksum);
                return;
            }

            // Evict LRU entries until there's room
            while (_current_bytes + entry.size > _max_bytes && _lru_order.length > 0) {
                evict_oldest();
            }

            _lru_order.push_head(checksum);
            _entries[checksum] = entry;
            _current_bytes += entry.size;

            debug("Cache put: %s (%dx%d). Entries: %u",
                  checksum, width, height, _lru_order.length);
        }

        /**
         * Retrieve PNG bytes by checksum, promoting to most-recently-used.
         * Returns null on cache miss.
         *
         * @param checksum content checksum to look up
         * @return immutable PNG bytes, or null if not cached
         */
        public GLib.Bytes? get_png(string checksum)
        {
            CacheEntry? entry = _entries[checksum];
            if (entry == null) {
                return null;
            }

            // Promote to MRU: remove from current position, push to head
            // GLib.Queue.remove is O(n) but n ≤ 6 for typical 64MB / 10MB images
            _lru_order.remove(checksum);
            _lru_order.push_head(checksum);

            return entry.png_data;
        }

        /**
         * Get cached image dimensions without promoting in LRU.
         * Useful for label generation without triggering eviction changes.
         *
         * @param checksum content checksum
         * @param width output: image width, 0 if not cached
         * @param height output: image height, 0 if not cached
         * @return true if entry found
         */
        public bool get_dimensions(string checksum, out int width, out int height)
        {
            width = 0;
            height = 0;
            CacheEntry? entry = _entries[checksum];
            if (entry == null) {
                return false;
            }
            width = entry.width;
            height = entry.height;
            return true;
        }

        /**
         * Check if a checksum is present in the cache.
         */
        public bool contains(string checksum)
        {
            return _entries.contains(checksum);
        }

        /**
         * Remove a specific entry from the cache.
         */
        public void remove(string checksum)
        {
            CacheEntry? entry = _entries[checksum];
            if (entry == null) {
                return;
            }
            _current_bytes -= entry.size;
            _lru_order.remove(checksum);
            _entries.remove(checksum);
        }

        /**
         * Clear all entries and reset memory counter.
         */
        public void clear()
        {
            _lru_order.clear();
            _entries.remove_all();
            _current_bytes = 0;
            clear_warm_pixbuf();
        }

        /**
         * Evict the least-recently-used entry.
         */
        private void evict_oldest()
        {
            string? oldest = _lru_order.pop_tail();
            if (oldest != null) {
                CacheEntry? entry = _entries[oldest];
                if (entry != null) {
                    debug("Cache evict: %s", oldest);
                    _current_bytes -= entry.size;
                    _entries.remove(oldest);
                }
            }
        }

        // === Speculative Pixbuf Warm-up ===
        // Single-slot cache: holds ONE pre-decoded pixbuf for the item
        // the user is currently hovering over in the menu. Eliminates
        // the decode latency when they click to paste.
        private string? _warm_checksum = null;
        private Gdk.Pixbuf? _warm_pixbuf = null;

        /**
         * Speculatively decode the pixbuf for the given checksum.
         *
         * Called from an idle callback when the user hovers over an
         * image menu item. Decodes PNG → pixbuf so it's ready when
         * to_clipboard() or clipboard_get_func() needs it.
         *
         * Only ONE warm pixbuf is held at a time (~33 MB for 4K).
         * Decoding a new checksum releases the previous one.
         *
         * @param checksum content checksum to pre-decode
         */
        public void warm_pixbuf(string checksum)
        {
            // Already warmed for this checksum?
            if (_warm_checksum == checksum && _warm_pixbuf != null) {
                return;
            }

            // Release previous warm pixbuf
            _warm_pixbuf = null;
            _warm_checksum = null;

            // Get PNG from cache; can't warm without data
            GLib.Bytes? png = get_png(checksum);
            if (png == null) {
                debug("Warm pixbuf: no PNG cached for %s", checksum);
                return;
            }

            // Decode PNG → pixbuf
            try {
                unowned uint8[] data = png.get_data();
                Gdk.PixbufLoader loader = new Gdk.PixbufLoader();
                loader.write(data);
                loader.close();
                _warm_pixbuf = loader.get_pixbuf();
                _warm_checksum = checksum;
                debug("Warm pixbuf ready: %s (%dx%d)", checksum,
                      _warm_pixbuf.width, _warm_pixbuf.height);
            } catch (GLib.Error e) {
                warning("Warm pixbuf decode failed for %s: %s", checksum, e.message);
            }
        }

        /**
         * Get the speculatively decoded pixbuf, if available.
         *
         * Returns the pre-decoded pixbuf only if it matches the
         * requested checksum. Returns null on mismatch or if
         * no warm-up has been performed.
         *
         * @param checksum content checksum to look up
         * @return decoded pixbuf, or null
         */
        public Gdk.Pixbuf? get_warm_pixbuf(string checksum)
        {
            if (_warm_checksum == checksum) {
                return _warm_pixbuf;
            }
            return null;
        }

        /**
         * Clear the speculative pixbuf cache.
         * Called on cache clear or when warm-up is no longer needed.
         */
        public void clear_warm_pixbuf()
        {
            _warm_pixbuf = null;
            _warm_checksum = null;
        }

        /** Current total cached bytes */
        public int64 get_current_bytes() { return _current_bytes; }

        /** Configured maximum bytes */
        public int64 get_max_bytes() { return _max_bytes; }

        /** Number of entries in cache */
        public uint get_entry_count() { return _lru_order.length; }
    }
}
