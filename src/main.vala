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

#if(UNITY_LENS)

    /**
     * Unity lens daemon
     */
    private UnityLens.Daemon? lens_daemon = null;
    
#endif

    /**
     * main clipboard controller
     */
    private Controller? controller = null;
    
    /**
     * determine if debug mode is enabled
     */
    private static bool debug_enabled = false;
    
    /**
     * determine whether version information should be printed
     */
    private static bool show_version = false;
    
    /**
     * list of available command line options
     */
    private static const OptionEntry[] options = {
        { "debug", 'd', 0, OptionArg.NONE, ref debug_enabled, "Enable debug mode", null },
        { "version", 'v', 0, OptionArg.NONE, ref show_version, "Print version information", null },
        { null }
    };

    /**
     * starter method responsible for creating all needed views, controllers
     * and models and starting the GUI application and the unity lens daemon
     */
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
            
            // setup gtk
            Gtk.init(ref args);
            
            // setup storage    
            string diodon_dir = Utility.get_user_data_dir();
            IClipboardStorage storage = new XmlClipboardStorage(diodon_dir, "storage.xml");
            ClipboardModel model = new ClipboardModel(storage);
            
            // setup plugin engine
            Peas.Engine engine = Peas.Engine.get_default();
            string plugins_dir = Path.build_filename(diodon_dir, "plugins");
            engine.add_search_path(plugins_dir, plugins_dir);
            // engine.enable_loader("python")
            // TODO: add usr/share search path
            PeasGtk.PluginManager manager = new PeasGtk.PluginManager();

            // setup controller            
            controller = new Controller();
            controller.clipboard_model = model;
            controller.start();
            
            // Export the lens daemon on the session bus - as everywhere else
            // these values should match those definedd in the .place file 
            Bus.own_name(BusType.SESSION, Config.BUSNAME + ".Unity.Lens.Diodon",
                BusNameOwnerFlags.NONE, on_bus_acquired, on_name_acquired, on_name_lost);
            
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
    
    /**
     * Called when bus has been acquired
     */
    private static void on_bus_acquired (DBusConnection conn, string name)
    {
        debug("Connected to session bus - checking for existing instances...");
        
#if(UNITY_LENS)
        /* We need to set up our DBus objects *before* we know if we've acquired
         * the name. This is a bit unfortunate because it means we might do work
         * for no reason if another daemon is already running. See
         * https://bugzilla.gnome.org/show_bug.cgi?id=640714 */
        lens_daemon = new UnityLens.Daemon(controller.clipboard_model);
        controller.lens_daemon = lens_daemon;
#endif
    }

    /**
     * Called when dbus connection name has been accired.
     */
    private static void on_name_acquired (DBusConnection conn, string name)
    {
        debug ("Acquired name %s. We're the main instance.\nAll system are go.",
               name);
    }

    /**
     * Called when dbus connection has been lost
     */
    private static void on_name_lost (DBusConnection conn, string name)
    {
        debug ("Another daemon is running.\nBailing out.");
        Gtk.main_quit();
    }
}

