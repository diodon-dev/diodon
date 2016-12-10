/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2011 Diodon Team <diodon-team@lists.launchpad.net>
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
     * Represents a file clipboard item holding a path to a file.
     */
    public class FileClipboardItem : GLib.Object, IClipboardItem
    {
        /**
         * a special target type for copying files so nautilus can paste it
         */
        private static Gdk.Atom copy_files = Gdk.Atom.intern_static_string("x-special/gnome-copied-files");

        /**
         * file paths separated with \n
         */
        private string _paths;
        private string? _origin;
        private ClipboardType _clipboard_type;
        private DateTime _date_copied;

        /**
         * Default data constructor needed for reflection.
         *
         * @param clipboard_type clipboard type item is coming from
         * @param data paths separated with \n
         * @param origin origin of clipboard item as application path
         */
        public FileClipboardItem(ClipboardType clipboard_type, string data, string? origin, DateTime date_copied) throws FileError
        {
            _clipboard_type = clipboard_type;
            _paths = data;
            _origin = origin;
            _date_copied = date_copied;

            // check if all paths are available
            string[] paths = convert_to_paths(_paths);
            foreach(unowned string path in paths) {
                File file = File.new_for_path(path);
                if(!file.query_exists()) {
                    throw new FileError.NOENT("No such file or directory " + path);
                }
            }
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
            return _paths;
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
            string home = Environment.get_home_dir();

            // label should not be longer than 50 letters
            string label = _paths.replace("\n", " ");

            // replacing home dir with common known tilde
            label = label.replace(home, "~");

            if (label.char_count() > 50) {
                long index_char = label.index_of_nth_char(50);
                label = label.substring(0, index_char) + "...";
            }

            return label;
        }

        /**
	     * {@inheritDoc}
	     */
        public string get_mime_type()
        {
            // mime type of first file is used
            // if retrieving of content type fails, use text/plain as fallback
            string mime_type = "text/plain";
            string[] uris = convert_to_uris(_paths);
            File file = File.new_for_uri(uris[0]);
            try {
                FileInfo file_info = file.query_info(FileAttribute.STANDARD_FAST_CONTENT_TYPE, 0, null);
                mime_type = file_info.get_attribute_as_string(FileAttribute.STANDARD_FAST_CONTENT_TYPE);
            } catch(GLib.Error e) {
                warning("Could not determine mime type of file %s", uris[0]);
            }

            return mime_type;
        }

        /**
	     * {@inheritDoc}
	     */
        public ClipboardCategory get_category()
        {
            return ClipboardCategory.FILES;
        }

        /**
	     * {@inheritDoc}
	     */
        public Gtk.Image? get_image()
        {
            Gtk.Image image = new Gtk.Image.from_gicon(get_icon(), Gtk.IconSize.MENU);
            return image;
        }

        /**
	     * {@inheritDoc}
	     */
        public Icon get_icon()
        {
            const string FILE_ATTRS =
              FileAttribute.THUMBNAIL_PATH;

            // icon of first file is used
            string mime_type = get_mime_type();
            string[] uris = convert_to_uris(_paths);
            File file = File.new_for_uri(uris[0]);
            try {
                FileInfo info = file.query_info(FILE_ATTRS, 0);
                Icon icon = info.get_icon();
                string thumbnail_path = info.get_attribute_byte_string(FileAttribute.THUMBNAIL_PATH);
                if(thumbnail_path != null) {
                    return new FileIcon(File.new_for_path(thumbnail_path));
                }
                else if(icon != null) {
                    return icon;
                }
            } catch(GLib.Error e) {
                warning("Could not determine mime type of file %s", uris[0]);
            }

            // default icon of mime type
            return ContentType.get_icon(mime_type);
        }

        /**
	     * {@inheritDoc}
	     */
        public ByteArray? get_payload()
        {
            return null;
        }

        /**
	     * {@inheritDoc}
	     */
        public string get_checksum()
        {
            return Checksum.compute_for_string(ChecksumType.SHA1, _paths);
        }

        /**
	     * {@inheritDoc}
	     */
        public void to_clipboard(Gtk.Clipboard clipboard)
        {
            // create default uri target and text target
            Gtk.TargetEntry[] targets = null;
            Gtk.TargetList target_list = new Gtk.TargetList(targets);
            target_list.add_text_targets(0);
            target_list.add_uri_targets(0);
            target_list.add(copy_files, 0, 0); // add special nautilus target
            targets = Gtk.target_table_new_from_list(target_list);

            // set data callbacks with a empty clear func as
            // there is nothing to be cleared
            clipboard.set_with_owner(targets,
                (Gtk.ClipboardGetFunc)get_clipboard_data_callback,
                (Gtk.ClipboardClearFunc)clear_clipboard_data_callback, this);

            // store data in clipboard so when diodon is closed
            // data still can be pasted
            clipboard.store();
        }

        /**
	     * {@inheritDoc}
	     */
	    public bool equals(IClipboardItem* item)
        {
            bool equals = false;

            if(item is FileClipboardItem) {
                equals = strcmp(_paths, item->get_text()) == 0;
            }

            return equals;
        }

        /**
	     * {@inheritDoc}
	     */
	    public uint hash()
        {
            return str_hash(_paths);
        }

        /**
         * Callback method called by Gtk.Clipboard to get the clipboard data
         * whereas in this case it is the path as text and the uri for
         * pasting file itself. Static as instance to FileClipboardItem is passed on
         * as user_data.
         */
        private static void get_clipboard_data_callback(Gtk.Clipboard clipboard, Gtk.SelectionData selection_data,
            uint info, void* user_data)
        {
            FileClipboardItem item = (FileClipboardItem) user_data;

            Gdk.Atom[] targets = new Gdk.Atom[1];
            targets[0] = selection_data.get_target();

            // set content according to requested target
            if(Gtk.targets_include_text(targets)) {
                debug("get clipboard file data as text");
                selection_data.set_text(item._paths, -1);
            }
            else if(Gtk.targets_include_uri(targets)) {
                debug("get clipboard file data as uris");
                string[] uris = convert_to_uris(item._paths);
                selection_data.set_uris(uris);
            }
            else {
                debug("get clipboard file data as copied files");
                string[] uris = convert_to_uris(item._paths);
                // set special nautilus target which should copy the files
                // 8 number of bits in a unit are used
                string copy_files_data = "copy\n" + join("\n", uris);
                selection_data.set(copy_files, 8, string_to_uchar_array(copy_files_data));
            }
        }

        /**
         * Callback method called by Gtk.Clipboard to clear data.
         * Currently empty method as there is nothing to be cleared.
         */
        private static void clear_clipboard_data_callback(Gtk.Clipboard clipboard, void* user_data)
        {
        }

        /**
         * Helper method to convert string to uchar array.
         *
         * @param str string to be converted
         */
        private static uchar[] string_to_uchar_array(string str)
        {
            uchar[] data = new uchar[0];
            for (int i = 0; i < str.length; ++i) {
                data += (uchar) str[i];
            }
            return data;
        }

        /**
         * Helper method to join a array of string together with
         * given separator.
         *
         * @param separator separator to join string
         * @param array array of strings to be joined
         */
        private static string join(string separator, string[] array)
        {
            string result = "";
            if(array.length > 0) {
                result = array[0];
                for(int i = 1; i < array.length; ++i) {
                    result += separator;
                    result += array[i];
                }
            }

            return result;
        }

        /**
         * Convert given paths to uris
         *
         * @param paths paths to be converted
         */
        private static string[] convert_to_uris(string paths)
        {
            string[] uris = convert_to_paths(paths);
            for(int i = 0; i < uris.length; ++i) {
                string uri = uris[i];
                uri = "file://" + uri;
                uris[i] = uri;
            }

            return uris;
        }

        /**
         * Helper method to convert paths string to a path array
         *
         * @param path string with new line separator per path
         */
        private static string[] convert_to_paths(string paths)
        {
            string[] result = paths.split("\n");
            return result;
        }
    }
}

