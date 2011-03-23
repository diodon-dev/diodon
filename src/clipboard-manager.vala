/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010-2011 Diodon Team <diodon-team@lists.launchpad.net>
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
     * This class is in charge of retrieving information from
     * the encapsulated gnome clipboard and passing on such to the processes connected
     * to the given signals.
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ClipboardManager : GLib.Object
    {
        protected ClipboardType type;
        protected Gtk.Clipboard clipboard = null;
        
        /**
         * Called when text from the clipboard has been received
         * 
         * @param type type of clipboard text belongs to
         * @param text received text from clipboard which is never null or empty
         */
        public signal void on_text_received(ClipboardType type, string text);
        
        /**
         * Called when uris have been received from clipboard.
         * The given paths are not uris appended with file://
         * but just full paths.
         *
         * @param type type of clipboard uris belong to
         * @param paths paths separated with /n.
         */
        public signal void on_uris_received(ClipboardType type, string paths);
        
        /**
         * Called when a image has been received from the clipboard.
         *
         * @param type type of clipboard image belongs to
         * @param pixbuf image as a pixbuf object
         */
        public signal void on_image_received(ClipboardType type, Gdk.Pixbuf pixbuf);
        
        /**
         * Called when the clipboard is empty
         *
         * @param type type of clipboard which is empty
         */
        public signal void on_empty(ClipboardType type);
        
        /**
         * get type of given clipboard manager
         */
        public ClipboardType clipboard_type { get { return type; } }
        
        /**
         * Constructor
         *
         * @param clipboard clipboard to be managed
         * @param type of clipboard
         */
        public ClipboardManager(ClipboardType type)
        {
            // TODO: might consider this block to be replaced with a HashMap
            if(type == ClipboardType.CLIPBOARD) {
                this.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
            } else if(type == ClipboardType.PRIMARY) {
                this.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_PRIMARY);
            }
            
            this.type = type;
        }
        
        /**
         * Starts the process requesting text from encapsulated clipboard.
         * The owner has to change when new data is set in the clipboard
         * therefore just connecting to owner_change will do the trick.
         */
        public virtual void start()
        {
            clipboard.owner_change.connect(check_clipboard);
        }
        
        /**
         * Select item in the managed clipboard.
         *
         * @param item item to be selected
         */
        public virtual void select_item(IClipboardItem item)
        {
            item.to_clipboard(clipboard);
        }
        
        /**
         * Clear managed clipboard 
         */
        public void clear()
        {
            // clearing only works when clipboard is called by a callback
            // from clipboard itself. This is not the case here
            // so therefore we just set an empty text to clear the clipboard
            //clipboard.clear();
            clipboard.set_text("", -1);
        }
        
        /**
         * Request text from managed clipboard. If result is valid
         * on_text_received will be called.
         *
         * @param event owner change event
         */
        protected void check_clipboard()
        {
            // checking for text
            if(clipboard.wait_is_text_available()) {
                string text = request_text();
                
                // only valid text should be accepted
                if(text != null && text != "") {
                    // check if clipboard content are uris
                    // or just simple text
                    if(clipboard.wait_is_uris_available()) {
                        on_uris_received(type, text);
                    } else {
                        on_text_received(type, text);
                    }
                }
            }
            // checking for image
            else if(clipboard.wait_is_image_available()) {
                Gdk.Pixbuf? pixbuf = clipboard.wait_for_image();
                if(pixbuf != null) {
                    on_image_received(type, pixbuf);
                }
            }
            // checking if clipboard might be empty
            else {
                check_clipboard_emptiness();
            }
        }
        
        /**
         * request text from clipboard and return it
         *
         * @return returns text available in clipboard
         */
        protected string request_text()
        {
            // a workaround for the vapi bug
            // as wait_for_text should return a string and
            // not an unowned string as the returned value
            // needs to be freed
            string* text = clipboard.wait_for_text();
            string result = text->dup();
            delete text;
            
            return result;
        }
        
        /**
         * Check if clipboard content has been lost.
         */
        protected void check_clipboard_emptiness()
        {
            Gdk.Atom[] targets = null;
            if(!clipboard.wait_for_targets(targets)) {
                on_empty(type);
            }
        }
    }  
}
 
