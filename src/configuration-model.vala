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
     * The configruation model encapsulates the configuration state.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ConfigurationModel : GLib.Object
    {
        /**
         * key of use primary key flag
         */
        public string use_primary_key { get { return "/clipboard/use_primary"; } }
        
        /**
         * flag whether primary selection is enabled
         */
        public bool use_primary { get; set; default = true; }
        
        /**
         * key of use clipboard key flag
         */
        public string use_clipboard_key { get { return "/clipboard/use_clipboard"; } }
        
        /**
         * flag whether clipboard is enabled
         */
        public bool use_clipboard { get; set; default = true; }
    }
}

