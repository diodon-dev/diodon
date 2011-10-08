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
     * A gtk menu item holding a list of clipboard items
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    class ClipboardMenu : Gtk.Menu
    {
        private Controller controller;
        private Gtk.MenuItem empty_item;
        
        /**
         * HashMap to look up corresponding clipboard menu item of given
         * clipboard item.
         */
        private Gee.Map<IClipboardItem, ClipboardMenuItem> clipboard_menu_items;
        
        public ClipboardMenu(Controller controller)
        {
            this.controller = controller;
            
            empty_item = new Gtk.MenuItem.with_label(_("<Empty>"));
            empty_item.set_sensitive(false);
            append(empty_item); 
            
            Gtk.SeparatorMenuItem sep_item = new Gtk.SeparatorMenuItem();
            append(sep_item);
            
            Gtk.MenuItem clear_item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.CLEAR, null);
            clear_item.activate.connect(on_clicked_clear);
            append(clear_item);
            
            Gtk.MenuItem preferences_item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.PREFERENCES, null);
            preferences_item.activate.connect(on_clicked_preferences);
            append(preferences_item);
            
            Gtk.MenuItem quit_item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.QUIT, null);
            quit_item.activate.connect(on_clicked_quit);
            append(quit_item);
            
            show_all();
            
            clipboard_menu_items = new Gee.HashMap<IClipboardItem, ClipboardMenuItem>(
                (GLib.HashFunc?)IClipboardItem.hash_func, (GLib.EqualFunc?)IClipboardItem.equal_func);
        }
        
        public void init()
        {
            controller.on_select_item.connect(select_clipboard_item);
            controller.on_add_item.connect(prepend_clipboard_item);
            controller.on_remove_item.connect(remove_clipboard_item);
            controller.on_clear.connect(clear);
            
             // add all available items from storage to menu
            foreach(IClipboardItem item in controller.get_items()) {
                prepend_clipboard_item(item);
            }
        }
        
        /**
         * Select item by noving it to the top of the menu
         * 
         * @param item item to be selected
         */
        public void select_clipboard_item(IClipboardItem item)
        {
            // re-arranging
            remove_clipboard_item(item);
            prepend_clipboard_item(item);
        
            ClipboardMenuItem menu_item = clipboard_menu_items.get(item);
            menu_item.highlight_item();
        }
        
        /**
         * Prepend given item to menu.
         * 
         * @param entry entry to be added
         */
        public void prepend_clipboard_item(IClipboardItem item)
        {
            ClipboardMenuItem menu_item = new ClipboardMenuItem(item);
            menu_item.activate.connect(on_clicked_item);
            menu_item.show();
            clipboard_menu_items.set(item, menu_item);
            prepend(menu_item);
            
            hide_empty_item(); // just in case
        }
        
        /**
         * Remove given item from menu
         * 
         * @param item item to be removed
         */
        public void remove_clipboard_item(IClipboardItem item)
        {
            ClipboardMenuItem menu_item = null;
            clipboard_menu_items.unset(item, out menu_item);
            remove(menu_item);
            menu_item.destroy();
        }
        
        /**
         * Delete all clipboard menu items from menu
         */
        public void clear()
        {
            foreach(ClipboardMenuItem menu_item in clipboard_menu_items.values) {
                remove(menu_item);
                menu_item.destroy();
            }
            
            clipboard_menu_items.clear();
            show_empty_item();
        }
        
        public void show_menu()
        {
            popup(null, null, null, 0, Gtk.get_current_event_time());
        }
        
        /**
         * Show empty clipboard label
         */
        private void show_empty_item()
        {
            empty_item.set_visible(true);
        }
        
        /**
         * Hide empty clipboard label
         */
        private void hide_empty_item()
        {
            empty_item.set_visible(false);
        }
        
        /**
         * Not completed code for bug 792812
         */
        /*private bool on_key_pressed(Gdk.EventKey event)
        {
            // TODO: check for the configured hot key
            if(event.keyval == 118 && event.state == 12) {
            
                if(menu.get_selected_item() == null) {
                    menu.select_first(false);
                }
                else {
                    menu.move_selected(1);
                }
                
                return true;
            }
            
            return false;
        }

        private bool on_key_released(Gdk.EventKey event)
        {
            // TODO: check for the configured hotkey
            // FIXME: the item gets always activated when
            // Ctrl+Alt is released and not just the first time
            if(event.state == 12 && event.keyval != 118) {
                if(menu.get_selected_item() != null) {
                    menu.activate_item(menu.get_selected_item(), false);
                    return true;
                }
            }
                
            return false;
        }*/
        
        /**
         * User event: clicked menu item clear
         */
        private void on_clicked_clear()
        {
            controller.clear();
        }
        
        /**
         * User event: clicked menu item preferences
         */
        private void on_clicked_preferences()
        {
            controller.show_preferences();
        }
        
        /**
         * User event: clicked menu item quit
         */
        private void on_clicked_quit()
        {
            controller.quit();
        }
        
        /**
         * User event: clicked clipboard menu item
         * 
         * @param menu_item menu item clicked
         */
        private void on_clicked_item(Gtk.MenuItem menu_item)
        {
            ClipboardMenuItem clipboard_menu_item = (ClipboardMenuItem)menu_item;
            controller.select_item(clipboard_menu_item.get_clipboard_item());
        }        
    }
}

