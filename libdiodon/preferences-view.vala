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
     * Preferences dialog view loading user interface from preferences.ui
     */
    class PreferencesView : GLib.Object
    {
        private Gtk.Dialog preferences;
        public PreferencesView()
        {
        }

        /**
         * Show preferences view
         *
         * @param configuration configuration to initialize dialog
         * @param controller controller for pinned items management
         */
        public void show(ClipboardConfiguration configuration, Controller? controller = null)
        {
            // check if preferences window is already open
            if(preferences == null) {
                try {
                    // builder
                    Gtk.Builder builder = new Gtk.Builder();
                    builder.set_translation_domain(Config.GETTEXT_PACKAGE);
                    builder.add_from_file(Path.build_filename(Config.PKG_DATA_DIR, "preferences.ui"));

                    // use_clipboard
                    Gtk.ToggleButton use_clipboard =
                        builder.get_object("checkbutton_use_clipboard") as Gtk.ToggleButton;
                    use_clipboard.active = configuration.use_clipboard;
                    use_clipboard.toggled.connect(() => {
                        configuration.use_clipboard = !configuration.use_clipboard;
                    } );

                    // use_primary
                    Gtk.ToggleButton use_primary = builder.get_object("checkbutton_use_primary") as Gtk.ToggleButton;
                    use_primary.active = configuration.use_primary;
                    use_primary.toggled.connect(() => {
                        configuration.use_primary = !configuration.use_primary;
                    } );

                    // add images
                    Gtk.ToggleButton add_images = builder.get_object("checkbutton_add_images") as Gtk.ToggleButton;
                    add_images.active = configuration.add_images;
                    add_images.toggled.connect(() => {
                        configuration.add_images = !configuration.add_images;
                    } );

                    // synchronize_clipboards
                    Gtk.ToggleButton synchronize_clipboards =
                        builder.get_object("checkbutton_synchronize_clipboards") as Gtk.ToggleButton;
                    synchronize_clipboards.active = configuration.synchronize_clipboards;
                    synchronize_clipboards.toggled.connect(() => {
                        configuration.synchronize_clipboards = !configuration.synchronize_clipboards;
                    } );

                    // keep clipboard content
                    Gtk.ToggleButton keep_clipboard_content =
                        builder.get_object("checkbutton_keep_clipboard_content") as Gtk.ToggleButton;
                    keep_clipboard_content.active = configuration.keep_clipboard_content;
                    keep_clipboard_content.toggled.connect(() => {
                        configuration.keep_clipboard_content = !configuration.keep_clipboard_content;
                    } );

                    // instant paste
                    Gtk.ToggleButton instant_paste =
                        builder.get_object("checkbutton_instant_paste") as Gtk.ToggleButton;
                    instant_paste.active = configuration.instant_paste;
                    instant_paste.toggled.connect(() => {
                        configuration.instant_paste = !configuration.instant_paste;
                    } );

                    // recent_items_size
                    Gtk.SpinButton recent_items_size =
                        builder.get_object("spinbutton_recent_items_size") as Gtk.SpinButton;
                    recent_items_size.value = configuration.recent_items_size;
                    recent_items_size.value_changed.connect(() => {
                        configuration.recent_items_size = recent_items_size.get_value_as_int();
                    });
                    recent_items_size.editing_done.connect(() => {
                        configuration.recent_items_size = recent_items_size.get_value_as_int();
                    });

                    // plugins
                    PeasGtk.PluginManager manager = new PeasGtk.PluginManager(
                        Peas.Engine.get_default());
                    Gtk.Box plugins_box = builder.get_object("plugins_box") as Gtk.Box;
                    plugins_box.pack_start(manager);

                    // pinned items tab
                    if (controller != null) {
                        Gtk.Notebook notebook = builder.get_object("notebook_preferences") as Gtk.Notebook;
                        build_pinned_tab(notebook, controller);
                    }

                    // close
                    Gtk.Button close = builder.get_object("button_close") as Gtk.Button;
                    close.clicked.connect(hide);

                    // preferences
                    preferences = builder.get_object("dialog_preferences") as Gtk.Dialog;
                    preferences.destroy.connect_after(reset);
                    preferences.show_all();
                }
                catch(Error e) {
                    warning("Could not initialize preferences dialog. Error: " + e.message);
                }
            }
        }

        private bool _inhibit_save = false;
        private int _select_after_repopulate = -1;
        private Gtk.TreeView? _pinned_tree_view = null;

        private void build_pinned_tab(Gtk.Notebook notebook, Controller controller)
        {
            Gtk.Box pinned_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
            pinned_box.border_width = 12;

            Gtk.ListStore store = new Gtk.ListStore(3, typeof(Gdk.Pixbuf), typeof(string), typeof(string));
            Gtk.TreeView tree_view = new Gtk.TreeView.with_model(store);
            _pinned_tree_view = tree_view;
            tree_view.headers_visible = false;
            tree_view.reorderable = true;

            Gtk.CellRendererPixbuf icon_cell = new Gtk.CellRendererPixbuf();
            tree_view.insert_column_with_attributes(-1, "Icon", icon_cell, "pixbuf", 0);

            Gtk.CellRendererText cell = new Gtk.CellRendererText();
            cell.ellipsize = Pango.EllipsizeMode.END;
            tree_view.insert_column_with_attributes(-1, "Label", cell, "text", 1);

            populate_pinned_list(store, controller);

            store.row_deleted.connect(() => {
                if (!_inhibit_save) {
                    save_pinned_order(store, controller);
                }
            });

            string _hover_checksum = "";
            tree_view.add_events(Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            tree_view.motion_notify_event.connect((event) => {
                Gtk.TreePath? path;
                if (tree_view.get_path_at_pos((int) event.x, (int) event.y, out path, null, null, null)) {
                    Gtk.TreeIter iter;
                    if (store.get_iter(out iter, path)) {
                        string checksum;
                        store.get(iter, 2, out checksum);
                        if (checksum == _hover_checksum) {
                            return false;
                        }
                        ClipboardMenuItem.hide_preview();
                        _hover_checksum = checksum;
                        controller.get_item_by_checksum.begin(checksum, null, (obj, res) => {
                            IClipboardItem? item = controller.get_item_by_checksum.end(res);
                            if (item != null) {
                                ClipboardMenuItem.show_preview_for(item);
                            }
                        });
                    }
                }
                else {
                    _hover_checksum = "";
                    ClipboardMenuItem.hide_preview();
                }
                return false;
            });
            tree_view.leave_notify_event.connect(() => {
                _hover_checksum = "";
                ClipboardMenuItem.hide_preview();
                return false;
            });

            Gtk.Box list_and_buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);

            Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow(null, null);
            scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
            scroll.add(tree_view);
            list_and_buttons.pack_start(scroll, true, true, 0);

            Gtk.Box side_buttons = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
            Gtk.Button up_button = new Gtk.Button.with_label("\xe2\x96\xb2");
            Gtk.Button down_button = new Gtk.Button.with_label("\xe2\x96\xbc");
            Gtk.Button remove_button = new Gtk.Button.with_label(_("Unpin"));

            up_button.clicked.connect(() => {
                Gtk.TreeModel model;
                Gtk.TreeIter iter;
                if (tree_view.get_selection().get_selected(out model, out iter)) {
                    Gtk.TreeIter prev = iter;
                    if (store.iter_previous(ref prev)) {
                        store.swap(iter, prev);
                        save_pinned_order(store, controller);
                    }
                }
            });

            down_button.clicked.connect(() => {
                Gtk.TreeModel model;
                Gtk.TreeIter iter;
                if (tree_view.get_selection().get_selected(out model, out iter)) {
                    Gtk.TreeIter next = iter;
                    if (store.iter_next(ref next)) {
                        store.swap(iter, next);
                        save_pinned_order(store, controller);
                    }
                }
            });

            remove_button.clicked.connect(() => {
                Gtk.TreeModel model;
                Gtk.TreeIter iter;
                if (tree_view.get_selection().get_selected(out model, out iter)) {
                    string checksum;
                    model.get(iter, 2, out checksum);
                    ClipboardMenuItem.hide_preview();
                    Gtk.TreePath? path = store.get_path(iter);
                    int removed_index = path != null ? path.get_indices()[0] : -1;
                    _inhibit_save = true;
                    store.remove(ref iter);
                    _inhibit_save = false;
                    _select_after_repopulate = removed_index;
                    controller.toggle_pin_item.begin(checksum);
                }
            });

            side_buttons.pack_start(up_button, false, false, 0);
            side_buttons.pack_start(down_button, false, false, 0);
            side_buttons.pack_start(remove_button, false, false, 0);
            list_and_buttons.pack_start(side_buttons, false, false, 0);

            pinned_box.pack_start(list_and_buttons, true, true, 0);

            controller.on_pinned_items_changed.connect(() => {
                ClipboardMenuItem.hide_preview();
                populate_pinned_list(store, controller);
            });

            Gtk.Entry add_entry = new Gtk.Entry();
            add_entry.placeholder_text = _("Text to pin...");
            Gtk.Button add_button = new Gtk.Button.with_label(_("Add"));
            add_button.clicked.connect(() => {
                string text = add_entry.get_text().strip();
                if (text.length > 0) {
                    controller.add_and_pin_text.begin(text);
                    add_entry.set_text("");
                }
            });
            add_entry.activate.connect(() => {
                add_button.clicked();
            });

            Gtk.Box add_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            add_box.pack_start(add_entry, true, true, 0);
            add_box.pack_start(add_button, false, false, 0);
            pinned_box.pack_start(add_box, false, false, 0);

            Gtk.Label tab_label = new Gtk.Label(_("Pinned"));
            notebook.append_page(pinned_box, tab_label);
        }

        private void save_pinned_order(Gtk.ListStore store, Controller controller)
        {
            string[] checksums = {};
            Gtk.TreeIter iter;
            if (store.get_iter_first(out iter)) {
                do {
                    string checksum;
                    store.get(iter, 2, out checksum);
                    checksums += checksum;
                } while (store.iter_next(ref iter));
            }
            controller.set_pinned_checksums(checksums);
        }

        private void populate_pinned_list(Gtk.ListStore store, Controller controller)
        {
            _inhibit_save = true;
            store.clear();
            _inhibit_save = false;
            controller.get_pinned_items.begin((obj, res) => {
                List<IClipboardItem> items = controller.get_pinned_items.end(res);
                int count = 0;
                foreach (IClipboardItem item in items) {
                    Gtk.TreeIter iter;
                    store.append(out iter);
                    Gtk.Image? image = item.get_image();
                    Gdk.Pixbuf? pixbuf = null;
                    if (image != null) {
                        pixbuf = image.get_pixbuf();
                    }
                    store.set(iter, 0, pixbuf, 1, item.get_label(), 2, item.get_checksum());
                    count++;
                }
                if (_select_after_repopulate >= 0 && _pinned_tree_view != null && count > 0) {
                    int idx = _select_after_repopulate;
                    if (idx >= count) {
                        idx = count - 1;
                    }
                    Gtk.TreePath path = new Gtk.TreePath.from_indices(idx);
                    _pinned_tree_view.get_selection().select_path(path);
                    _select_after_repopulate = -1;
                }
            });
        }

        /**
         * Hide preferences view
         */
        public void hide()
        {
            preferences.close();
        }

        /**
         * Reset preferences dialog
         */
        public void reset()
        {
            ClipboardMenuItem.hide_preview();
            _pinned_tree_view = null;
            _select_after_repopulate = -1;
            preferences = null;
        }
    }
}
