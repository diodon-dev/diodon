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
     * The controller is responsible to interact with the 
     * Gtk clipboard and passing on information to the given ClipboardModel
     * and Indicator. Furthermore, clipboard user interactions on the indicator
     * are passed on to this controller where the logic is implemented
     * how to manage such requests.
     * 
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ClipboardController : GLib.Object
    {
        private IndicatorView indicator;
        private ClipboardModel model;
        private Gee.List<Gtk.Clipboard> clipboards;
        
        /**
         * Called when a item has been selected.
         */
        private signal void on_select_item(ClipboardItem item);
        
        /**
         * Called when a new item has been available
         */
        private signal void on_new_item(ClipboardItem item);
        
        /**
         * Called when a item needs to be removed
         */
        private signal void on_remove_item(ClipboardItem item);
        
        /**
         * Constructor.
         * 
         * @param indicator diodon indicator
         * @param model clipboard model
         * @param clipboard gtk clipboard
         */
        public ClipboardController(IndicatorView indicator, ClipboardModel model, Gee.List<Gtk.Clipboard> clipboards)
        {            
            this.model = model;
            this.clipboards = clipboards;
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
             indicator.on_select_item.connect(select_item);
             
             on_select_item.connect(model.select_item);
             on_select_item.connect(indicator.select_item);
             
             on_new_item.connect(model.add_item);
             on_new_item.connect(indicator.prepend_item);
             
             on_remove_item.connect(model.remove_item);
             on_remove_item.connect(indicator.remove_item);
             
             // add all available items from storage to indicator
             foreach(ClipboardItem item in model.get_items()) {
                indicator.prepend_item(item);
             }
        }
        
        /**
         * Select item by moving it onto the top of the menu
         * respectively data storage and then copying it to the clipboard
         *
         * @param item item to be selected
         */
        private void select_item(ClipboardItem item)
        {
            on_remove_item(item);
            on_new_item(item);
            on_select_item(item);
            
            foreach(Gtk.Clipboard clipboard in clipboards) {
                clipboard.set_text(item.get_text(), -1);
            }
        }
        
        /**
         * Clear all items from the clipboard and reset selected items
         */
        private void clear_items()
        {
            // remove all items from indicator first
            foreach(ClipboardItem item in model.get_items()) {
                indicator.remove_item(item);
            }
            
            foreach(Gtk.Clipboard clipboard in clipboards) {
                clipboard.clear();
            }
            
            model.clear_items();
        }
        
        /**
         * Fetching text from clipboard
         *
         * @return currently always true
         */
        private bool fetch_clipboard_info()
        {
            foreach(Gtk.Clipboard clipboard in clipboards) {
                clipboard.request_text(clipboard_text_received);
            }
            
            return true;
        }
        
        /**
         * Handling text retrieved from clipboard by adding it to the storage
         * and appending it to the menu of the indicator
         * 
         * @param clipboard gtk clipboard
         * @param text text received
         */
        private void clipboard_text_received(Gtk.Clipboard clipboard, string? text)
        {
            if(text != null && text != "") {
                ClipboardItem selected_item = model.get_selected_item();
                if(selected_item == null || text != selected_item.get_text()) {
                    ClipboardItem item = new ClipboardItem(text);
                    
                    // remove item from clipboard if it already exists
                    if(model.get_items().contains(item)) {
                        on_remove_item(item);
                    }
                    
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
 
