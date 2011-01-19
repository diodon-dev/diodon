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
     * Memory clipboard storage implementation.
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class MemoryClipboardStorage : GLib.Object, IClipboardStorage
    {
        private Gee.ArrayList<ClipboardItem> items;
    
        /**
         * Default constructor
         */
        public MemoryClipboardStorage()
        {
            items = new Gee.ArrayList<ClipboardItem>((GLib.EqualFunc?)ClipboardItem.equal_func);
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void remove_item(ClipboardItem item)
        {
            items.remove(item);
        }
        
        /**
	     * {@inheritDoc}
	     */
        public Gee.ArrayList<ClipboardItem> get_items()
        {
            return items;
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void add_item(ClipboardItem item)
        {
            items.add(item);
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void clear()
        {
            items.clear();
        }
    }  
}
 
