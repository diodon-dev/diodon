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
     * An image clipboard item representing such in a preview image.
     */
    public class ImageClipboardItem : GLib.Object, IClipboardItem
    {
        private ClipboardType _clipboard_type;
        private string _checksum; // checksum to identify pic content
        private Gdk.Pixbuf _pixbuf;
        private string _label;
        private string? _origin;
        private DateTime _date_copied;

        // Cached PNG payload bytes — avoids re-encoding on every get_payload() call
        private uint8[]? _cached_png = null;

        // Static in-memory cache: checksum → {pixbuf, png_bytes}
        // Keeps full-res data alive so paste from history is a dict
        // lookup instead of Zeitgeist query + PNG decode + PNG re-encode.
        private static GLib.HashTable<string, Gdk.Pixbuf>? _pixbuf_cache = null;
        private static GLib.HashTable<string, GLib.Bytes>? _png_cache = null;

        private static unowned GLib.HashTable<string, Gdk.Pixbuf> get_pixbuf_cache() {
            if (_pixbuf_cache == null) {
                _pixbuf_cache = new GLib.HashTable<string, Gdk.Pixbuf>(str_hash, str_equal);
            }
            return _pixbuf_cache;
        }

        private static unowned GLib.HashTable<string, GLib.Bytes> get_png_cache() {
            if (_png_cache == null) {
                _png_cache = new GLib.HashTable<string, GLib.Bytes>(str_hash, str_equal);
            }
            return _png_cache;
        }

        /**
         * Try to build an ImageClipboardItem from the in-memory cache.
         * Returns null if the checksum is not cached.
         * Bypasses extract_pixbuf_info() entirely — no SHA1 rehash of
         * the full pixel data. Both pixbuf AND PNG bytes are restored
         * from cache so get_payload() never needs to re-encode either.
         */
        public static ImageClipboardItem? from_cache(string checksum, string? origin, DateTime date_copied) {
            unowned Gdk.Pixbuf? cached_pix = get_pixbuf_cache().lookup(checksum);
            if (cached_pix == null) {
                return null;
            }
            // Build item directly — do NOT call with_image/extract_pixbuf_info
            // which would SHA1-hash 33MB of pixel data for nothing.
            var item = new ImageClipboardItem._from_cache_internal();
            item._clipboard_type = ClipboardType.NONE;
            item._origin = origin;
            item._date_copied = date_copied;
            item._checksum = checksum;
            item._label = "[%dx%d]".printf(cached_pix.width, cached_pix.height);
            item._pixbuf = cached_pix;

            // PNG bytes live in the static cache — get_payload() reads
            // them by checksum. No copying needed here.
            return item;
        }

        // Private no-op constructor for from_cache() to avoid
        // the expensive extract_pixbuf_info() path.
        private ImageClipboardItem._from_cache_internal() {
        }

        /**
         * Create image clipboard item by a pixbuf.
         *
         * @param clipboard_type clipboard type item is coming from
         * @param pixbuf image from clipboard
         * @param origin origin of clipboard item as application path
         */
        public ImageClipboardItem.with_image(ClipboardType clipboard_type, Gdk.Pixbuf pixbuf, string? origin, DateTime date_copied) throws GLib.Error
        {
            _clipboard_type = clipboard_type;
            _origin = origin;
            _date_copied = date_copied;
            extract_pixbuf_info(pixbuf);
        }

        /**
         * Create image clipboard item by given payload.
         *
         * @param clipboard_type clipboard type item is coming from
         * @param pixbuf image from clipboard
         * @param origin origin of clipboard item as application path
         */
        public ImageClipboardItem.with_payload(ClipboardType clipboard_type, ByteArray payload, string? origin, DateTime date_copied) throws GLib.Error
        {
            _clipboard_type = clipboard_type;
            _origin = origin;
            _date_copied = date_copied;

            // Cache the raw PNG bytes on the instance AND in the
            // static cache so get_payload() never re-encodes.
            _cached_png = new uint8[payload.data.length];
            GLib.Memory.copy(_cached_png, payload.data, payload.data.length);

            Gdk.PixbufLoader loader = new Gdk.PixbufLoader();
            loader.write(payload.data);
            loader.close();
            Gdk.Pixbuf pixbuf = loader.get_pixbuf();
            extract_pixbuf_info(pixbuf);

            // Also put PNG bytes in the static cache keyed by checksum
            // (checksum is set by extract_pixbuf_info above)
            get_png_cache().replace(_checksum, new GLib.Bytes(payload.data));
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
            return _label; // label is representation of image
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
            // images are always converted to png
            return "image/png";
        }

        /**
	     * {@inheritDoc}
	     */
        public Icon get_icon()
        {
            try {
                File file = save_tmp_pixbuf(_pixbuf);
                FileIcon icon = new FileIcon(file);
                return icon;
            } catch(Error e) {
                warning("Could not create icon for image %s. Fallback to content type",
                    _checksum);
                return ContentType.get_icon(get_mime_type());
            }
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
            Gdk.Pixbuf pixbuf_preview = create_scaled_pixbuf(_pixbuf);
            return new Gtk.Image.from_pixbuf(pixbuf_preview);
        }

        /**
	     * {@inheritDoc}
	     */
        public ByteArray? get_payload() throws GLib.Error
        {
            // 1. Check instance cache
            if (_cached_png != null) {
                ByteArray ba = new ByteArray.sized((uint) _cached_png.length);
                ba.append(_cached_png);
                return ba;
            }

            // 2. Check static cache (from_cache items land here)
            GLib.Bytes? cached = get_png_cache().lookup(_checksum);
            if (cached != null) {
                unowned uint8[] data = cached.get_data();
                ByteArray ba = new ByteArray.sized((uint) data.length);
                ba.append(data);
                return ba;
            }

            // 3. Last resort: encode (first time only, e.g. fresh copy)
            uint8[] buffer;
            _pixbuf.save_to_buffer(out buffer, "png");

            // Cache for future
            _cached_png = new uint8[buffer.length];
            GLib.Memory.copy(_cached_png, buffer, buffer.length);
            get_png_cache().replace(_checksum, new GLib.Bytes(buffer));

            return new ByteArray.take(buffer);
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
	     */
        public void to_clipboard(Gtk.Clipboard clipboard)
        {
             // Use set_with_owner so WE control what data gets served
             // to requesting apps. When an app asks for image/png,
             // we serve our pre-encoded cached bytes directly —
             // no re-encoding of 33MB of raw pixels on the main thread.
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
         * Serves cached PNG bytes directly for image/png requests,
         * falls back to pixbuf encoding only for rare other formats.
         */
        private static void clipboard_get_func(
            Gtk.Clipboard clipboard,
            Gtk.SelectionData selection_data,
            uint info,
            void* user_data_or_owner)
        {
            ImageClipboardItem self = (ImageClipboardItem) user_data_or_owner;

            // Try serving cached PNG for image/png requests (the common case)
            string target_name = selection_data.get_target().name();
            if (target_name == "image/png") {
                // Check static cache first, then instance
                GLib.Bytes? cached = get_png_cache().lookup(self._checksum);
                if (cached != null) {
                    unowned uint8[] data = cached.get_data();
                    selection_data.set(
                        selection_data.get_target(),
                        8,
                        data
                    );
                    return;
                }
                if (self._cached_png != null) {
                    selection_data.set(
                        selection_data.get_target(),
                        8,
                        self._cached_png
                    );
                    return;
                }
            }

            // Fallback for other formats (image/bmp, image/jpeg, etc.)
            // Let GDK encode from pixbuf — rare path
            selection_data.set_pixbuf(self._pixbuf);
        }

        /**
         * Called by GTK when clipboard ownership is lost.
         */
        private static void clipboard_clear_func(
            Gtk.Clipboard clipboard,
            void* user_data_or_owner)
        {
            // Nothing to clean up — data lives in the static cache
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
            // use checksum to create hash code
            return str_hash(_checksum);
        }

        /**
         * Extracts all pixbuf information which are needed to show image
         * in the view without having the pixbuf in the memory.
         *
         * @param pixbuf pixbuf to extract info from
         */
        private void extract_pixbuf_info(Gdk.Pixbuf pixbuf)
        {
            // create checksum of picture
            Checksum checksum = new Checksum(ChecksumType.SHA1);
            checksum.update(pixbuf.get_pixels(), pixbuf.height * pixbuf.rowstride);
            _checksum = checksum.get_string().dup();

            // label in format [{width}x{height}]
            _label ="[%dx%d]".printf(pixbuf.width, pixbuf.height);
            _pixbuf = pixbuf;

            // Cache the pixbuf so future pastes from history are instant
            // (dict lookup instead of Zeitgeist query + PNG decode)
            get_pixbuf_cache().replace(_checksum, pixbuf);
        }

        /**
         * Create a thumbnail-sized scaled pixbuf that fits within the
         * preview area while maintaining aspect ratio (contain fit).
         * The thumbnail is sized at 3x the normal menu item height
         * for clearly visible image previews.
         *
         * @param pixbuf source pixbuf to scale
         * @return scaled pixbuf preserving aspect ratio
         */
        private static Gdk.Pixbuf create_scaled_pixbuf(Gdk.Pixbuf pixbuf)
        {
            // Thumbnail size that fits comfortably in a GTK menu
            // without clipping, even with multiple items visible
            int max_height = 150;
            int max_width = 200;

            int src_width = pixbuf.width;
            int src_height = pixbuf.height;

            // Object-fit contain: scale to fill as much of the bounding
            // box as possible while preserving the original aspect ratio
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
         * Store pixbuf in tmp folder but only if it does not exist
         *
         * @param pixbuf pixbuf to be stored
         * @return file object of stored pixbuf
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

