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
        
        public ZeitgeistClipboardStorage()
        {
            this.log = Zeitgeist.Log.get_default();
            this.index = new Zeitgeist.Index();
        }
        
        /**
         * Remove all events matching given clipboard item
         *
         * @param clipboard item to be removed
         */
        public async void remove_item(IClipboardItem item)
        {
            try {
                PtrArray templates = create_item_event_templates(item);
                Array event_ids = yield log.find_event_ids(
                    new TimeRange.anytime(),
                    (owned)templates, 
                    StorageState.ANY,
                    uint32.MAX,
                    ResultType.MOST_RECENT_EVENTS, // all events
                    null);
                
                yield log.delete_events((owned)event_ids, null);
            } catch(GLib.Error e) {
                warning("Remove item %s not successful, error: %s",
                    item.get_clipboard_data(), e.message);
            }
        }
        
        public Gee.List<IClipboardItem> get_recent_items()
        {
            return new Gee.ArrayList<IClipboardItem>();
        }
        
        /**
         * Add clipboard item as Zeitgeist event and subject to zeitgeist log.
         */
        public async void add_item(IClipboardItem item)
        {
            try {
                string interpretation = get_interpretation(item);
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
                
                yield log.insert_events(null, event);
            } catch(GLib.Error e) {
                warning("Add item %s not successful, error: %s",
                    item.get_clipboard_data(), e.message);
            }
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
        
        private PtrArray create_item_event_templates(IClipboardItem item)
        {
            PtrArray events = new PtrArray.sized(1);
            Event ev = new Zeitgeist.Event.full(
                ZG_CREATE_EVENT,
                ZG_USER_ACTIVITY,
                "application://diodon.desktop",
                new Subject.full (
                    "clipboard://" + item.get_checksum(),
                    get_interpretation(item),
                    NFO_DATA_CONTAINER,
                    "",
                    "",
                    "",
                    ""));
                    
            events.add ((ev as GLib.Object).ref());
            return events;
        }
    }  
}

