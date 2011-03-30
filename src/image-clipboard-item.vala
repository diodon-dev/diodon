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
     * Represents a image clipboard item holding. For memory consumption
     * reasons the pixbuf is not hold in the memory but stored to the disc
     * and only loaded when requested.
     * However a scaled pixbuf of the image is still needed for preview reasons.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ImageClipboardItem : GLib.Object, IClipboardItem
    {
        private ClipboardType _clipboard_type;
        private Checksum _checksum;
        private int _width;
        private int _height;
        private int _rowstride;
        private Gdk.Pixbuf _pixbuf_preview; // scaled pixbuf for preview
        
        /**
         * path where pixbuf image has been stored on disc
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
            
            // temporarily load pix buf so needed information can be extracted
            Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(data);
            extract_pixbuf_info(pixbuf);
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
            _path = save_pixbuf(pixbuf);
            extract_pixbuf_info(pixbuf);
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
            return "[%dx%d]".printf(_width, _height); 
        }
        
        /**
	     * {@inheritDoc}
	     */
        public Gtk.Image? get_image()
        {
            return new Gtk.Image.from_pixbuf(_pixbuf_preview);
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void to_clipboard(Gtk.Clipboard clipboard)
        {
            try {
                 Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(_path);
                 clipboard.set_image(pixbuf);
                 clipboard.store();
            } 
            catch(Error e) {
                error("Loading of image %s failed. Cause: %s", _path, e.message);
            }
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
                
                // check dimensions
                if(_width == image_item->_width && _height == image_item->_height
                  && _rowstride == image_item->_rowstride) {
                  
                  // TODO: do some checksum checking
                  equals = true;
                  // check if previews are eqaul
                  //equals = Utility.compare_pixbufs(_pixbuf, image_item->_pixbuf);
                  
                  // if there are equals there is no way around to
                  // to compare the image files itself
                  //if(equals) {
                    //
                  //}  
                  
                }
                // before pixbufs are loaded to memory
                // check if it is possible that such are 
                
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
        
            result = prime * result + _width;
            result = prime * result + _height;
            result = prime * result + _rowstride;
            
            return result;
        }
        
        /**
         * Extracts all pixbuf information which are needed to show image
         * in the view without having the pixbuf in the memory.
         */
        private void extract_pixbuf_info(Gdk.Pixbuf pixbuf)
        {
            _pixbuf_preview = create_scaled_pixbuf(pixbuf);
            _height = pixbuf.get_height();
            _width = pixbuf.get_width();
            _rowstride = pixbuf.get_rowstride();
        }
        
        /**
         * Create a menu icon size scaled pix buf
         *
         * @param pixbuf scaled pixbuf
         */
        private static Gdk.Pixbuf create_scaled_pixbuf(Gdk.Pixbuf pixbuf)
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
            Gdk.Pixbuf scaled = pixbuf.scale_simple(width, height, Gdk.InterpType.BILINEAR);
            return scaled;
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

