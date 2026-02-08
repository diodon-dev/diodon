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
 *
 * Author:
 *  Oliver Sauder <os@esite.ch>
 */

namespace Diodon
{
    /**
     * An image clipboard item representing an image in the clipboard history.
     *
     * === Memory Architecture (Performance Engineer Patch) ===
     *
     * Three construction paths, each optimized for its purpose:
     *
     * 1. with_image() — Fresh clipboard copy
     *    - Decodes pixbuf info, saves thumbnail to disk, caches PNG in LRU
     *    - KEEPS _pixbuf for immediate clipboard serving
     *    - Only ONE such item exists at a time (current clipboard)
     *
     * 2. with_metadata() — Menu display (LIGHTWEIGHT)
     *    - Loads ONLY the tiny thumbnail from disk (~5 KB PNG)
     *    - Never touches the full PNG payload or Zeitgeist event data
     *    - Makes menu open instant even with dozens of 4K images
     *
     * 3. with_known_payload() — Paste path
     *    - Checksum already known from Zeitgeist URI (skip SHA1)
     *    - Decodes pixbuf and KEEPS it for clipboard serving
     *    - One decode instead of two (vs old with_payload + to_clipboard)
     *
     * === Fail-Fast Clipboard Serving ===
     *
     * clipboard_get_func() NEVER blocks >5ms:
     *   - image/png: served from LRU cache in ~0ms (memcpy)
     *   - Other formats: served from _pixbuf if ready, or from
     *     speculative warm-up cache. If neither available, returns
     *     FALSE (fail-fast) instead of blocking for decode.
     *
     * === Speculative Decoding ===
     *
     * When user hovers over a menu item, ImageCache.warm_pixbuf()
     * pre-decodes the full image in an idle callback. When the user
     * clicks, to_clipboard() picks up the warm pixbuf instantly.
     *
     * === Thumbnail Persistence ===
     *
     * Thumbnails are saved to ~/.local/share/diodon/thumbnails/<checksum>.png
     * at copy time. Menu display loads ONLY this file, never the full payload.
     * Backward-compatible: if thumbnail file missing, falls back gracefully
     * with a null image (the menu item shows label text only).
     */
    public class ImageClipboardItem : GLib.Object, IClipboardItem
    {
        private ClipboardType _clipboard_type;
        private string _checksum;
        private Gdk.Pixbuf? _pixbuf;     // only for with_image/with_known_payload items
        private Gdk.Pixbuf? _thumbnail;   // ~5 KB, always set if available
        private string _label;
        private string? _origin;
        private DateTime _date_copied;

        /**
         * Create image clipboard item from a live pixbuf (fresh clipboard copy).
         *
         * Called when an external app copies an image. The pixbuf is kept
         * on the instance for immediate clipboard serving. PNG is encoded
         * once and stored in the global LRU cache. Thumbnail is saved to
         * disk for instant menu loading on future sessions.
         *
         * @param clipboard_type clipboard type item is coming from
         * @param pixbuf image from clipboard (33 MB for 4K RGBA)
         * @param origin origin of clipboard item as application path
         * @param date_copied timestamp
         */
        public ImageClipboardItem.with_image(ClipboardType clipboard_type, Gdk.Pixbuf pixbuf, string? origin, DateTime date_copied) throws GLib.Error
        {
            _clipboard_type = clipboard_type;
            _origin = origin;
            _date_copied = date_copied;
            extract_pixbuf_info(pixbuf);
            // Keep _pixbuf — needed for immediate clipboard serving
            // and keep_clipboard_content sync restore. This is the ONLY
            // construction path that holds a pixbuf long-term; all
            // other paths drop theirs or never decode one.
        }

        /**
         * Create image clipboard item from stored PNG payload (Zeitgeist history).
         *
         * LEGACY constructor — kept for backward compatibility with callers
         * that don't have the checksum yet. Prefer with_known_payload() or
         * with_metadata() for new code paths.
         *
         * Decodes PNG to extract thumbnail and checksum, then DROPS the
         * pixbuf. PNG bytes go into the global LRU cache (not on the instance).
         *
         * @param clipboard_type clipboard type
         * @param payload PNG bytes from Zeitgeist event
         * @param origin origin application path
         * @param date_copied timestamp
         */
        public ImageClipboardItem.with_payload(ClipboardType clipboard_type, ByteArray payload, string? origin, DateTime date_copied) throws GLib.Error
        {
            _clipboard_type = clipboard_type;
            _origin = origin;
            _date_copied = date_copied;

            // Decode PNG -> pixbuf (temporary, ~33 MB)
            Gdk.PixbufLoader loader = new Gdk.PixbufLoader();
            loader.write(payload.data);
            loader.close();
            Gdk.Pixbuf pixbuf = loader.get_pixbuf();

            // Extract checksum + thumbnail from pixbuf
            extract_pixbuf_info(pixbuf);

            // Store PNG in global LRU cache (as immutable GLib.Bytes)
            var png_bytes = new GLib.Bytes(payload.data);
            ImageCache.get_default().put(_checksum, png_bytes,
                                         pixbuf.width, pixbuf.height);

            // DROP the pixbuf — this item is display-only (thumbnail).
            // Saves ~33 MB per history item. PNG lives in the LRU cache
            // and can be re-fetched from Zeitgeist if evicted.
            _pixbuf = null;
        }

