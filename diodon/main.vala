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
         * main clipboard controller
         */
        private Controller? controller = null;

        /**
         * determine whether help information should be printed
         */
        private static bool show_help = false;

        /**
         * store unmached options and possible actions
         */
        private static string[] remaining_options;

        /**
         * list of available command line options
         */
        private static const OptionEntry[] options = {
            { OPTION_REMAINING, '\0', 0, OptionArg.STRING_ARRAY, ref remaining_options, null, "<action> | [CHECKSUM]" },
            { "help", 'h', 0, OptionArg.NONE, ref show_help, "Show help options", null },
            { "version", 'v', 0, OptionArg.NONE, ref show_version, "Print version information", null },
            { null }
        };
        
        public DiodonApplication()
        {
            Object(application_id: Config.BUSNAME, flags: ApplicationFlags.HANDLES_COMMAND_LINE);
            
            command_line.connect (handle_command_line);

            // add supported actions
            SimpleAction paste_action = new SimpleAction("paste-action", VariantType.STRING);
            paste_action.activate.connect(activate_paste_action);
            add_action(paste_action);
        }
        
        public void activate_paste_action(GLib.Variant? parameter)
        {

            if(parameter == null || controller == null) 
                return;

            string checksum = parameter.get_strv ()[0];
            if (checksum == null)
                return;

            hold();

            // it might be an uri so we have to remove uri first before
            // TODO: 
            // see ZeitgeistClipboardStorage.CLIPBOARD_URI why clipboard:
            // is used staticly here
            checksum = checksum.replace("clipboard:", "");
            debug("Execute paste with checksum %s", checksum);
            controller.select_item_by_checksum.begin(checksum);
            
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
        
        /**
         * Process command line arguments
         */
        private int handle_command_line (ApplicationCommandLine command_line)
        {
            string[] args = command_line.get_arguments ();
            show_version = false;
            show_help = false;
            remaining_options = new string[args.length];

            StringBuilder summary = new StringBuilder ("Actions:\n");
            if (controller != null)
            {
                Gee.Map<string,string> descs = controller.get_command_descriptions ();
                if(descs.size > 0) {
                    foreach (Gee.Map.Entry<string,string> entry in descs.entries) {
                        summary.append_printf ("  %-25s%s\n", entry.key, entry.value);
                    }
                } else {
                    summary.append ("  None");
                }
                
            } else {
                summary.append("  Actions are only available while diodon is running.");
            }

            try
            {
                OptionContext opt_context = new OptionContext("- GTK+ Clipboard Manager");
                opt_context.set_summary (summary.str);
                opt_context.set_help_enabled(false);
                opt_context.add_main_entries(options, null);
                opt_context.add_group(Gtk.get_option_group(true));
                // to support vala 0.22
                // TODO: once upgrade to a newer vala version
                // this needs to be reverted
                // opt_context.parse_strv (ref args);
                OptionContextExtended.parse_strv (opt_context, ref args);

                if(show_help) {
                    command_line.print(opt_context.get_help (true, null));
                    return 0;
                }

                if(show_version) {
                    command_line.print("Diodon %s\n", Config.VERSION);
                    return 0;
                }

                if (remaining_options.length > 0 && remaining_options[0] != null
                    && controller != null)
                {
                    // check if diodon has been called with a registered action
                    if (has_action (remaining_options[0]))
                    {
                        int i = 1;
                        while (remaining_options[i] != null) {
                            i++;
                        }

                        activate_action(remaining_options[0], new Variant.strv(remaining_options[1:i]));
                        return 0;
                    }
                    // check if it is a checksum and paste action can be executed
                    else if (remaining_options[0].length == 40) {
                        activate_action("paste", new Variant.strv(remaining_options[0:1]));
                        return 0;
                    } else  {
                        warning("Invalid action '%s'", remaining_options[0]);
                        return 1;
                    }
                }
                
                // no options - activate Diodon by either starting or showing menu                
                activate ();
                return 0;
            } catch(OptionError e) {
                stdout.printf("Option parsing failed: %s\n", e.message);
            }

            return 1;
        }

        public static int main(string[] args)
        {
            // setup gettext
            Intl.textdomain(Config.GETTEXT_PACKAGE);
            Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
            Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
            Intl.setlocale(LocaleCategory.ALL, "");
            
            // diodon should only show up in gnome
            DesktopAppInfo.set_desktop_env("GNOME");
            
            DiodonApplication app = new DiodonApplication();
            return app.run(args);
        }
    }
}

