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
     * The clipboard model encapsulates the clipboard state and persists this
     * state with the help of the given IClipboardStorage.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ClipboardModel
    {
        private IClipboardStorage storage;
        private Gee.HashMap<ClipboardType, IClipboardItem> current_items;
 
        /** 
         * Storage constructor
         *
         * @param storage
         */
        public ClipboardModel(IClipboardStorage storage)
        {
            this.storage = storage;     
            this.current_items = new Gee.HashMap<ClipboardType, IClipboardItem>();
        }
        
        /**
         * Get currently selected item for given clipboard type
         * 
         * @param type clipboard type
         * @return clipboard item
         */
        public IClipboardItem get_current_item(ClipboardType type)
        {
            return current_items.get(type);
        }
        
        /**
         * Get last respectively oldest available clipboard item
         *
         * @return last item or null if no item is available
         */
        public IClipboardItem get_last_item()
        {
            IClipboardItem item = null;
            
            if(get_size() > 0) {
                item = get_items().get(0);
            }
            
            return item;
        }
        
        /**
         * Get all clipboard items
         * 
         * @return list of clipboard items
         */
        public Gee.ArrayList<IClipboardItem> get_items()
        {
            return storage.get_items();
        }
        
        /**
         * Get number of items available
         *
         * @return number of items
         */
        public int get_size()
        {
            return get_items().size;
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
        public void add_item(IClipboardItem item)
        {
            storage.add_item(item);
        }
        
        /**
         * Select clipboard item.
         * 
         * @param item item to be selected
         */         
        public void select_item(IClipboardItem item)
        {  
            current_items.set(item.get_clipboard_type(), item);
        }
        
        /**
         * Remove clipboard item from storage
         *
         * @param item item to be removed
         */
        public void remove_item(IClipboardItem item)
        {
            storage.remove_item(item);
        }
    }  
}