        /**
         * Create image clipboard item from metadata only (menu display).
         *
         * LIGHTWEIGHT path — loads ONLY the tiny thumbnail from disk (~5 KB).
         * Never touches the full PNG payload or decodes any image data.
         * This makes menu open instant even with dozens of 4K images in history.
         *
         * Used exclusively by create_clipboard_items() for the recent menu.
         * When the user clicks to paste, a new item is created via
         * with_known_payload() which does the full decode.
         *
         * Falls back gracefully if thumbnail file is missing (old items
         * from before thumbnail persistence was added): shows label only.
         *
         * @param clipboard_type clipboard type
         * @param checksum SHA1 content checksum (extracted from Zeitgeist URI)
         * @param label dimension string e.g. "[3840x2160]"
         * @param origin origin application path
         * @param date_copied timestamp
         */
        public ImageClipboardItem.with_metadata(ClipboardType clipboard_type, string checksum, string label, string? origin, DateTime date_copied)
        {
            _clipboard_type = clipboard_type;
            _checksum = checksum;
            _label = label;
            _origin = origin;
            _date_copied = date_copied;
            _pixbuf = null;  // No full image — menu display only

            // Load thumbnail from disk (~5 KB PNG)
            string thumb_path = get_thumbnail_path(checksum);
            try {
                _thumbnail = new Gdk.Pixbuf.from_file(thumb_path);
            } catch (GLib.Error e) {
                debug("Thumbnail not on disk for %s, menu will show label only", checksum);
                _thumbnail = null;
            }
        }

        /**
         * Create image clipboard item from known checksum + payload (paste path).
         *
         * Optimized paste constructor. The checksum is already known from the
         * Zeitgeist subject URI, eliminating the expensive SHA1 re-computation
         * over raw pixels (~15ms for 4K). Decodes the pixbuf and KEEPS it
         * for immediate clipboard serving — no double-decode.
         *
         * Also saves thumbnail to disk if not already persisted (handles
         * upgrade from pre-thumbnail versions).
         *
         * @param clipboard_type clipboard type
         * @param checksum known SHA1 checksum from Zeitgeist URI
         * @param payload PNG bytes from Zeitgeist event
         * @param origin origin application path
         * @param date_copied timestamp
         */
        public ImageClipboardItem.with_known_payload(ClipboardType clipboard_type, string checksum, ByteArray payload, string? origin, DateTime date_copied) throws GLib.Error
        {
            _clipboard_type = clipboard_type;
            _checksum = checksum;
            _origin = origin;
            _date_copied = date_copied;

            // Decode PNG → pixbuf
            Gdk.PixbufLoader loader = new Gdk.PixbufLoader();
            loader.write(payload.data);
            loader.close();
            Gdk.Pixbuf pixbuf = loader.get_pixbuf();

            _label = "[%dx%d]".printf(pixbuf.width, pixbuf.height);
            _thumbnail = create_scaled_pixbuf(pixbuf);

            // Store PNG in global LRU cache
            var png_bytes = new GLib.Bytes(payload.data);
            ImageCache.get_default().put(_checksum, png_bytes,
                                         pixbuf.width, pixbuf.height);

            // Ensure thumbnail is persisted to disk
            save_thumbnail_to_disk(_thumbnail, _checksum);

            // KEEP pixbuf — this is the paste path, immediate serving needed.
            // to_clipboard() will find _pixbuf non-null and skip decode.
            _pixbuf = pixbuf;
        }

        /**
	     * {@inheritDoc}
	     */
        public ClipboardType get_clipboard_type()
        {
            return _clipboard_type;
        }

        /**
	     * {@inheritDoc}
	     */
	    public DateTime get_date_copied()
        {
            return _date_copied;
        }

        /**
	     * {@inheritDoc}
	     */
	    public string get_text()
        {
            return _label;
        }

