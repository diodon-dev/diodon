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
     * Main class. Providing functionality to
     * start diodon.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class Main
    {
        public static int main (string[] args)
        {
            // setup gettext TODO: get it up and running
            //Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);
            //Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
    
            // setup indicator
            Indicator indicator = new Indicator();
            
            Gtk.init (ref args);
            Gtk.main();

            return 0;
        }
    }
}
