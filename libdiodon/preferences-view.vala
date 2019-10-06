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
         * @param configuraiton configuration to initialize dialog
         */
        public void show(ClipboardConfiguration configuration)
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
            preferences = null;
        }
    }
}

