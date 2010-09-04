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
     * A gtk menu item holding a clipboard item.
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ClipboardMenuItem : Gtk.MenuItem
    {
        private ClipboardItem item;
        
        /**
         * Clipboard item constructor
         * 
         * @param item clipboard item 
         */
        public ClipboardMenuItem(ClipboardItem item)
        {
            this.item = item;
            
            string label = item.get_text().replace("\n", " ");
            if (label.length > 50) {
                label = label.substring(0, 50) + "...";
            }
            set_label(label);
        }
        
        /**
         * Get encapsualted clipboard item
         */
        public ClipboardItem get_clipboard_item()
        {
            return item;
        }
        
        /**
         * Highlight item by changing label to bold
         * TODO: get this up and running
         */        
        public void highlight_item()
        {
            /*Gtk.Label label = get_menu_label();
            label.set_markup("<b>%s</b>".printf(get_label()));*/
        }
        
        /**
         * Gets the child of Gtk.Bin base class which represents
         * a Gtk.Label object.
         *
         * @return gtk label 
         */ 
        private Gtk.Label get_menu_label()
        {
            Gtk.Label menu_label = (Gtk.Label) get_child();
            return menu_label;
        }
    }
}

