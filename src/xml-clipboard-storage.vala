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
     * Xml clipboard storage implementation using
     * libxml2 to store parse and write the xml file.
     * 
     * TODO: add libxml2 implementation
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class XmlClipboardStorage : GLib.Object, IClipboardStorage
    {
        private ArrayList<ClipboardItem> items;
    
        public XmlClipboardStorage()
        {
            entries = new ArrayList<ClipboardEntry>();
        }
        
        public void remove_item(ClipboardItem item)
        {
            entries.remove(item);
        }
        
        public ArrayList<ClipboardEntry> get_items()
        {
            return items;
        }
        
        public void add_item(ClipboardItem entry)
        {
            items.add(entry);
        }
    }  
}
 
