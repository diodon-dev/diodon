/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010-2013 Diodon Team <diodon-team@lists.launchpad.net>
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
     * The clipboard history encapsulates the clipboard state and persists this
     * state with the help of given zeitgeist clipboard storage.
     */
    class ClipboardHistory : GLib.Object
    {
        private ZeitgeistClipboardStorage storage;
        private Gee.HashMap<ClipboardType, IClipboardItem> current_items;
 
        public ClipboardHistory(ZeitgeistClipboardStorage storage)
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
         * Get item of given checksum
         * 
         * @param checksum checksum of item to retrieve
         * @return clipboard item of given checksum; otherwise null
         */         
        public async IClipboardItem? get_item_by_checksum(string checksum)
        {  
            return yield storage.get_item_by_checksum(checksum);
        }
        
        /**
         * Get clipboard items which match given search query
         *
         * @param search_query query to search items for
         * @return clipboard items matching given search query
         */
        public async Gee.List<IClipboardItem> get_items_by_search_query(string search_query)
        {
            return yield storage.get_items_by_search_query(search_query);
        }
        
        /**
         * Get most recent items limited by assigned num_items. List will filter
         * out any duplicates according to their checksum. Most recent item
         * will be on the top of the list.
         *
         * @param num_items number of recent items
         */
        public async Gee.List<IClipboardItem> get_recent_items(int num_items)
        {
            return yield storage.get_recent_items(num_items);
        }
        
        /**
         * clear items and resetting selected item 
         */
        public async void clear()
        {
            yield storage.clear();
            current_items.clear();
        }
        
        /**
         * add given item
         * 
         * @param item item to be added
         */
        public async void add_item(IClipboardItem item)
        {
            yield storage.add_item(item);
            current_items.set(item.get_clipboard_type(), item);
        }
        
        /**
         * Select clipboard item.
         * 
         * @param item item to be selected
         * @param use_clipboard whether item gets selected for clipboard
         * @param use_primary whether item gets selected for primary selection
         */         
        public async void select_item(IClipboardItem item, bool use_clipboard, bool use_primary)
        {  
            // selected item is always at the end of history, so we need to
            // add it again
            yield storage.add_item(item);
            
            // verify that current items are selected correctly
            if(use_clipboard) {
                current_items.set(ClipboardType.CLIPBOARD, item);
            }
            if(use_primary) {
                current_items.set(ClipboardType.PRIMARY, item);
            }
        }
        
        /**
         * Remove clipboard item from storage
         *
         * @param item item to be removed
         */
        public async void remove_item(IClipboardItem item)
        {
            yield storage.remove_item(item);
        }
    }  
}

