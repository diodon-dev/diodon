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
 */

namespace Diodon
{
    /**
     * Class for defining utility methods to be used in any part of diodon.
     * 
     * @author Oliver Sauder <os@esite.ch>
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
        
        /**
         * Compara pixbufs pixel by pixel
         *
         * @param pixbufa pix buf to be compared
         * @param pixbufb pix buf to be compared
         * @return true if pixbufs are equal; otherwise false.
         */
        public static bool compare_pixbufs(Gdk.Pixbuf pixbufa, Gdk.Pixbuf pixbufb)
        {
            // check for dimensions
            if(pixbufa.width != pixbufb.width || 
                pixbufa.rowstride != pixbufb.rowstride || pixbufa.height != pixbufb.height) {
                
                return false; // images have different size
            }
            
            uchar* pixelsa = (uchar*)pixbufa.pixels;
            uchar* pixelsb = (uchar*)pixbufb.pixels;
            int height = pixbufa.height;
            int rowstride = pixbufa.rowstride;
            int width = pixbufa.width;
            
            for(int i = 0; i < height; ++i) {
                uchar* rowa = pixelsa + (i * rowstride);
                uchar* rowb = pixelsb + (i * rowstride);
                
                for(int j = 0; j < width; ++j) {
                    if(*rowa != *rowb) {
                        return false; // one pixels differs
                    }
                    
                    rowa++;
                    rowb++;
                }
            }
            
            return true;
        }
        
        /**
         * Convert given target list to an array of target entries
         *
         * @param target_list list to be converted
         */
        public static Gtk.TargetEntry[] convert_target_entries(Gtk.TargetList target_list)
        {
            // converting target list to target entries
            // leaving one target entry for special target (s. below)
            Gtk.TargetEntry[] targets = new Gtk.TargetEntry[target_list.list.length()];
            // TODO: workaround needed so names will be freed as
            // TargetEntry.target is a weak reference
            string[] names = new string[target_list.list.length()];
            int i = 0;
            foreach(weak Gtk.TargetPair pair in target_list.list) {
                // TODO: another workaround as Gdk.Atom name
                // binding returns a unowned string as it shouldn't
                // see https://bugzilla.gnome.org/show_bug.cgi?id=645215
                string* tmp = pair.target.name();
                names[i] = tmp->dup();
                targets[i].target = names[i];
                delete tmp;
                ++i;
            }
            
            return targets;
        }
    }
}

