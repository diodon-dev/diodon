/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010-2014 Diodon Team <diodon-team@lists.launchpad.net>
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
    public class DiodonApplication : Gtk.Application
    {
        /**
         * collects all non-option arguments which would otherwise be left in argv.
         */
        private const string OPTION_REMAINING = "";
        
        /**
         * determine whether version information should be printed
         */
        private static bool show_version = false;
        
        /**
         * checksums to be pasted. should only be one though
         */
        private static string[] checksums;
        
        /**
         * main clipboard controller
         */
        private Controller? controller = null;
        
        /**
         * list of available command line options
         */
        private static const OptionEntry[] options = {
            { OPTION_REMAINING, '\0', 0, OptionArg.STRING_ARRAY, ref checksums, null, "[CHECKSUM]" },
            { "version", 'v', 0, OptionArg.NONE, ref show_version, "Print version information", null },
            { null }
        };
        
        public DiodonApplication()
        {
            Object(application_id: Config.BUSNAME, flags: ApplicationFlags.FLAGS_NONE, register_session: true);
            
            // add supported actions
            SimpleAction paste_action = new SimpleAction("paste-action", VariantType.STRING);
            paste_action.activate.connect(activate_paste_action);
            add_action(paste_action);
        }
        
        public void activate_paste_action(GLib.Variant? parameter)
        {
            hold();
            
            if(parameter != null && controller != null) {
                string checksum = parameter.get_string();
                debug("Execute paste-action with checksum %s", checksum);
                controller.select_item_by_checksum.begin(checksum);
            }
            
            release();
        }
        
        public override void activate()
        {
            debug("Activate DiodonApplication (Version %s)", Config.VERSION);
            
            if(controller == null) {
                // setup controller            
                controller = new Controller();
                controller.init.begin();
                
                Gtk.main();
            } else {
                // Diodon running already, let's show history
                controller.show_history();
            }
        }
        
        public override void shutdown()
        {
            base.shutdown();
            
            if(controller != null) {
                controller.dispose();
                controller = null;
            }
        }
        
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
                
                // init vars
                checksums = new string[1];  // can only process one checksum max
                
                // init option context
                OptionContext opt_context = new OptionContext("- GTK+ Clipboard Manager");
                opt_context.set_help_enabled(true);
                opt_context.add_main_entries(options, null);
                opt_context.add_group(Gtk.get_option_group(true));
                opt_context.parse(ref args);
                
                if(show_version) {
                    stdout.printf("Diodon %s\n", Config.VERSION);
                    return 0; // bail out
                }
                
                // check whether there is a checksum of clipboard content to paste
                string checksum = null;
                if(checksums.length > 0 && checksums[0] != null) {
                    checksum = checksums[0];
                    
                    // it might be an uri so we have to remove uri first before
                    // TODO: 
                    // see ZeitgeistClipboardStorage.CLIPBOARD_URI why clipboard:
                    // is used staticly here
                    checksum = checksum.replace("clipboard:", "");
                }
                
                DiodonApplication app = new DiodonApplication();
                
                // application has to be terminiated gracefully
                Unix.signal_add(ProcessSignal.INT, () => { app.controller.quit(); return true; });
                Unix.signal_add(ProcessSignal.TERM, () => { app.controller.quit(); return true; });
                Unix.signal_add(ProcessSignal.HUP, () => { app.controller.quit(); return true; });
                
                if(checksum != null) {
                    debug("activate paste-action with checksum %s", checksum);
                    app.register();
                    app.activate_action("paste-action", new Variant.string(checksum));
                    return 0;
                }
                
                return app.run(args);
            } catch(OptionError e) {
                stdout.printf("Option parsing failed: %s\n", e.message);
            } catch(Error e) {
                stdout.printf("Unexpected error occured: %s\n", e.message);
            }
            
            return 1;
        }
    }
}

