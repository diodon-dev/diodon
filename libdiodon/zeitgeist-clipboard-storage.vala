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
    public class ZeitgeistClipboardStorage : GLib.Object
    {
        private Zeitgeist.Log log;
        private Index index;
        
        // basic clipboard zeitgeist templates used for filtering while searching
        private PtrArray templates;
        
        public ZeitgeistClipboardStorage()
        {
            this.templates = new PtrArray.sized(1);
            Event event = new Event.full(ZG_ACCESS_EVENT,
                ZG_USER_ACTIVITY, "", new Subject.full("clipboard*",
                    "", "", "", "", "", ""));
            this.templates.add((event as GLib.Object).ref());
      
            this.log = Zeitgeist.Log.get_default();
            this.index = new Zeitgeist.Index();
            //monitor = new Zeitgeist.Monitor (new Zeitgeist.TimeRange.from_now(),
            //    zg_templates);
        }
        
        public void remove_item(IClipboardItem item)
        {
        }
        
        public Gee.List<IClipboardItem> get_recent_items()
        {
            return new Gee.ArrayList<IClipboardItem>();
        }
        
        /**
         * Add clipboard item as Zeitgeist event and subject to zeitgeist log.
         */
        public void add_item(IClipboardItem item)
        {
            /*string interpretation = get_interpretation(item);
            string? origin = Utility.get_path_of_active_application();
            
            Zeitgeist.Subject subject = new Zeitgeist.Subject();
            subject.set_uri("clipboard://" + item.get_checksum());
            subject.set_interpretation(interpretation);
            subject.set_manifestation(Zeitgeist.NFO_DATA_CONTAINER);
            subject.set_mimetype(item.get_mime_type());
            if(origin != null) {
                subject.set_origin(origin);
            }
            subject.set_text(item.get_clipboard_data());
            
            Zeitgeist.Event event = new Zeitgeist.Event();
            // TODO: this should actually be a copy event
            event.set_interpretation(Zeitgeist.ZG_CREATE_EVENT);
            event.set_manifestation(Zeitgeist.ZG_USER_ACTIVITY);
            event.set_actor("application://diodon.desktop");
            event.add_subject(subject);
            
            // content should be added, however ignored as currently
            // data is not being read
            //event.set_payload();
            
            TimeVal cur_time = TimeVal();
            int64 timestamp = Zeitgeist.Timestamp.from_timeval(cur_time);
            event.set_timestamp(timestamp);
            
            log.insert_events_no_reply(event, null);*/
        }
        
        private string get_interpretation(IClipboardItem item)
        {
            string interpretation = Zeitgeist.NFO_PLAIN_TEXT_DOCUMENT;
            if(item is FileClipboardItem) {
                interpretation = Zeitgeist.NFO_FILE_DATA_OBJECT;
            }
            else if (item is ImageClipboardItem) {
                interpretation = Zeitgeist.NFO_IMAGE;
            }
            
            return interpretation;
        }
    }  
}

