/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010-2011 Diodon Team <diodon-team@lists.launchpad.net>
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
     * A gtk menu item holding a clipboard item.
     */
    class ClipboardMenuItem : Gtk.ImageMenuItem
    {
        private IClipboardItem _item;
        
        /**
         * Clipboard item constructor
         * 
         * @param item clipboard item 
         */
        public ClipboardMenuItem(IClipboardItem item)
        {
            _item = item;
            set_label(_item.get_label());
            
            // check if image needs to be shown
            Gtk.Image? image = _item.get_image();
            if(image != null) {
                set_image(image);
                set_always_show_image(true);
            }
        }
        
        /**
         * Get encapsulated clipboard item
         *
         * @return clipboard item
         */
        public IClipboardItem get_clipboard_item()
        {
            return _item;
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
        /*private Gtk.Label get_menu_label()
        {
            Gtk.Label menu_label = (Gtk.Label) get_child();
            return menu_label;
        }*/
    }
}

