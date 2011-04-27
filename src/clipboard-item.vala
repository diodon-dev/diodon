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
     * Clipboard item interface to be implemented by various different
     * clipboard item types such as Text,File or Image.
     *
     * @author Oliver Sauder <os@esite.ch>
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
         * get group clipboard item is beloging to
         *
         * @return clipboard group
         */
        public abstract ClipboardGroup get_group();
        
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
         * A string representing all information to rebuild a clipboard
         * item again.
         *
         * @return data
         */
        public abstract string get_clipboard_data();
        
        /**
         * Select the current item in the given gtk clipboard
         *
         * @param clipboard gtk clipboard
         */
        public abstract void to_clipboard(Gtk.Clipboard clipboard);
        
        /**
         * Will be called when clipboard items gets removed from storage.
         * Can be used for cleaning up functionality.
         */
        public abstract void remove();
        
        /**
         * Check if given item is equal.
         *
         * @return true if equal; otherwise false.
         *
         * TODO: see todo equal_func
         */
        public abstract bool equals(IClipboardItem *item);
        
        /**
         * return hash code for implemented clipboard item
         *
         * @return hash code
         *
         * TODO: see todo hash_func
         */
        public abstract uint hash();
        
        /**
         * equal func helper comparing two clipboard items.
         *
         * TODO:
         * in future releases of libgee (currently in development version 0.7.0)
         * there will be a interface called hashable which should be implemented
         * instead of this inconvenient equal func method.
         * 
         * @param item_a item to be compared
         * @param item_b other item to be compared
         * 
         * @return true if equal; otherwise false.
         */
        public static bool equal_func(IClipboardItem* item_a, IClipboardItem* item_b)
        {
            return item_a->equals(item_b);
        }
        
        /**
         * hash func helper creating hash code for clipboard item.
         *
         * TODO:
         * in future releases of libgee (currently in development version 0.7.0)
         * there will be a interface called hashable which should be implemented
         * instead of this inconvenient hash func method.
         * 
         * @param item item to create hash from
         * 
         * @return generated hash code
         */
        public static uint hash_func (IClipboardItem* item)
        {
            return item->hash();
        }
    }    
}

