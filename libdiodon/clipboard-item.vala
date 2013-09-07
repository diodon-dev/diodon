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
     * Clipboard item interface to be implemented by various different
     * clipboard item types such as Text,File or Image.
     */
    public interface IClipboardItem : GLib.Object
    {
        /**
         * get clipboard type item is coming from
         *
         * @return type of clipboard
         */  
        public abstract ClipboardType get_clipboard_type();
        
        /**
         * label of clipboard item used to show in user interface
         *
         * @return label of item
         */  
        public abstract string get_label();
        
        /**
         * get mime type of given clipboard item
         *
         * @return mime type of item
         */
        public abstract string get_mime_type();
        
        /**
         * get clipboard category item belongs to
         *
         * @return clipboard category
         */
        public abstract ClipboardCategory get_category();
        
        /**
         * image to represent content of clipboard item
         *
         * @return image of item or null if not available
         */
        public abstract Gtk.Image? get_image();
        
        /**
         * icon to represent type of clipboard item
         *
         * @return icon of clipboard type
         */
        public abstract Icon get_icon();
        
        /**
         * Retrieves any additional data needed to reconstruct clipboard content
         */
        public abstract ByteArray? get_payload() throws GLib.Error;
        
        /**
         * A string representing clipboard item.
         *
         * @return data
         */
        public abstract string get_text();
        
        /**
         * Get unique checksum for clipboard content.
         */
        public abstract string get_checksum();
        
        /**
         * Select the current item in the given gtk clipboard
         *
         * @param clipboard gtk clipboard
         */
        public abstract void to_clipboard(Gtk.Clipboard clipboard);
        
        /**
         * Determine if given item matches search string and section
         *
         * @param search search string
         * @param type clipboard item type to filter by
         * @return true when match; otherwise false.
         */
        public abstract bool matches(string search, ClipboardItemType type);
    }    
}

