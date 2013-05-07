/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2013 Diodon Team <diodon-team@lists.launchpad.net>
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
 
using Zeitgeist;

namespace Diodon
{
    /**
     * Zeitgeist clipboard storage implementation using
     * libzeitgeist to store clipboard items as events with subjects.
     */
    class ZeitgeistClipboardStorage : GLib.Object
    {
        private Zeitgeist.Log log;
        private Index zg_index;
        private Monitor monitor;
        
        // basic clipboard zeitgeist templates used for filtering while searching
        private PtrArray zg_templates;
        
        public ZeitgeistClipboardStorage()
        {
            zg_templates = new PtrArray.sized(1);
            Event event = new Event.full(ZG_ACCESS_EVENT,
                ZG_USER_ACTIVITY, "", new Subject.full("clipboard*",
                    "", "", "", "", "", ""));
                                               
            zg_templates.add((event as GLib.Object).ref());
      
            log = new Zeitgeist.Log();
            zg_index = new Zeitgeist.Index();
            monitor = new Zeitgeist.Monitor (new Zeitgeist.TimeRange.from_now(),
                zg_templates);
        }
        
        public void remove_item(IClipboardItem item)
        {
        }
        
        public Gee.List<IClipboardItem> get_recent_items()
        {
            return new Gee.ArrayList<IClipboardItem>();
        }
        
        public void add_item(IClipboardItem item)
        {
        }
    }  
}

