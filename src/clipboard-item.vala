/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010 Diodon Team <diodon-team@lists.launchpad.net>
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
     * Represents an immutable item in the clipboard with all its information.
     * 
     * TODO; consider using a interface for a clipboard item to implement
     * the representation of coping files or buffers.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ClipboardItem : GLib.Object
    {
        private string _text;
        private ClipboardType _clipboard_type;
       
        /**
         * Simple text constructor
         * 
         * @param type clipboard type item is coming from
         * @param text plain text
         */ 
        public ClipboardItem(ClipboardType clipboard_type, string text)
        {
            _clipboard_type = clipboard_type;
            _text = text;
        }
    
        /**
         * get plain text
         */
        public string text
        {
            get { return _text; }
        }

        /**
         * get clipboard type item is coming from
         */        
        public ClipboardType clipboard_type
        {
            get { return _clipboard_type; }
        }
        
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
        public static bool equal_func(ClipboardItem* item_a, ClipboardItem* item_b)
        {
            return str_equal(item_a->text, item_b->text);
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
        public static uint hash_func (ClipboardItem* item)
        {
            return str_hash(item->text);
        }
    }  
}
