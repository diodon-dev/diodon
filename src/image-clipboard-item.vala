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
     * Represents a image clipboard item holding a byte array of data
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ImageClipboardItem : GLib.Object, IClipboardItem
    {
        private ClipboardType _clipboard_type;
        private Gdk.Pixbuf _pixbuf;
        
        /**
         * path where pixbuf image has been temporarily stored
         */
        private string _path;
        
        /**
         * Default data constructor needed for reflection.
         * 
         * @param clipboard_type clipboard type item is coming from
         * @param data image path
         */ 
        public ImageClipboardItem(ClipboardType clipboard_type, string data) throws GLib.Error
        {
            _clipboard_type = clipboard_type;
            _path = data;
            _pixbuf = new Gdk.Pixbuf.from_file(data);
        }
        
        /**
         * Create image clipboard item by a pixbuf which will be stored to the
         * disc for later use.
         * 
         * @param clipboard_type clipboard type item is coming from
         * @param pixbuf image from clipboard
         */
        public ImageClipboardItem.with_image(ClipboardType clipboard_type, Gdk.Pixbuf pixbuf) throws GLib.Error
        {
            _clipboard_type = clipboard_type;
            _pixbuf = pixbuf;
            _path = save_pixbuf(pixbuf);
        }
    
        /**
	     * {@inheritDoc}
	     */
        public ClipboardType get_clipboard_type()
        {
            return _clipboard_type;
        }
        
        /**
	     * {@inheritDoc}
	     */
	    public string get_clipboard_data()
        {
            return _path;
        }

        /**
	     * {@inheritDoc}
	     */
        public string get_label()
        {
            // label in format [{width}x{height}]            
            return "[%dx%d]".printf(_pixbuf.get_width(), _pixbuf.get_height());
        }
        
        /**
	     * {@inheritDoc}
	     */
        public Gtk.Image? get_image()
        {
            // get menu icon size
            Gtk.IconSize size = Gtk.IconSize.MENU;
            int width, height;
            if(!Gtk.icon_size_lookup(size, out width, out height)) {
                // set default when icon size lookup fails
                width = 16;
                height = 16;
            }
            
            // scale pixbuf to menu icon size
            Gdk.Pixbuf scaled = _pixbuf.scale_simple(width, height, Gdk.InterpType.BILINEAR);
            return new Gtk.Image.from_pixbuf(scaled);
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void to_clipboard(Gtk.Clipboard clipboard)
        {
            clipboard.set_image(_pixbuf);
            clipboard.store();
        }
        
        /**
	     * {@inheritDoc}
	     */
	    public void remove()
        {
            debug("Removing image %s from storage", _path);
            // remove temporarily stored image
            File image = File.new_for_path(_path);
            try {
                image.delete();
            } catch (Error e) {
                warning ("removing of image file %s failed. Cause: %s", _path, e.message);
            }
        }
        
        /**
	     * {@inheritDoc}
	     */
	    public bool equals(IClipboardItem* item)
        {
            bool equals = false;
            
            if(item is ImageClipboardItem) {
                ImageClipboardItem* image_item = (ImageClipboardItem*)item;
                equals = Utility.compare_pixbufs(_pixbuf, image_item->_pixbuf);
            }
            
            return equals;
        }
        
        /**
	     * {@inheritDoc}
	     */
	    public uint hash()
        {
            // build a hash code with the three dimension identifiers
            // see http://java.sun.com/developer/Books/effectivejava/Chapter3.pdf
            // for a documentation
            int prime = 37;
            int result = 23;
        
            int width = _pixbuf.width;
            int height = _pixbuf.height;
            int rowstride = _pixbuf.rowstride;
            
            result = prime * result + width;
            result = prime * result + height;
            result = prime * result + rowstride;
            
            return result;
        }
        
        /**
         * Store pixbuf to file system and return path to it.
         *
         * @param pixbuf pixbuf to be stored
         */
        private static string save_pixbuf(Gdk.Pixbuf pixbuf) throws GLib.Error
        {
            // create a file name in the diodon user data dir images folder
            string filename = "";
            string data_dir = Utility.get_user_data_dir();
            string image_data_dir = Path.build_filename(data_dir, "images");
            
            if(Utility.make_directory_with_parents(image_data_dir)) {
            
                // image file name equal timestamp in seconds
                // plus a random number in case when multiple images
                // are copied to a clipboard in one second
                int id = Random.int_range(1000, 9999);
                DateTime now = new DateTime.now_local();
                string name = now.format("%Y%m%d-%H%M%S") + "-%i.png".printf(id);
                
                filename = Path.build_filename(image_data_dir, name);
                pixbuf.save(filename, "png");
            }
        
            return filename;
        }
    }  
}