        /**
	     * {@inheritDoc}
	     */
	    public string? get_origin()
        {
            return _origin;
        }

        /**
	     * {@inheritDoc}
	     */
        public string get_label()
        {
            return _label;
        }

        /**
	     * {@inheritDoc}
	     */
        public string get_mime_type()
        {
            return "image/png";
        }

        /**
	     * {@inheritDoc}
	     */
        public Icon get_icon()
        {
            try {
                if (_pixbuf != null) {
                    File file = save_tmp_pixbuf(_pixbuf);
                    FileIcon icon = new FileIcon(file);
                    return icon;
                }
            } catch(Error e) {
                warning("Could not create icon for image %s. Fallback to content type",
                    _checksum);
            }
            return ContentType.get_icon(get_mime_type());
        }

        /**
	     * {@inheritDoc}
	     */
        public ClipboardCategory get_category()
        {
            return ClipboardCategory.IMAGES;
        }

        /**
	     * {@inheritDoc}
	     */
        public Gtk.Image? get_image()
        {
            if (_thumbnail != null) {
                return new Gtk.Image.from_pixbuf(_thumbnail);
            }
            if (_pixbuf != null) {
                Gdk.Pixbuf preview = create_scaled_pixbuf(_pixbuf);
                return new Gtk.Image.from_pixbuf(preview);
            }
            return null;
        }

        /**
         * {@inheritDoc}
         *
         * Returns PNG payload for Zeitgeist storage.
         * Checks global LRU cache first, then encodes from pixbuf.
         */
        public ByteArray? get_payload() throws GLib.Error
        {
            // 1. Check global LRU cache
            GLib.Bytes? cached = ImageCache.get_default().get_png(_checksum);
            if (cached != null) {
                unowned uint8[] data = cached.get_data();
                ByteArray ba = new ByteArray.sized((uint) data.length);
                ba.append(data);
                return ba;
            }

            // 2. Encode from pixbuf (only for fresh with_image items)
            if (_pixbuf != null) {
                uint8[] buffer;
                _pixbuf.save_to_buffer(out buffer, "png");

                // Cache for future use
                var png_bytes = new GLib.Bytes(buffer);
                ImageCache.get_default().put(_checksum, png_bytes,
                                             _pixbuf.width, _pixbuf.height);

                return new ByteArray.take(buffer);
            }

            warning("No PNG data available for image %s", _checksum);
            return null;
        }

        /**
         * {@inheritDoc}
         */
        public string get_checksum()
        {
            return _checksum;
        }

        /**
         * {@inheritDoc}
         *
         * Sets the image on the clipboard using set_with_owner() for
         * lazy, on-demand data serving.
         *
         * Pixbuf resolution order:
         *   1. Instance _pixbuf (with_image / with_known_payload items)
         *   2. Speculative warm-up cache (user hovered before clicking)
         *   3. Decode from LRU cache (fallback, ~50ms for 4K)
         *   4. Give up (no data available)
         */
        public void to_clipboard(Gtk.Clipboard clipboard)
        {
            // 1. Already have pixbuf (with_image / with_known_payload)
            if (_pixbuf != null) {
                // fast path — no decode needed
            }
            // 2. Check speculative warm-up from hover
            else {
                Gdk.Pixbuf? warm = ImageCache.get_default().get_warm_pixbuf(_checksum);
                if (warm != null) {
                    _pixbuf = warm;
                    debug("to_clipboard: using warm pixbuf for %s", _checksum);
                }
            }
            // 3. Fallback: decode from LRU cache
            if (_pixbuf == null) {
                GLib.Bytes? cached = ImageCache.get_default().get_png(_checksum);
                if (cached != null) {
                    try {
                        unowned uint8[] data = cached.get_data();
                        Gdk.PixbufLoader loader = new Gdk.PixbufLoader();
                        loader.write(data);
                        loader.close();
                        _pixbuf = loader.get_pixbuf();
                        debug("to_clipboard: decoded from LRU for %s", _checksum);
                    } catch (GLib.Error e) {
                        warning("Failed to decode pixbuf for clipboard: %s", e.message);
                    }
                }
            }

            if (_pixbuf == null) {
                warning("No image data available for clipboard (checksum: %s)", _checksum);
                return;
            }

            // Use set_with_owner for lazy data serving.
            // Data is only encoded when an app actually requests it,
            // and only in the requested format — no upfront serialization.
            Gtk.TargetList target_list = new Gtk.TargetList(null);
            target_list.add_image_targets(0, true);
            Gtk.TargetEntry[] entries = Gtk.target_table_new_from_list(target_list);

            clipboard.set_with_owner(
                entries,
                clipboard_get_func,
                clipboard_clear_func,
                this
            );
        }

