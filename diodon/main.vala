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
 *
 * Author:
 *  Oliver Sauder <os@esite.ch>
 */
 
namespace Diodon
{
    /**
     * determine if debug mode is enabled
     */
    private static bool debug_enabled = false;
    
    /**
     * determine whether version information should be printed
     */
    private static bool show_version = false;
    
    /**
     * main clipboard controller
     */
    private Controller? controller = null;
    
    /**
     * list of available command line options
     */
    private static const OptionEntry[] options = {
        { "debug", 'd', 0, OptionArg.NONE, ref debug_enabled, "Enable debug mode", null },
        { "version", 'v', 0, OptionArg.NONE, ref show_version, "Print version information", null },
        { null }
    };

    public static int main(string[] args)
    {
        try {
            // setup gettext
            Intl.textdomain(Config.GETTEXT_PACKAGE);
            Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
            Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
            Intl.setlocale(LocaleCategory.ALL, "");
            
            // diodon should only show up in gnome
            DesktopAppInfo.set_desktop_env("GNOME");
            
            // init option context
            OptionContext opt_context = new OptionContext("- GTK+ Clipboard Manager");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(options, null);
            opt_context.parse(ref args);
            
            if(show_version) {
                stdout.printf("Diodon %s\n", Config.VERSION);
                return 0; // bail out
            }
            
            // mute debug log if not enabled
            if(!debug_enabled) {
                Log.set_handler(null, LogLevelFlags.LEVEL_DEBUG, mute_log_handler);
            }
            
            Gtk.init(ref args);
            Unique.App app = new Unique.App(Config.BUSNAME, null);
            
            // when diodon is already running activate it
            if(app.is_running) {
                if(app.send_message(Unique.Command.ACTIVATE, null) == Unique.Response.OK) {
                    return 0;
                }
                else {
                    critical("Diodon is already running but could not be actiaved.");
                    return 1;
                }
            }

            // setup controller            
            controller = new Controller();
            controller.init();
            
            // register app activate will open controller history
            app.message_received.connect((command, message_data, time_) => {
                switch(command) {
                    case Unique.Command.ACTIVATE:
                        controller.show_history();
                        return Unique.Response.OK;
                     default:
                        return Unique.Response.INVALID;
                }
            });
            
            Gtk.main();
            
            return 0;
        } catch(OptionError e) {
            stdout.printf("Option parsing failed: %s\n", e.message);
            return 1;
        }
    }
    
    /**
     * Callback to mute log message
     */
    private static void mute_log_handler(string? log_domain,
        LogLevelFlags log_levels, string message)
    {
    }
}

