/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010 Diodon Team <diodon-team@lists.launchpad.net>
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

namespace Diodon
{
    /**
     * Main class is responsible for creating all needed views, controllers
     * and models and starting the GUI application.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class Main : GLib.Object
    {
        /**
         * determine if debug mode is enabled
         */
        private static bool debug = false;
        
        private static const OptionEntry[] options = {
            { "debug", 'd', 0, OptionArg.NONE, ref debug, "Enable debug mode.", null },
            { null }
        };
    
        /**
         * Callback to mute log message
         */
        private static void mute_log_handler(string? log_domain,
            LogLevelFlags log_levels, string message)
        {
        }
    
        public static int main(string[] args)
        {
            try {
                // setup gettext
                Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
                Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
                
                // init option context
                OptionContext opt_context = new OptionContext("- Clipboard Manager for GNOME");
                opt_context.set_help_enabled(true);
                opt_context.add_main_entries(options, null);
                opt_context.parse(ref args);
                
                // mute debug log if not enabled
                if(!debug) {
                    Log.set_handler(null, LogLevelFlags.LEVEL_DEBUG, mute_log_handler);
                }

                // setup gtk
                Gtk.init(ref args);
                
                // setup storage    
                string diodon_dir = Path.build_filename(Environment.get_user_data_dir(), Config.PACKAGE_NAME);
                IClipboardStorage storage = new XmlClipboardStorage(diodon_dir, "storage.xml");
                ClipboardModel model = new ClipboardModel(storage);

                // setup controller            
                Controller controller = new Controller();
                controller.clipboard_model = model;
                controller.start();
                
                Gtk.main();
                
                return 0;
            } catch(OptionError e) {
                stdout.printf("Option parsing failed: %s\n", e.message);
                return 1;
            }
        }
    }
}

