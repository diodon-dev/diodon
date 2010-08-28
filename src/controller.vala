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

using Gee;

namespace Diodon
{
    /**
     * The controller is responsible to interact with the 
     * Gtk clipboard and passing on information to the given ClipboardModel
     * and Indicator. Furthermore, user interactions on the indicator are passed
     * on to the controller where the logic is implemented how to manage
     * those requests.
     * 
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class Controller : GLib.Object
    {
        private Indicator indicator;
        private ClipboardModel model;
        private Gtk.Clipboard clipboard;
        
        /**
         * Called when a item has been selected.
         */
        private signal void on_select_item(ClipboardItem item);
        
        /**
         * Called when a new item has been available
         */
        private signal void on_new_item(ClipboardItem item);
        
        /**
         * Called when items need to be cleared
         */ 
        private signal void on_clear_items();
        
        /**
         * Constructor.
         * 
         * @param indicator diodon indicator
         * @param model clipboard model
         * @param clipboard gtk clipboard
         */
        public Controller(Indicator indicator, ClipboardModel model, Gtk.Clipboard clipboard)
        {            
            this.model = model;
            this.clipboard = clipboard;
            this.indicator = indicator;
        }
        
        /**
         * Starts the process collection clipboard information and listing
         * to user events.
         */
        public void start()
        {
             Timeout.add(500, fetch_clipboard_info);
             
             indicator.on_quit.connect(quit);
             indicator.on_clear.connect(clear_items);
             
             on_select_item.connect(model.select_item);
             on_select_item.connect(indicator.select_item);
             
             on_clear_items.connect(model.clear_items);
             on_clear_items.connect(indicator.clear_items);
             
             on_new_item.connect(model.add_item);
             on_new_item.connect(indicator.prepend_item);
        }
        
        /**
         * Clear all items from the clipboard
         */
        private void clear_items()
        {
            on_clear_items();
        }
        
        /**
         * Fetching text from clipboard
         */
        private bool fetch_clipboard_info()
        {
            clipboard.request_text(clipboard_text_received);
            return true;
        }
        
        /**
         * Handling text retrieved from clipboard by adding it to the storage
         * and appending it to the menu of the indicator
         */
        private void clipboard_text_received(Gtk.Clipboard clipboard, string? text)
        {
            if(text != null && text != "") {
                ClipboardItem selected_item = model.get_selected_item();
                if(selected_item == null || text != selected_item.get_text()) {
                    ClipboardItem item = new ClipboardItem(text);
                    on_new_item(item);
                    on_select_item(item);
                }
            }
        }
        
        /**
         * Quit diodon
         */
        private void quit()
        {
            Gtk.main_quit();
        }
    }  
}
 
