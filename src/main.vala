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

namespace Diodon
{
    /**
     * Main class is responsible for creating all needed views, controllers
     * and models and starting the GUI application.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class Main
    {
        public static int main(string[] args)
        {
            string diodon_dir =  Environment.get_home_dir()
                + "/.local/share/diodon";
        
            // setup gettext
            Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
            Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");

            Gtk.init(ref args);
            
            // setup controller    
            Indicator indicator = new Indicator();
            IClipboardStorage storage = new XmlClipboardStorage(diodon_dir, "storage.xml");
            ClipboardModel model = new ClipboardModel(storage);
            Gtk.Clipboard clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
            Gtk.Clipboard primary = Gtk.Clipboard.get(Gdk.SELECTION_PRIMARY);
            Gee.List<Gtk.Clipboard> clipboards = new Gee.ArrayList<Gtk.Clipboard>();
            clipboards.add(clipboard);
            clipboards.add(primary);
            
            Controller controller = new Controller(indicator, model, clipboards);
            controller.start();
            
            Gtk.main();
            return 0;
        }
    }
}

