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
     * A gtk menu item holding a list of clipboard items
     */
    class ClipboardMenu : Gtk.Menu
    {
        private Controller controller;
        private Gee.List<Gtk.Widget> static_menu_items;
        
        /**
         * Create clipboard menu
         *
         * @param controller reference to controller
         * @param items clipboard items to be shown
         * @param menu_items additional menu items to be added after separator
         */
        public ClipboardMenu(Controller controller, Gee.List<IClipboardItem> items, Gee.List<Gtk.MenuItem> static_menu_items)
        {
            this.controller = controller;
            this.static_menu_items = static_menu_items;
            
            if(items.size <= 0) {
                Gtk.MenuItem empty_item = new Gtk.MenuItem.with_label(_("<Empty>"));
                empty_item.set_sensitive(false);
                append(empty_item);
            }
            
            foreach(IClipboardItem item in items) {
                append_clipboard_item(item);
            }
            
            Gtk.SeparatorMenuItem sep_item = new Gtk.SeparatorMenuItem();
            append(sep_item);
            
            if(static_menu_items != null) {
                foreach(Gtk.MenuItem menu_item in static_menu_items) {
                    append(menu_item);
                }
            }
            
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
            
            this.key_press_event.connect(on_key_pressed);
            this.key_release_event.connect(on_key_released);
        }
        
        /**
         * Append given clipboard item to menu.
         * 
         * @param entry entry to be added
         */
        public void append_clipboard_item(IClipboardItem item)
        {
            ClipboardMenuItem menu_item = new ClipboardMenuItem(item);
            menu_item.activate.connect(on_clicked_item);
            menu_item.show();
            append(menu_item);
        }
        
        public void show_menu()
        {
            popup(null, null, null, 0, Gtk.get_current_event_time());
        }
        
        /**
         * Completely destroy menu by cleaning up menu items and menu itself.
         */
        public void destroy_menu()
        {
            foreach(Gtk.Widget item in get_children()) {
                remove(item);
                
                // make sure that static items do not get destroyed
                if(static_menu_items == null || !static_menu_items.contains(item))
                {
                    item.destroy();
                    item.dispose();
                }
            }
            
            destroy();
            dispose();
        }
        
        /**
         * select next item when history accelerator is pressed multiple times
         */
        private bool on_key_pressed(Gdk.EventKey event)
        {
            uint keyval;
            Gdk.ModifierType state;
            ClipboardConfiguration cfg = controller.get_configuration();
            Gtk.accelerator_parse(cfg.history_accelerator,
                out keyval, out state);
            uint event_state = KeybindingManager.remove_lockmodifiers(event.state);
            
            if(event.keyval == keyval && event_state == state) {
            
                if(get_selected_item() == null) {
                    select_first(false);
                }
                else {
                    move_selected(1);
                }
                
                return true;
            }
            
            return false;
        }

        /**
         * activate item when modifier of history accelerator are
         * released and a item is selected.
         */
        private bool on_key_released(Gdk.EventKey event)
        {
            uint keyval;
            Gdk.ModifierType state;
            ClipboardConfiguration cfg = controller.get_configuration();
            Gtk.accelerator_parse(cfg.history_accelerator,
                out keyval, out state);
            uint event_state = KeybindingManager.remove_lockmodifiers(event.state);
              
            if(event_state == state && event.is_modifier == 1) {
                if(get_selected_item() != null) {
                    activate_item(get_selected_item(), false);
                    return true;
                }
            }
                
            return false;
        }
        
        /**
         * User event: clicked menu item clear
         */
        private void on_clicked_clear()
        {
            controller.clear.begin();
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
            controller.select_item_by_checksum.begin(clipboard_menu_item.get_item_checksum());
        }        
    }
}