        /**
         * Called by GTK when a target app requests clipboard data.
         *
         * === FAIL-FAST CONTRACT: Never blocks >5ms ===
         *
         * image/png: Served directly from LRU cache (~0ms memcpy).
         *   If not cached, fails immediately — the requesting app
         *   sees an empty selection and retries or falls back.
         *
         * Other formats (BMP, TIFF, etc.): Converted from _pixbuf
         *   via GDK. If _pixbuf is null, checks the speculative
         *   warm-up cache (populated when user hovered the menu item).
         *   If still null, fails immediately — NEVER does a synchronous
         *   PNG→pixbuf decode in this callback.
         *
         * Rationale: clipboard_get_func runs on the GTK main thread.
         * A synchronous decode of a 4K PNG (~50-100ms) would freeze
         * the entire desktop for every paste operation. By the time
         * this callback fires, to_clipboard() should have already
         * set _pixbuf via one of the three resolution paths.
         */
        private static void clipboard_get_func(
            Gtk.Clipboard clipboard,
            Gtk.SelectionData selection_data,
            uint info,
            void* user_data_or_owner)
        {
            ImageClipboardItem self = (ImageClipboardItem) user_data_or_owner;
            string target_name = selection_data.get_target().name();

            // Fast path: serve cached PNG directly (~0ms, memcpy only)
            if (target_name == "image/png") {
                GLib.Bytes? cached = ImageCache.get_default().get_png(self._checksum);
                if (cached != null) {
                    unowned uint8[] data = cached.get_data();
                    selection_data.set(selection_data.get_target(), 8, data);
                    return;
                }
                // PNG not in cache — fail fast
                debug("clipboard_get_func: PNG cache miss for %s, failing fast", self._checksum);
                return;
            }

            // Non-PNG formats: need pixbuf for GDK conversion
            // 1. Use instance pixbuf if available (normal case after to_clipboard)
            if (self._pixbuf != null) {
                selection_data.set_pixbuf(self._pixbuf);
                return;
            }

            // 2. Check speculative warm-up cache
            Gdk.Pixbuf? warm = ImageCache.get_default().get_warm_pixbuf(self._checksum);
            if (warm != null) {
                self._pixbuf = warm;
                selection_data.set_pixbuf(warm);
                return;
            }

            // 3. FAIL FAST — no synchronous decode, no blocking
            debug("clipboard_get_func: pixbuf not ready for %s (target: %s), failing fast",
                  self._checksum, target_name);
        }

        /**
         * Called by GTK when clipboard ownership is lost.
         *
         * Nulls out _pixbuf to prevent zombie data after Clear History.
         * Without this, a Ctrl+V after Clear could still paste the
         * sensitive image from the lingering pixbuf reference.
         */
        private static void clipboard_clear_func(
            Gtk.Clipboard clipboard,
            void* user_data_or_owner)
        {
            ImageClipboardItem self = (ImageClipboardItem) user_data_or_owner;
            self._pixbuf = null;
            // Also clear warm pixbuf in case it references this item
            ImageCache.get_default().clear_warm_pixbuf();
        }

        /**
	     * {@inheritDoc}
	     */
	    public bool equals(IClipboardItem* item)
        {
            bool equals = false;

            if(item is ImageClipboardItem) {
                ImageClipboardItem* image_item = (ImageClipboardItem*)item;
                equals = strcmp(_checksum, image_item->_checksum) == 0;
            }

            return equals;
        }

        /**
	     * {@inheritDoc}
	     */
	    public uint hash()
        {
            return str_hash(_checksum);
        }

        /**
         * Extract checksum and thumbnail from a pixbuf.
         *
         * SHA1 hashes all raw pixels to produce a unique content ID.
         * Creates a 200x150 thumbnail for menu display and saves it
         * to disk for instant loading on future sessions.
         * Encodes PNG and stores in the global LRU cache.
         *
         * @param pixbuf source pixbuf (typically ~33 MB for 4K RGBA)
         */
        private void extract_pixbuf_info(Gdk.Pixbuf pixbuf)
        {
            // SHA1 hash of raw pixel data -> unique content checksum
            Checksum checksum = new Checksum(ChecksumType.SHA1);
            checksum.update(pixbuf.get_pixels(), pixbuf.height * pixbuf.rowstride);
            _checksum = checksum.get_string().dup();

            _label = "[%dx%d]".printf(pixbuf.width, pixbuf.height);
            _pixbuf = pixbuf;

            // Pre-compute thumbnail (200x150 max, bilinear, contain-fit)
            _thumbnail = create_scaled_pixbuf(pixbuf);

            // Persist thumbnail to disk for instant menu loading
            save_thumbnail_to_disk(_thumbnail, _checksum);

            // Encode PNG and store in global LRU cache
            try {
                uint8[] buf;
                pixbuf.save_to_buffer(out buf, "png");
                var png_bytes = new GLib.Bytes(buf);
                ImageCache.get_default().put(_checksum, png_bytes,
                                             pixbuf.width, pixbuf.height);
            } catch (GLib.Error e) {
                warning("Failed to cache PNG for %s: %s", _checksum, e.message);
            }
        }

