/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2011 Diodon Team <diodon-team@lists.launchpad.net>
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
     * Class for defining utility methods to be used in any part of diodon.
     */
    public abstract class Utility : GLib.Object
    {
        /**
         * Get diodon user data dir.
         *
         * @return path to diodon user data dir
         */
        public static string get_user_data_dir()
        {
            return Path.build_filename(Environment.get_user_data_dir(), Config.PACKAGE_NAME);
        }
        
        /**
         * Create directory with all its parents logging error if not successful.
         * Checks first if directory already exists.
         *
         * @param directory directory to be created
         * @return returns true if directory already exists or creation was successful
         */
        public static bool make_directory_with_parents(string directory)
        {
            bool result = true;
             
            // make sure that all parent directories exist
            try {
                File dir = File.new_for_path(directory);
                if(!dir.query_exists(null)) {
                    result = dir.make_directory_with_parents(null);
                }
            } catch (Error e) {
                warning ("could not create directory %s", directory);
                result = false;
            }
            
            return result;
        }
    }
}

