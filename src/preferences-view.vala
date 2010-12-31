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
     * Preferences dialog view loading user interface from preferences.ui
     * and providing signals to connect to.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class PreferencesView : GLib.Object
    {
        private Gtk.Builder builder;
        
        /**
         * Constructor.
         *
         * @param object object to connect signals too
         */
        public PreferencesView(GLib.Object object)
        {
            try {
                builder = new Gtk.Builder();
                builder.add_from_file("/home/sao/src/bzr/launchpad/projects/diodon/trunk/data/preferences.ui");
                builder.connect_signals(object);
            }
            catch(GLib.Error e) {
                error("Could not initialize preferences dialog. Error: " + e.message);
            }
        }
        
        /**
         * Show preferences view
         *
         * @param model configuration model to initialize dialog
         */
        public void show(ConfigurationModel model)
        {
            if(builder != null)
            {
                Gtk.ToggleButton use_clipboard = builder.get_object("checkbutton_use_clipboard") as Gtk.ToggleButton;
                use_clipboard.active = model.use_clipboard;
                
                Gtk.ToggleButton use_primary = builder.get_object("checkbutton_use_primary") as Gtk.ToggleButton;
                use_primary.active = model.use_primary;
                
                Gtk.ToggleButton synchronize_clipboards = builder.get_object("checkbutton_synchronize_clipboards") as Gtk.ToggleButton;
                synchronize_clipboards.active = model.synchronize_clipboards;
                
                Gtk.SpinButton clipboard_size = builder.get_object("spinbutton_clipboard_size") as Gtk.SpinButton;
                clipboard_size.value = model.clipboard_size;
                
                Gtk.Entry history_key = builder.get_object("entry_history_key") as Gtk.Entry;
                history_key.text = model.history_accelerator;
                
                Gtk.Dialog preferences = builder.get_object("dialog_preferences") as Gtk.Dialog;
                preferences.show_all();
            }
        }
    }
}

