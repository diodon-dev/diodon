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
        private unowned List<Gtk.Widget> static_menu_items;

        // Debounce source ID for speculative warm-up.
        // Prevents the "Thundering Herd" when user holds Down Arrow
        // and rapidly scrolls through 50 items — only the item they
        // stop on (after 150ms of no movement) triggers a decode.
        private uint _warmup_source_id = 0;

        /**
         * Create clipboard menu
         *
         * @param controller reference to controller
         * @param items clipboard items to be shown
         * @param menu_items additional menu items to be added after separator
         * @param privacy_mode check whether privacy mode is enabled
         */
        public ClipboardMenu(Controller controller, List<IClipboardItem> items, List<Gtk.MenuItem>? static_menu_items, bool privace_mode, string? error = null)
        {
            this.controller = controller;
            this.static_menu_items = static_menu_items;

            if(error != null) {
                Gtk.MenuItem error_item = new Gtk.MenuItem.with_label(wrap_label(error));
                error_item.set_sensitive(false);
                append(error_item);
            } else if(items.length() <= 0) {
                Gtk.MenuItem empty_item = new Gtk.MenuItem.with_label(_("<Empty>"));
                empty_item.set_sensitive(false);
                append(empty_item);
            }

            if(privace_mode) {
                Gtk.MenuItem privacy_item = new Gtk.MenuItem.with_label(
                    _("Privacy mode is enabled. No new items will be added to history!")
                );
                privacy_item.set_sensitive(false);
                append(privacy_item);
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
        }

        /**
         * Append given clipboard item to menu.
         *
         * For image items, also hooks the `select` signal to trigger
         * speculative pixbuf warm-up when the user hovers/navigates
         * to the item. This pre-decodes the full image in an idle
         * callback so paste is instant when they click.
         *
         * @param entry entry to be added
         */
        public void append_clipboard_item(IClipboardItem item)
        {
            ClipboardMenuItem menu_item = new ClipboardMenuItem(item);
            menu_item.activate.connect(on_clicked_item);

            // Speculative decode with debounce: when user hovers an
            // image item, schedule warm-up after 150ms of no movement.
            // This prevents the "Thundering Herd" — holding Down Arrow
            // through 50 items won't spawn 50 decode tasks. Only the
            // item the user stops on actually triggers a decode.
            if (menu_item.is_image_item()) {
                menu_item.select.connect(() => {
                    // Cancel any pending warm-up from a previous item
                    if (_warmup_source_id != 0) {
                        GLib.Source.remove(_warmup_source_id);
                        _warmup_source_id = 0;
                    }
                    string cs = menu_item.get_item_checksum();
                    _warmup_source_id = GLib.Timeout.add(150, () => {
                        ImageCache.get_default().warm_pixbuf(cs);
                        _warmup_source_id = 0;
                        return GLib.Source.REMOVE;
                    });
                });
            }

            menu_item.show();
            append(menu_item);
        }

        public void show_menu()
        {
            // timer is needed to workaround race condition between X11 and Gdk event
            // otherwise popup does not open
            Timeout.add(
                250,
                () => {
                    popup(null, null, null, 0, Gtk.get_current_event_time());
                    // Focus the first item by default for keyboard navigation
                    select_first(true);
                    return false;
                }
            );
        }

        /**
         * Completely destroy menu by cleaning up menu items and menu itself.
         */
        public void destroy_menu()
        {
            // Cancel any pending warm-up before destroying
            if (_warmup_source_id != 0) {
                GLib.Source.remove(_warmup_source_id);
                _warmup_source_id = 0;
            }

            foreach(Gtk.Widget item in get_children()) {
                remove(item);

                // make sure that static items do not get destroyed
                if(static_menu_items == null || static_menu_items.find(item) == null)
                {
                    item.destroy();
                    item.dispose();
                }
            }

            destroy();
            dispose();
        }

        /**
         * Wrap label at colons and dots.
         */
        private string wrap_label(string label)
        {
           string _label = label.replace(": ", ":\n");
           _label.replace(". ", ".\n");
           return _label;
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

        /**
         * Allow moving of cursor with vi-style j and k keys
         */
        private bool on_key_pressed(Gdk.EventKey event)
        {
            uint down_keyval = Gdk.keyval_from_name("j");
            uint up_keyval = Gdk.keyval_from_name("k");

            uint pressed_keyval = Gdk.keyval_to_lower(event.keyval);
            if(pressed_keyval == down_keyval) {
                if(get_selected_item() == null) {
                    select_first(true);
                } else {
                    move_selected(1);
                }
                return true;
            }
            if(pressed_keyval == up_keyval) {
                if(get_selected_item() == null) {
                    select_first(true);
                }
                move_selected(-1);
                return true;
            }

            return false;
        }
    }
}
