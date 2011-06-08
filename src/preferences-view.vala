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
 */
 
using Gee;
 
namespace Diodon
{
    /**
     * Preferences dialog view loading user interface from preferences.ui
     * and providing signals to connect to.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class PreferencesView : GLib.Object
    {
        private Gtk.Dialog preferences;
        
        public signal void on_change_use_clipboard();
        public signal void on_change_use_primary();
        public signal void on_change_synchronize_clipboards();
        public signal void on_change_keep_cliboard_content();
        public signal void on_change_clipboard_size(int size);
        public signal void on_change_history_accelerator(string accelerator);
        public signal void on_close();

        /**
         * Show preferences view
         *
         * @param model configuration model to initialize dialog
         */
        public void show(ConfigurationModel model)
        {
            // check if preferences window is already open
            if(preferences == null) {
                try {
                    // builder
                    Gtk.Builder builder = new Gtk.Builder();
                    builder.set_translation_domain(Config.GETTEXT_PACKAGE);
                    builder.add_from_file(Path.build_filename(Config.SHAREDIR, "preferences.ui"));
                    
                    // use_clipboard
                    Gtk.ToggleButton use_clipboard = 
                        builder.get_object("checkbutton_use_clipboard") as Gtk.ToggleButton;
                    use_clipboard.active = model.use_clipboard;
                    use_clipboard.toggled.connect(() => { on_change_use_clipboard(); } );
                    
                    // use_primary
                    Gtk.ToggleButton use_primary = builder.get_object("checkbutton_use_primary") as Gtk.ToggleButton;
                    use_primary.active = model.use_primary;
                    use_primary.toggled.connect(() => { on_change_use_primary(); } );
                    
                    // synchronize_clipboards
                    Gtk.ToggleButton synchronize_clipboards = 
                        builder.get_object("checkbutton_synchronize_clipboards") as Gtk.ToggleButton;
                    synchronize_clipboards.active = model.synchronize_clipboards;
                    synchronize_clipboards.toggled.connect(() => { on_change_synchronize_clipboards(); } );
                    
                    // keep clipboard content
                    Gtk.ToggleButton keep_clipboard_content =
                        builder.get_object("checkbutton_keep_cliboard_content") as Gtk.ToggleButton;
                    keep_clipboard_content.active = model.keep_clipboard_content;
                    keep_clipboard_content.toggled.connect(() => { on_change_keep_cliboard_content(); } );
                    
                    // clipboard_size
                    Gtk.SpinButton clipboard_size = 
                        builder.get_object("spinbutton_clipboard_size") as Gtk.SpinButton;
                    clipboard_size.value = model.clipboard_size;
                    clipboard_size.value_changed.connect(() => {
                        on_change_clipboard_size(clipboard_size.get_value_as_int());
                    });
                    clipboard_size.editing_done.connect(() => {
                        on_change_clipboard_size(clipboard_size.get_value_as_int());
                    });
                    
                    // history_accelerator
                    Gtk.Entry history_accelerator = 
                        builder.get_object("entry_history_accelerator") as Gtk.Entry;
                    history_accelerator.text = model.history_accelerator;
                    history_accelerator.changed.connect(() => {
                        on_change_history_accelerator(history_accelerator.get_text());
                    });
                    
                    // close
                    Gtk.Button close = builder.get_object("button_close") as Gtk.Button;
                    close.clicked.connect(() => { on_close(); } );
                    
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
            preferences.hide();
            preferences.destroy();
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

