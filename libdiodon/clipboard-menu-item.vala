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
    class ClipboardMenuItem : Gtk.ImageMenuItem
    {
        private string _checksum;
        private IClipboardItem _item;
        private Gdk.Pixbuf? _cached_preview;
        private bool _preview_loaded;
        private static Gtk.Window? _preview_window;

        /**
         * Clipboard item constructor
         *
         * @param item clipboard item
         */
        public ClipboardMenuItem(IClipboardItem item)
        {
            _checksum = item.get_checksum();
            _item = item;
            set_label(item.get_label());

            // check if image needs to be shown
            Gtk.Image? image = item.get_image();
            if(image != null) {
                set_image(image);
                set_always_show_image(true);
            }

            debug("ClipboardMenuItem: connecting select/deselect for %s", _checksum);
            select.connect(on_item_select);
            deselect.connect(on_item_deselect);
        }

        private Gdk.Pixbuf? get_preview()
        {
            if (!_preview_loaded) {
                _cached_preview = _item.get_preview_pixbuf();
                _preview_loaded = true;
            }
            return _cached_preview;
        }

        private void on_item_select()
        {
            debug("on_item_select: checksum=%s", _checksum);
            Gdk.Pixbuf? preview = get_preview();
            if (preview == null) {
                debug("on_item_select: no preview available");
                return;
            }
            debug("on_item_select: preview %dx%d", preview.width, preview.height);
            show_preview_pixbuf(preview);
        }

        public static void show_preview_for(IClipboardItem item)
        {
            Gdk.Pixbuf? preview = item.get_preview_pixbuf();
            if (preview == null) {
                return;
            }
            show_preview_pixbuf(preview);
        }

        private static void show_preview_pixbuf(Gdk.Pixbuf preview)
        {
            if (_preview_window == null) {
                _preview_window = new Gtk.Window(Gtk.WindowType.POPUP);
                _preview_window.set_type_hint(Gdk.WindowTypeHint.TOOLTIP);
                _preview_window.set_app_paintable(true);
                Gdk.Screen screen = _preview_window.get_screen();
                Gdk.Visual? visual = screen.get_rgba_visual();
                if (visual != null) {
                    _preview_window.set_visual(visual);
                }
            }
            _preview_window.foreach((child) => { _preview_window.remove(child); });
            Gtk.Image preview_image = new Gtk.Image.from_pixbuf(preview);
            Gtk.CssProvider css = new Gtk.CssProvider();
            try {
                css.load_from_data("frame { border: 1px solid #888888; }", -1);
            } catch (Error e) {
                warning("Failed to load preview CSS: %s", e.message);
            }
            Gtk.Frame frame = new Gtk.Frame(null);
            frame.set_shadow_type(Gtk.ShadowType.NONE);
            frame.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            frame.add(preview_image);
            _preview_window.add(frame);
            _preview_window.resize(preview.width, preview.height);
            Gdk.Display? display = Gdk.Display.get_default();
            Gdk.Seat? seat = display != null ? display.get_default_seat() : null;
            if (seat != null) {
                int mouse_x, mouse_y;
                seat.get_pointer().get_position(null, out mouse_x, out mouse_y);
                int x = mouse_x + 16;
                int y = mouse_y + 16;
                Gdk.Screen screen = _preview_window.get_screen();
                int screen_height = screen.get_height();
                if (y + preview.height > screen_height) {
                    y = screen_height - preview.height;
                }
                if (y < 0) {
                    y = 0;
                }
                _preview_window.move(x, y);
            }
            _preview_window.show_all();
        }

        private static void on_item_deselect()
        {
            hide_preview();
        }

        public static void hide_preview()
        {
            if (_preview_window != null) {
                _preview_window.hide();
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

