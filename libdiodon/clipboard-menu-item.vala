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
     * A gtk menu item holding a checksum of a clipboard item. It only keeps
     * the checksum as it would waste memory to keep the hole item available.
     */
    class ClipboardMenuItem : Gtk.MenuItem
    {
        private string _checksum;

        /**
         * Clipboard item constructor
         *
         * @param item clipboard item
         */
        public ClipboardMenuItem(IClipboardItem item)
        {
            _checksum = item.get_checksum();

            Gtk.Image? image = item.get_image();
            if(image != null) {
                // For image items: display a large centered thumbnail
                // spanning the full tile, instead of a small icon on the left

                // Remove any default child widget from the menu item
                var existing_child = get_child();
                if (existing_child != null) {
                    remove(existing_child);
                }

                // Vertical box: thumbnail on top, dimension label below
                var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 2);
                box.set_halign(Gtk.Align.CENTER);
                box.set_valign(Gtk.Align.CENTER);
                box.set_can_focus(false);
                box.margin_top = 4;
                box.margin_bottom = 4;
                box.margin_start = 8;
                box.margin_end = 8;

                // Center the thumbnail within the full tile width
                image.set_halign(Gtk.Align.CENTER);
                image.set_valign(Gtk.Align.CENTER);
                image.set_can_focus(false);

                // Request explicit size so the menu allocates enough space
                Gdk.Pixbuf? pix = image.get_pixbuf();
                if (pix != null) {
                    image.set_size_request(pix.width, pix.height);
                }

                box.pack_start(image, false, false, 0);

                add(box);

                // Show image dimensions on hover
                set_tooltip_text(item.get_label());
            } else {
                // Remove default child to replace with a wrapping label
                var existing_child = get_child();
                if (existing_child != null) {
                    remove(existing_child);
                }

                var label = new Gtk.Label(item.get_label());
                label.set_xalign(0);
                label.set_line_wrap(true);
                label.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
                label.set_max_width_chars(50);
                label.set_lines(4);
                label.set_ellipsize(Pango.EllipsizeMode.END);
                add(label);
            }
        }

        /**
         * Get encapsulated clipboard item checksum
         *
         * @return clipboard item checksum
         */
        public string get_item_checksum()
        {
            return _checksum;
        }

        /**
         * Highlight item by changing label to bold
         * TODO: get this up and running
         */
        /*public void highlight_item()
        {
            Gtk.Label label = get_menu_label();
            label.set_markup("<b>%s</b>".printf(get_label()));
        }*/

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

