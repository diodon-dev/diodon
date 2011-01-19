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
        private ClipboardType type;
        private Gtk.Clipboard clipboard = null;
        
        /**
         * Called when text from the clipboard has been received
         * 
         * @param type type of clipboard text belongs to
         * @param text received text from clipboard which is never null or empty
         */
        public signal void on_text_received(ClipboardType type, string text);
        
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
         */
        public void start()
        {
            Timeout.add(500, request_text);
        }
        
        /**
         * Select text of given item in the managed clipboard.
         *
         * @param item item to be selected
         */
        public void select_item(ClipboardItem item)
        {
            clipboard.set_text(item.text, -1);
        }
        
        /**
         * Clear managed clipboard 
         */
        public void clear()
        {
            clipboard.set_text("", -1);
            // FIXME: this does not seem to do anything
            //clipboard.clear();
        }
        
        /**
         * Checks if the given text can be accepted.
         *
         * @param text clipboard text
         * @return always true in the default implementation
         */
        protected virtual bool is_accepted(string text)
        {
            return true;
        }
        
        /**
         * Request text from managed clipboard. If result is valid
         * on_text_received will be called.
         *
         * @return currently always true
         */
        private bool request_text()
        {
            string text = clipboard.wait_for_text();
            
            // check if text is valid and accepted
            if(text != null && text != "" && is_accepted(text)) {
                on_text_received(type, text);
            }
            
            // for performance reasons, only check
            // clipboard if text is not available
            if(text == null) {
                check_clipboard();
            }
            
            return true;
        }
        
        /**
         * Check if clipboard content has been lost.
         */
        private void check_clipboard()
        {
            Gdk.Atom[] targets = null;
            if(!clipboard.wait_for_targets(targets)) {
                on_empty(type);
            }
        }
    }  
}

 
