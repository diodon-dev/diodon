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
         * This method is a workaround for string.substring which
         * produces invalid utf-8 in some cases.
         * See https://bugzilla.gnome.org/show_bug.cgi?id=653088
         */
        public static string substring(string str, int length)
        {
            string result = "";
            for(int i=0; i < length; ++i) {
                unichar c = str.get_char(i);
                if(c.validate()) {
                  result = result.concat(c.to_string());
                }
            }
            
            return result;
        }
    }
}

