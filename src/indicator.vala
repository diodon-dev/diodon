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
     * ClipboardIndicator class. Handling interaction
     * with the application indicator icon.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class Indicator : GLib.Object
    {
        private AppIndicator.Indicator indicator;
        private Gtk.Menu appMenu;
        
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
            appMenu = new Gtk.Menu();
            
            Gtk.SeparatorMenuItem sepItem = new Gtk.SeparatorMenuItem();
            appMenu.append(sepItem);
            
            Gtk.MenuItem clearItem = new Gtk.MenuItem.with_label("Clear");
            clearItem.activate.connect(on_clicked_clear);
            appMenu.append(clearItem);
            
            Gtk.ImageMenuItem quitItem = new Gtk.ImageMenuItem.from_stock(
                Gtk.STOCK_QUIT, null);
            quitItem.activate.connect(Gtk.main_quit);
            appMenu.append(quitItem);
            
            appMenu.show_all();
            indicator.set_menu(appMenu);
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
 