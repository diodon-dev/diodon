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
    public class Indicator : GLib.Object
    {
        private AppIndicator.Indicator indicator;
        private Gtk.Menu menu;
        private ArrayList<Gtk.MenuItem> menu_items;
        
        /**
         * called when application exits
         */
        public signal void on_quit(Gtk.MenuItem item);
        
        /**
         * called when all items need to be cleared
         */
        public signal void on_clear();
        
        /**
         * Default constructor.
         */ 
        public Indicator()
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
            
            Gtk.MenuItem clear_item = new Gtk.MenuItem.with_label("Clear");
            clear_item.activate.connect(on_clicked_clear);
            menu.append(clear_item);
            
            Gtk.ImageMenuItem quit_item = new Gtk.ImageMenuItem.from_stock(
                Gtk.STOCK_QUIT, null);
            //quit_item.activate.connect(on_quit);
            menu.append(quit_item);
            
            menu.show_all();
            indicator.set_menu(menu);
        }
        
        /**
         * Select item by moving it to the top of the menu
         * 
         * @param item item to be selected
         */
        public void select_item(ClipboardItem item)
        {
        }
        
        /**
         * Prepend given entry to menu.
         * 
         * @param entry entry to be added
         */
        public void add_entry(ClipboardItem item)
        {
            /*Gtk.MenuItem clipboard_item =
                new Gtk.MenuItem.with_label(entry.get_label());
            clipboard_item.activate.connect()*/
        }
        
        /**
         * 
        private void on_clicked_clipboarditem(MenuItem item)
        {
            item.set_arg
            
            foreach (var k in menuItems.keys) {
                if (menuItems.get(k) == item) {
                    stmtQueryData.bind_int64(1, k);
                    stmtQueryData.step();
                    clipboard.set_text(stmtQueryData.column_text(0), -1);
                    stmtQueryData.reset();
                    return;
                }
            }
        }
        
        /**
         * Clear event handler removing all clipboard entries.
         */
        private void on_clicked_clear()
        {
            /*foreach (var v in menuItems.values) {
                v.destroy();
            }
            
            menuItems.clear();
            stmtClear.step();
            stmtClear.reset();
            add_clearitem();*/
        }
    }  
}
 
