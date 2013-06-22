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
        
        /**
         * Get most recent items limited by assigned num_items. List will filter
         * out any duplicates according to their checksum resp. uri in zeitgeist.
         *
         * @param num_items number of recent items
         */
        public async Gee.List<IClipboardItem> get_recent_items(int num_items)
        {
            Gee.List<IClipboardItem> items = new Gee.ArrayList<IClipboardItem>();
            PtrArray templates = new PtrArray.sized(1);
	        TimeRange time_range = new TimeRange.anytime();
            Event ev = new Zeitgeist.Event.full (ZG_CREATE_EVENT, ZG_USER_ACTIVITY, "",
                             new Subject.full ("clipboard*",
                                               NFO_PLAIN_TEXT_DOCUMENT,
                                               NFO_DATA_CONTAINER,
                                               "",
                                               "",
                                               "",
                                               ""));
            templates.add ((ev as GLib.Object).ref());
            
            try {
	            Zeitgeist.ResultSet events = yield log.find_events(
	                time_range,
	                (owned)templates, 
                    StorageState.ANY,
                    num_items,
                    // this will filter duplicates according to their uri
                    ResultType.MOST_RECENT_SUBJECTS,
                    null
                );
                
                // convert events to clipoard item
                foreach(Event event in events) {
                    if (event.num_subjects() > 0) {
                        Subject subject = event.get_subject(0);
                        IClipboardItem item = create_clipboard_item(subject);
                        if(item != null) {
                            items.add(item);
                        }
                    } else {
                      warning ("Unexpected event without subject");
                      continue;
                    }
                }
                
            } catch(GLib.Error e) {
                warning("Get recent items not successful, error: %s",
                    e.message);
            }
            
            return items;
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
        
        private IClipboardItem? create_clipboard_item(Subject subject)
        {
            string interpreation = subject.get_interpretation();
            IClipboardItem item = null;
            string text = subject.get_text();
            
            try {
                if(strcmp(NFO_PLAIN_TEXT_DOCUMENT, interpreation) == 0) {
                   item = new TextClipboardItem(ClipboardType.NONE, text); 
                }
                
                else if(strcmp(NFO_FILE_DATA_OBJECT, interpreation) == 0) {
                    item = new FileClipboardItem(ClipboardType.NONE, text);
                } 
                    
                else if(strcmp(NFO_IMAGE, interpreation) == 0) {
                    // TODO: implement image item
                }
            } catch (Error e) {
                warning ("loading of item of interpreation %s with data %s failed. Cause: %s",
                    interpreation, text, e.message);
            } 
            
            return item;
        }
        
        private string get_interpretation(IClipboardItem item)
        {
            string interpretation = NFO_PLAIN_TEXT_DOCUMENT;
            if(item is FileClipboardItem) {
                interpretation = NFO_FILE_DATA_OBJECT;
            }
            else if (item is ImageClipboardItem) {
                interpretation = NFO_IMAGE;
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

