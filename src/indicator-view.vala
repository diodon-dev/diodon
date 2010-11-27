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
     * ClipboardIndicator class. Handling interaction
     * with the application indicator icon.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class IndicatorView : GLib.Object
    {
        private AppIndicator.Indicator indicator;
        private Gtk.Menu menu;
        
        /**
         * HashMap of all available clipboard items
         */
        private HashMap<ClipboardItem, ClipboardMenuItem> clipboard_menu_items;
        
        /**
         * called when application exits
         */
        public signal void on_quit();
        
        /**
         * called when all items need to be cleared
         */
        public signal void on_clear();
        
        /**
         * called when a item has been selected in the menu
         * 
         * @param item item to be selected
         */
        public signal void on_select_item(ClipboardItem item);
        
        /**
         * Default constructor.
         */ 
        public IndicatorView()
        {
            // Setup indicator
            indicator = new AppIndicator.Indicator("diodon", "applications-utilities",
                AppIndicator.Category.APPLICATION_STATUS);
            indicator.set_status(AppIndicator.Status.ACTIVE);
            indicator.set_attention_icon("indicator-messages-new");
            indicator.set_icon("distributor-logo");
            
            // Setup application menu
            menu = new Gtk.Menu();
            
            Gtk.SeparatorMenuItem sep_item = new Gtk.SeparatorMenuItem();
            menu.append(sep_item);
            
            Gtk.MenuItem clear_item = new Gtk.MenuItem.with_label(_("Clear"));
            clear_item.activate.connect(on_clicked_clear);
            menu.append(clear_item);
            
            Gtk.MenuItem quit_item = new Gtk.MenuItem.with_label(_("Quit"));
            quit_item.activate.connect(on_clicked_quit);
            menu.append(quit_item);
            
            menu.show_all();
            indicator.set_menu(menu);
            
            clipboard_menu_items = new HashMap<ClipboardItem, ClipboardMenuItem>(
                ClipboardItem.hash_func, ClipboardItem.equal_func);
        }
        
        /**
         * Select item by highlighting it.
         * 
         * @param item item to be selected
         */
        public void select_item(ClipboardItem item)
        {
            ClipboardMenuItem menu_item = clipboard_menu_items.get(item);
            menu_item.highlight_item();
        }
        
        /**
         * Prepend given item to menu.
         * 
         * @param entry entry to be added
         */
        public void prepend_item(ClipboardItem item)
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
        public void remove_item(ClipboardItem item)
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
         * User event: clicked menu item clear
         */
        private void on_clicked_clear()
        {
            on_clear();
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
 
