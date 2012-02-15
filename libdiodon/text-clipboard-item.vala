/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010-2011 Diodon Team <diodon-team@lists.launchpad.net>
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
     * Represents a text clipboard item holding simple text.
     */
    public class TextClipboardItem : GLib.Object, IClipboardItem
    {
        private string _text;
        private ClipboardType _clipboard_type;
       
        /**
         * Default data constructor needed for reflection.
         * 
         * @param clipboard_type clipboard type item is coming from
         * @param data simple text
         */ 
        public TextClipboardItem(ClipboardType clipboard_type, string data)
        {
            _clipboard_type = clipboard_type;
            _text = data;
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
            return _text;
        }

        /**
	     * {@inheritDoc}
	     */
        public string get_label()
        {
            // label should not be longer than 50 letters
            string label = _text.replace("\n", " ");
            if (label.char_count() > 50) {
                long index_char = label.index_of_nth_char(50);
                label = label.substring(0, index_char) + "...";
            }
            
            return label;
        }

        /**
	     * {@inheritDoc}
	     */
        public string get_mime_type()
        {
            return "text/plain";
        }
        
        /**
	     * {@inheritDoc}
	     */
        public ClipboardCategory get_category()
        {
            return ClipboardCategory.TEXT;
        }
      
        /**
	     * {@inheritDoc}
	     */
        public Gtk.Image? get_image()
        {
            return null; // no image available for text content
        }

        /**
	     * {@inheritDoc}
	     */
        public Icon get_icon()
        {
            return ContentType.get_icon(get_mime_type());
        }
        
        /**
	     * {@inheritDoc}
	     */
        public string get_checksum()
        {
            return Checksum.compute_for_string(ChecksumType.MD5, _text);
        }
                        
        /**
	     * {@inheritDoc}
	     */
        public void to_clipboard(Gtk.Clipboard clipboard)
        {
            clipboard.set_text(_text, -1);
            clipboard.store();
        }
        
        /**
	     * {@inheritDoc}
	     */
	    public void remove()
        {
            // no cleaning up needed
        }
        
        /**
	     * {@inheritDoc}
	     */
        public bool matches(string search, ClipboardItemType type)
        {
            bool matches = false;
            
            if(type == ClipboardItemType.ALL
                || type == ClipboardItemType.TEXT) {
                
                // ignore case
                matches = _text.down().contains(search.down());
            }
            
            return matches;
        }
        
        /**
	     * {@inheritDoc}
	     */
	    public bool equals(IClipboardItem* item)
        {
            bool equals = false;
            
            if(item is TextClipboardItem) {
                equals = str_equal(_text, item->get_clipboard_data());
            }
            
            return equals;
        }
        
        /**
	     * {@inheritDoc}
	     */
	    public uint hash()
        {
            return str_hash(_text);
        }
    }  
}
