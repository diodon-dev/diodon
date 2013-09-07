/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2011-2013 Diodon Team <diodon-team@lists.launchpad.net>
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
     * An image clipboard item representing such in a preview image.
     */
    public class ImageClipboardItem : GLib.Object, Gee.Hashable<IClipboardItem>, IClipboardItem
    {
        private ClipboardType _clipboard_type;
        private string _checksum; // checksum to identify pic content
        private Gdk.Pixbuf _pixbuf;
        private string _label;
        
        /**
         * Create image clipboard item by a pixbuf.
         * 
         * @param clipboard_type clipboard type item is coming from
         * @param pixbuf image from clipboard
         */
        public ImageClipboardItem.with_image(ClipboardType clipboard_type, Gdk.Pixbuf pixbuf) throws GLib.Error
        {
            _clipboard_type = clipboard_type;
            extract_pixbuf_info(pixbuf);
        }
        
        /**
         * Create image clipboard item by given payload.
         * 
         * @param clipboard_type clipboard type item is coming from
         * @param pixbuf image from clipboard
         */
        public ImageClipboardItem.with_payload(ClipboardType clipboard_type, ByteArray payload) throws GLib.Error
        {
            _clipboard_type = clipboard_type;
            
            Gdk.PixbufLoader loader = new Gdk.PixbufLoader();
            loader.write(payload.data);
            loader.close();
            Gdk.Pixbuf pixbuf = loader.get_pixbuf();
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
	    public string get_text()
        {
            return _label; // label is representation of image
        }

        /**
	     * {@inheritDoc}
	     */
        public string get_label()
        {
            return _label;
        }
        
        /**
	     * {@inheritDoc}
	     */
        public string get_mime_type()
        {
            // images are always converted to png
            return "image/png";
        }
        
        /**
	     * {@inheritDoc}
	     */
        public Icon get_icon()
        {
            // TODO niy
            //FileIcon icon = new FileIcon(File.new_for_path(_path));
            //return icon;
            return ContentType.get_icon(get_mime_type());
        }
        
        /**
	     * {@inheritDoc}
	     */
        public ClipboardCategory get_category()
        {
            return ClipboardCategory.IMAGES;
        }
        
        /**
	     * {@inheritDoc}
	     */
        public Gtk.Image? get_image()
        {
            Gdk.Pixbuf pixbuf_preview = create_scaled_pixbuf(_pixbuf);
            return new Gtk.Image.from_pixbuf(pixbuf_preview);
        }
        
        /**
	     * {@inheritDoc}
	     */
        public ByteArray? get_payload() throws GLib.Error
        {
            uint8[] buffer;
            _pixbuf.save_to_buffer(out buffer, "png");
            return new ByteArray.take(buffer);
        }
        
        /**
         * {@inheritDoc}
         */
        public string get_checksum()
        {
            return _checksum;
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
        public bool matches(string search, ClipboardItemType type)
        {
            bool matches = false;
            
            if(type == ClipboardItemType.ALL
                || type == ClipboardItemType.IMAGES) {
                // we do not have any search to be matched
                // therefore only an empty search string matches
                matches = search.length == 0; 
            }
            
            return matches;
        }
        
        /**
	     * {@inheritDoc}
	     */
	    public bool equal_to(IClipboardItem item)
        {
            bool equals = false;
            
            if(item is ImageClipboardItem) {
                ImageClipboardItem image_item = (ImageClipboardItem)item;
                equals = str_equal(_checksum, image_item._checksum);
            }
            
            return equals;
        }
        
        /**
	     * {@inheritDoc}
	     */
	    public uint hash()
        {
            // use checksum to create hash code
            return str_hash(_checksum);
        }
        
        /**
         * Extracts all pixbuf information which are needed to show image
         * in the view without having the pixbuf in the memory.
         *
         * @param pixbuf pixbuf to extract info from
         */
        private void extract_pixbuf_info(Gdk.Pixbuf pixbuf)
        {
            // create checksum of picture
            Checksum checksum = new Checksum(ChecksumType.SHA1);
            checksum.update(pixbuf.get_pixels(), pixbuf.height * pixbuf.rowstride);
            _checksum = checksum.get_string().dup();
            
            // label in format [{width}x{height}]
            _label ="[%dx%d]".printf(pixbuf.width, pixbuf.height); 
            _pixbuf = pixbuf;
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
    }  
}

