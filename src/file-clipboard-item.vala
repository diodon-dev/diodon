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
 */

namespace Diodon
{
    /**
     * Represents a file clipboard item holding a path to a file.
     *
     * @author Oliver Sauder <os@esite.ch>
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
        private ClipboardType _clipboard_type;
       
        /**
         * Default data constructor needed for reflection.
         * 
         * @param type clipboard type item is coming from
         * @param data paths separated with \n
         */ 
        public FileClipboardItem(ClipboardType clipboard_type, string data)
        {
            _clipboard_type = clipboard_type;
            _paths = data;
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
	    public string get_clipboard_data()
        {
            return _paths;
        }

        /**
	     * {@inheritDoc}
	     */
        public string get_label()
        {
            // label should not be longer than 50 letters
            string label = _paths.replace("\n", " ");
            if (label.length > 50) {
                label = label.substring(0, 50) + "...";
            }
            
            return label;
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

            // converting target list to target entries
            // leaving one target entry for special target (s. below)
            targets = new Gtk.TargetEntry[target_list.list.length()];
            int i = 0;
            foreach(unowned Gtk.TargetPair pair in target_list.list) {
                targets[i].target = pair.target.name();
                ++i;
            }

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
         * Callback method called by Gtk.Clipboard to get the clipboard data
         * whereas in this case it is the path as text and the uri for
         * pasting file itself. Static as instance to FileClipboardItem is passed on
         * as user_data.
         */
        private static void get_clipboard_data_callback(Gtk.Clipboard clipboard, Gtk.SelectionData selection_data,
            uint info, void* user_data)
        {
            debug("clipboard data called");
            FileClipboardItem item = (FileClipboardItem) user_data;
            
            // use path as simple text
            selection_data.set_text(item._paths, -1);
            
             // convert paths to uris
            string[] uris = item._paths.split("\n");
            for(int i = 0; i < uris.length; ++i) {
                string uri = uris[i];
                uri = "file://" + uri;
                uris[i] = uri;
            }
            selection_data.set_uris(uris);
            
            // set special nautilus target which should copy the files
            // nautilus has defined 8 as format so we have to use 8 as well
            string copy_files_data = "copy\n" + join("\n", uris);
            selection_data.set(copy_files, 8, string_to_uchar_array(copy_files_data));
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
    }  
}

