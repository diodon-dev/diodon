/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010 Diodon Team <diodon-team@lists.launchpad.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Diodon
{
    /**
     * This class is in charge of retrieving information from
     * the gnome clipboard(s) and passing on such to the processes connected
     * to the given signals.
     *
     * TODO: consider using a different design pattern to handle
     * primary and clipboard selection
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ClipboardManager : GLib.Object
    {
        private Gtk.Clipboard primary = null;
        private Gtk.Clipboard clipboard = null;
        
        /**
         * delegate definition to determine when text has been received
         * 
         * @param text received text
         */ 
        private delegate void TextReceivedFunc(string text);
        
        /**
         * Called when text of the primary selection clipboard has been received
         * 
         * @param text received primary selection text which is never null or empty
         */
        public signal void on_primary_text_received(string text);
        
        /**
         * Called when text of the clipboard has been received
         * 
         * @param text received clipboard text which is never null or empty
         */
        public signal void on_clipboard_text_received(string text);
        
        /**
         * Starts the process requesting text from the primary selection
         * and clipboard.
         */
        public void start()
        {
            primary = Gtk.Clipboard.get(Gdk.SELECTION_PRIMARY);
            clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
            Timeout.add(500, request_primary_text);
            Timeout.add(500, request_clipboard_text);
        }
        
        /**
         * Select item in primary selection
         *
         * @param item item to be selected
         */
        public void select_item_in_primary(ClipboardItem item)
        {
            select_text(primary, item.get_text());
        }

        /**
         * Select item in clipboard.
         *
         * @param item item to be selected
         */        
        public void select_item_in_clipboard(ClipboardItem item)
        {
            select_text(clipboard, item.get_text());
        }
        
        /**
         * Clear primary selection
         */
        public void clear_primary()
        {
            clear_selection(primary);
        }
        
        /**
         * Clear clipboard selection
         */
        public void clear_clipboard()
        {
            clear_selection(clipboard);
        }
        
        /**
         * Requests text from the primary selection.
         * 
         * @return always true.
         */
        private bool request_primary_text()
        {
            request_text(primary, (text) => {
                on_primary_text_received(text); 
             });
             return true;
        }
        
        /**
         * Requests text from the clipboard selection.
         * 
         * @return always true.
         */
        private bool request_clipboard_text()
        {
             request_text(clipboard, (text) => {
                on_clipboard_text_received(text);
             });
             return true;
        }
        
        /**
         * Request text from the given clipboard. If result is valid
         * given function will be called.
         *
         * @param selection selection to retrieve text from
         * @param func function to be called when text has been
         *  retrieved successfully
         */
        private void request_text(Gtk.Clipboard selection, TextReceivedFunc func)
        {
            string text = selection.wait_for_text();
            
            // check if text is valid
            if(text != null && text != "") {
                func(text);
            }
        }
        
        /**
         * Select text in the given clipboard.
         *
         * @param selection selection for text selection
         * @param text text to be selected
         */
        private void select_text(Gtk.Clipboard selection, string text)
        {
            selection.set_text(text, -1);
        }
        
        /**
         * Clear given selection 
         * 
         * @param selection selection to be cleared
         */
        private void clear_selection(Gtk.Clipboard selection)
        {
            selection.clear();
        }
    }  
}
 
