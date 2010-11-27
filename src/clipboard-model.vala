/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010 Diodon Team <diodon-team@lists.launchpad.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
 
using Gee;

namespace Diodon
{
    /**
     * The clipboard model encapsulates the clipboard state and persists this
     * state with the help of the given IClipboardStorage.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ClipboardModel
    {
        private IClipboardStorage storage;
        private Gee.HashMap<ClipboardType, ClipboardItem> current_items;
 
        public ClipboardModel(IClipboardStorage storage)
        {
            this.storage = storage;     
            this.current_items = new Gee.HashMap<ClipboardType, ClipboardItem>();
        }
        
        /**
         * Get currently selected item for given clipboard type
         * 
         * @param type clipboard type
         * @return clipboard item
         */
        public ClipboardItem get_current_item(ClipboardType type)
        {
            return current_items.get(type);
        }
        
        /**
         * Get all clipboard items
         * 
         * @return list of clipboard items
         */
        public ArrayList<ClipboardItem> get_items()
        {
            return storage.get_items();
        }
        
        /**
         * clear items and resetting selected item 
         */
        public void clear()
        {
            storage.clear();
            current_items.clear();
        }
        
        /**
         * add given item
         * 
         * @param item item to be added
         */
        public void add_item(ClipboardItem item)
        {
            storage.add_item(item);
        }
        
        /**
         * Select clipboard item.
         * 
         * @param item item to be selected
         */         
        public void select_item(ClipboardItem item)
        {  
            current_items.set(item.clipboard_type, item);
        }
        
        /**
         * Remove clipboard item from storage
         *
         * @param item item to be removed
         */
        public void remove_item(ClipboardItem item)
        {
            storage.remove_item(item);
        }
    }  
}

