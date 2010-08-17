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
        private ClipboardItem selected_item;
 
        public ClipboardModel(IClipboardStorage storage)
        {
            this.storage = storage;      
        }
        
        /**
         * Get currently selected item.
         * 
         * @return clipboard item
         */
        public ClipboardItem get_selected_item()
        {
            return selected_item;
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
        public void clear_items()
        {
            storage.remove_all_items();
            selected_item = null;
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
            // if there is a selected item, remove it first
            // before selecting a new one
            if(selected_item != null)
            {
                storage.remove_item(selected_item);
            }
            
            selected_item = item;
            storage.add_item(selected_item);
        }
    }  
}

