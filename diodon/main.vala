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
            
            Gtk.init(ref args);
            Unique.App app = new Unique.App(Config.BUSNAME, null);
            
            // when diodon is already running activate it or paste checksum if necessary
            if(app.is_running) {
            
                if(checksum != null) {
                    debug("Try to paste content of checksum %s", checksum);
                    Unique.MessageData checksum_data = new Unique.MessageData();
                    checksum_data.set_text(checksum, checksum.length);
                    
                    if(app.send_message(Unique.Command.OPEN, checksum_data) == Unique.Response.OK) {
                        return 0;
                    } else {
                        warning("Pasting checksum %s was unsucessful", checksum);
                    }
                }
                
                if(app.send_message(Unique.Command.ACTIVATE, null) == Unique.Response.OK) {
                    return 0;
                }
                
                critical("Diodon is already running but could not be actiaved.");
                return 1;
            }

            // setup controller            
            controller = new Controller();
            controller.init.begin();
            
            if(checksum != null) {
                debug("Select checksum %s after starting up", checksum);
                controller.select_item_by_checksum.begin(checksum);
            }
            
            // process message listener
            app.message_received.connect((command, message_data, time_) => {
                switch(command) {
                    // OPEN for pasting content of checksum
                    case Unique.Command.OPEN:
                        string checksum_recv = message_data.get_text();
                        debug("Message OPEN received with checksum %s", checksum_recv);
                        controller.select_item_by_checksum.begin(checksum_recv);
                        return Unique.Response.OK;
                    // ACTIVATE to open history
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
}

