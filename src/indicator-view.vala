/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010 Diodon Team <diodon-team@lists.launchpad.net>
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
 
using Gee;
 
namespace Diodon
{
    /**
     * ClipboardIndicator class. Handling interaction
     * with the application indicator icon.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class IndicatorView : GLib.Object
    {
        private AppIndicator.Indicator indicator;
        private Gtk.Menu menu;
        private Gtk.MenuItem empty_item;
        
        /**
         * HashMap of all available clipboard items
         */
        private HashMap<IClipboardItem, ClipboardMenuItem> clipboard_menu_items;
        
        /**
         * called when application exits
         */
        public signal void on_quit();
        
        /**
         * called when all items need to be cleared
         */
        public signal void on_clear();
        
        /**
         * called when preferences dialog needs to be shown
         */
        public signal void on_show_preferences();
        
        /**
         * called when a item has been selected in the menu
         * 
         * @param item item to be selected
         */
        public signal void on_select_item(IClipboardItem item);
        
        /**
         * Default constructor.
         */ 
        public IndicatorView()
        {
            // Setup indicator
            indicator = new AppIndicator.Indicator("diodon", "gtk-paste",
                AppIndicator.IndicatorCategory.APPLICATION_STATUS);
            set_visible(true);
            
            // Setup application menu
            menu = new Gtk.Menu();
            menu.key_press_event.connect(on_key_pressed);
            menu.key_release_event.connect(on_key_released);
            
            empty_item = new Gtk.MenuItem.with_label(_("<Empty>"));
            empty_item.set_sensitive(false);
            menu.append(empty_item);
            
            Gtk.SeparatorMenuItem sep_item = new Gtk.SeparatorMenuItem();
            menu.append(sep_item);
            
            Gtk.MenuItem clear_item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.CLEAR, null);
            clear_item.activate.connect(on_clicked_clear);
            menu.append(clear_item);
            
            Gtk.MenuItem preferences_item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.PREFERENCES, null);
            preferences_item.activate.connect(on_clicked_preferences);
            menu.append(preferences_item);
            
            Gtk.MenuItem quit_item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.QUIT, null);
            quit_item.activate.connect(on_clicked_quit);
            menu.append(quit_item);
            
            menu.show_all();
            indicator.set_menu(menu);
            
            clipboard_menu_items = new HashMap<IClipboardItem, ClipboardMenuItem>(
                (GLib.HashFunc?)IClipboardItem.hash_func, (GLib.EqualFunc?)IClipboardItem.equal_func);
        }
        
        ~IndicatorView()
        {
            empty_item.destroy();
            menu.destroy();
        }
        
        public void set_visible(bool visible)
        {
            if (visible)
                indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
            else
                indicator.set_status(AppIndicator.IndicatorStatus.PASSIVE);
        }
        
        /**
         * Select item by highlighting it.
         * 
         * @param item item to be selected
         */
        public void select_item(IClipboardItem item)
        {
            ClipboardMenuItem menu_item = clipboard_menu_items.get(item);
            menu_item.highlight_item();
        }
        
        /**
         * Prepend given item to menu.
         * 
         * @param entry entry to be added
         */
        public void prepend_item(IClipboardItem item)
        {
            ClipboardMenuItem menu_item = new ClipboardMenuItem(item);
            menu_item.activate.connect(on_clicked_item);
            menu_item.show();
            clipboard_menu_items.set(item, menu_item);
            menu.prepend(menu_item);
        }
        
        /**
         * Remove given item from menu
         * 
         * @param item item to be removed
         */
        public void remove_item(IClipboardItem item)
        {
            ClipboardMenuItem menu_item = null;
            clipboard_menu_items.unset(item, out menu_item);
            menu.remove(menu_item);
            menu_item.destroy();
        }
        
        /**
         * Delete all clipboard menu items from indicator
         */
        public void clear()
        {
            foreach(ClipboardMenuItem menu_item in clipboard_menu_items.values) {
                menu.remove(menu_item);
                menu_item.destroy();
            }
            
            clipboard_menu_items.clear();
        }
        
        /**
         * Show indicator menu
         */
        public void show_menu()
        {
            menu.popup(null, null, null, 0, Gtk.get_current_event_time());
        }
        
        /**
         * Show empty clipboard label
         */
        public void show_empty_item()
        {
            empty_item.set_visible(true);
        }
        
        /**
         * Hide empty clipboard label
         */
        public void hide_empty_item()
        {
            empty_item.set_visible(false);
        }
        
        /**
         * 
         */
        private bool on_key_pressed(Gdk.EventKey event)
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
        }
        
        /**
         * User event: clicked menu item clear
         */
        private void on_clicked_clear()
        {
            on_clear();
        }
        
        /**
         * User event: clicked menu item preferences
         */
        private void on_clicked_preferences()
        {
            on_show_preferences();
        }
        
        /**
         * User event: clicked menu item quit
         */
        private void on_clicked_quit()
        {
            on_quit();
        }
        
        /**
         * User event: clicked clipboard menu item
         * 
         * @param menu_item menu item clicked
         */
        private void on_clicked_item(Gtk.MenuItem menu_item)
        {
            ClipboardMenuItem clipboard_menu_item = (ClipboardMenuItem)menu_item;
            on_select_item(clipboard_menu_item.get_clipboard_item());
        }
    }  
}
 
