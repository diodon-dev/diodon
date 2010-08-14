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
     * IClipboardStorage interface. Defining methods
     * to store clipboard data into a data container
     * such as xml or sql.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public interface IClipboardStorage
    {
        /**
         * Get all available clipboard items.
         * 
         * @return get all clipboard entries in right order
         */
        public abstract ArrayList<ClipboardItem> get_items();
        
        /**
         * Add given teim to storage
         * 
         * @param item item to be added
         */
        public abstract void add_item(ClipboardItem item);
        
        /**
         * remove given item from storage
         * 
         * @param item item to be removed
         */
        public abstract void remove_item(ClipboardItem item);
    }  
}