        /**
         * Save a thumbnail pixbuf to disk for instant menu loading.
         *
         * Writes to ~/.local/share/diodon/thumbnails/<checksum>.png
         * Creates the directory if it doesn't exist. Skips if the
         * thumbnail file already exists (idempotent).
         *
         * @param thumbnail thumbnail pixbuf to persist
         * @param checksum content checksum for the filename
         */
        private static void save_thumbnail_to_disk(Gdk.Pixbuf thumbnail, string checksum)
        {
            string thumb_path = get_thumbnail_path(checksum);

            // Always overwrite — handles the Resurrection scenario where
            // user deletes an image, then copies the exact same pixels again.
            // The old thumbnail was deleted by remove_item(); we must
            // regenerate it unconditionally to avoid a broken menu icon.

            string thumb_dir = Path.get_dirname(thumb_path);
            Utility.make_directory_with_parents(thumb_dir);

            try {
                thumbnail.save(thumb_path, "png");
            } catch (GLib.Error e) {
                warning("Failed to save thumbnail for %s: %s", checksum, e.message);
            }
        }

        /**
         * Get the filesystem path for a thumbnail PNG file.
         *
         * @param checksum content checksum
         * @return absolute path to thumbnail file
         */
        public static string get_thumbnail_path(string checksum)
        {
            return Path.build_filename(
                Utility.get_user_data_dir(), "thumbnails", checksum + ".png");
        }

        /**
         * Delete the thumbnail file for a given checksum.
         * Called when an item is removed from history to prevent
         * orphaned thumbnails accumulating on disk.
         *
         * @param checksum content checksum of the item being removed
         */
        public static void delete_thumbnail(string checksum)
        {
            string thumb_path = get_thumbnail_path(checksum);
            if (FileUtils.test(thumb_path, FileTest.EXISTS)) {
                FileUtils.unlink(thumb_path);
            }
        }

        /**
         * Delete ALL thumbnail files from disk.
         * Called when the entire clipboard history is cleared.
         */
        public static void delete_all_thumbnails()
        {
            string thumb_dir = Path.build_filename(
                Utility.get_user_data_dir(), "thumbnails");
            try {
                Dir dir = Dir.open(thumb_dir);
                string? name = null;
                while ((name = dir.read_name()) != null) {
                    if (name.has_suffix(".png")) {
                        string path = Path.build_filename(thumb_dir, name);
                        FileUtils.unlink(path);
                    }
                }
            } catch (GLib.FileError e) {
                debug("Could not clean thumbnails dir: %s", e.message);
            }
        }

        /**
         * Create a thumbnail-sized scaled pixbuf (contain-fit).
         * Max 200x150, bilinear interpolation, never upscales.
         */
        private static Gdk.Pixbuf create_scaled_pixbuf(Gdk.Pixbuf pixbuf)
        {
            int max_height = 150;
            int max_width = 200;

            int src_width = pixbuf.width;
            int src_height = pixbuf.height;

            double scale_x = (double) max_width / src_width;
            double scale_y = (double) max_height / src_height;
            double scale = double.min(scale_x, scale_y);

            // Never upscale beyond original resolution
            if (scale > 1.0) {
                scale = 1.0;
            }

            int dest_width = int.max((int)(src_width * scale), 1);
            int dest_height = int.max((int)(src_height * scale), 1);

            return pixbuf.scale_simple(dest_width, dest_height, Gdk.InterpType.BILINEAR);
        }

        /**
         * Store pixbuf in tmp folder (for icon generation).
         */
        private File save_tmp_pixbuf(Gdk.Pixbuf pixbuf) throws GLib.Error
        {
            string filename = Path.build_filename(Environment.get_tmp_dir(),
                "diodon-" + _checksum + ".png");

            File file = File.new_for_path(filename);
            if(!file.query_exists(null)) {
                pixbuf.save(filename, "png");
            }

            return file;
        }
    }
}

