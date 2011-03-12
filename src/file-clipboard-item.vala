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
            Gtk.TargetEntry[] targets = new Gtk.TargetEntry[0];
            Gtk.TargetList target_list = new Gtk.TargetList(targets);
            target_list.add_uri_targets(0);
            target_list.add_text_targets(0);

            // set data callbacks with a empty clear func as
            // there is nothing to be cleared
            clipboard.set_with_data(targets, (Gtk.ClipboardGetFunc)get_clipboard_data_callback,
                (clipboard, user_data) => {});
            
            // store data in clipboard so when diodon is closed
            // data still can be pasted
            clipboard.store();
        }
        
        /**
         * Callback method called by Gtk.Clipboard to get the clipboard data
         * whereas in this case it is the path as text and the uri for
         * pasting file itself.
         */
        private void get_clipboard_data_callback(Gtk.Clipboard clipboard, Gtk.SelectionData selection_data,
            uint info, void* user_data)
        {
            // use path as simple text
            selection_data.set_text(_paths, -1);
            
             // convert paths to uris
            string[] uris = _paths.split("\n");
            for(int i = 0; i < uris.length; ++i) {
                string uri = GLib.Uri.escape_string(uris[i], "", true);
                uri = "file://" + uri;
                uris[i] = uri;    
            }
            selection_data.set_uris(uris);
        }
    }  
}

