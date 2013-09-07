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
            this.index = new Index();
        }
        
        /**
         * Remove all events matching given clipboard item
         *
         * @param clipboard item to be removed
         */
        public async void remove_item(IClipboardItem item)
        {
            debug("Remove item with given checksum %s", item.get_checksum());
            
            try {
                GenericArray<Event> templates = create_item_event_templates(item);
                uint32[] ids = yield log.find_event_ids(
                    new TimeRange.anytime(),
                    templates,
                    StorageState.ANY,
                    uint32.MAX,
                    ResultType.MOST_RECENT_EVENTS, // all events
                    null);
                
                Array<uint32> events = new Array<uint32>();
                events.append_vals(ids, ids.length);
                
                yield log.delete_events(events, null);
            } catch(GLib.Error e) {
                warning("Remove item %s not successful, error: %s",
                    item.get_text(), e.message);
            }
        }
        
        /**
         * Get clipboard item by its given checksum
         *
         * @param checksum checksum of clipboard item
         * @return clipboard item of given checksum; othterwise null if not available
         */
        public async IClipboardItem? get_item_by_checksum(string checksum)
        {
            debug("Get item with given checksum %s", checksum);
            
            GenericArray<Event> templates = new GenericArray<Event>();
	        TimeRange time_range = new TimeRange.anytime();
            Event template = new Event.full(
                            ZG.CREATE_EVENT,
                            ZG.USER_ACTIVITY,
                            null,
                            null,
                            new Subject.full ("clipboard://" + checksum,
                                               null,
                                               NFO.DATA_CONTAINER,
                                               null,
                                               null,
                                               null,
                                               null));
            templates.add(template);
            
            IClipboardItem item = null;
            try {
	            ResultSet events = yield log.find_events(
	                time_range,
	                templates, 
                    StorageState.ANY,
                    1,
                    // this will filter duplicates according to their uri
                    ResultType.MOST_RECENT_SUBJECTS,
                    null
                );
                
                foreach(Event event in events) {
                    if (event.num_subjects() > 0) {
                        Subject subject = event.get_subject(0);
                        item = create_clipboard_item(event, subject);
                    }
                }
                
            } catch(GLib.Error e) {
                warning("Get item by checksum not successful, error: %s",
                    e.message);
            }
            
            if(item == null) {
                debug("Item with checksum %s could not be found", checksum);
            }
            
            return item;
        }
        
        /**
         * Get most recent items limited by assigned num_items. List will filter
         * out any duplicates according to their checksum resp. uri in zeitgeist.
         * Most recent item will be on the top.
         *
         * @param num_items number of recent items
         */
        public async Gee.List<IClipboardItem> get_recent_items(uint32 num_items)
        {
            debug("Get recent %u items", num_items);
            
            Gee.List<IClipboardItem> items = new Gee.ArrayList<IClipboardItem>();
            GenericArray<Event> templates = new GenericArray<Event>();
	        TimeRange time_range = new TimeRange.anytime();
            Event template = new Event.full (
                            ZG.CREATE_EVENT,
                            ZG.USER_ACTIVITY,
                            null,
                            null,
                            new Subject.full ("clipboard*",
                                               null,
                                               NFO.DATA_CONTAINER,
                                               null,
                                               null,
                                               null,
                                               null));
            templates.add (template);
            
            try {
	            ResultSet events = yield log.find_events(
	                time_range,
	                templates, 
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
                        IClipboardItem item = create_clipboard_item(event, subject);
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
            debug("Add item %s to clipboard", item.get_label());
            
            try {
                string interpretation = get_interpretation(item);
                string? origin = Utility.get_path_of_active_application();
                
                Subject subject = new Subject();
                subject.uri = "clipboard://" + item.get_checksum();
                subject.interpretation = interpretation;
                subject.manifestation = NFO.DATA_CONTAINER;
                subject.mimetype = item.get_mime_type();
                if(origin != null) {
                    subject.origin = origin;
                }
                subject.text = item.get_text();
                
                Event event = new Event();
                // TODO: this should actually be a copy event
                event.interpretation = ZG.CREATE_EVENT;
                event.manifestation = ZG.USER_ACTIVITY;
                event.actor = "application://diodon.desktop";
                event.add_subject(subject);
                
                ByteArray? payload = item.get_payload();
                if(payload != null) {
                    event.payload = payload;
                }
                
                TimeVal cur_time = TimeVal();
                int64 timestamp = Timestamp.from_timeval(cur_time);
                event.timestamp = timestamp;
                
                GenericArray<Event> events = new GenericArray<Event>();
                events.add(event);
                
                yield log.insert_events(events);
            } catch(GLib.Error e) {
                warning("Add item %s not successful, error: %s",
                    item.get_text(), e.message);
            }
        }
        
        /**
         * Clear all clipboard items in zeitgeist storage
         */
        public async void clear()
        {
            debug("Clear clipboard history");
            
            GenericArray<Event> templates = new GenericArray<Event>();
	        TimeRange time_range = new TimeRange.anytime();
            Event template = new Event.full (
                ZG.CREATE_EVENT,
                ZG.USER_ACTIVITY,
                null,
                null,
                new Subject.full (
                    "clipboard*",
                    null,
                    NFO.DATA_CONTAINER,
                    null,
                    null,
                    null,
                    null));
            templates.add(template);
            
            try {
	            uint32[] ids = yield log.find_event_ids(
	                time_range,
	                templates, 
                    StorageState.ANY,
                    uint32.MAX,
                    ResultType.MOST_RECENT_EVENTS,
                    null
                );
                
                Array<uint32> events = new Array<uint32>();
                events.append_vals(ids, ids.length);
                yield log.delete_events(events);
                
            } catch(GLib.Error e) {
                warning("Failed to clear items: %s", e.message);
            }
        }
        
        private IClipboardItem? create_clipboard_item(Event event, Subject subject)
        {
            string interpreation = subject.interpretation;
            IClipboardItem item = null;
            string text = subject.text;
            unowned ByteArray payload = event.payload;
            
            try {
                if(strcmp(NFO.PLAIN_TEXT_DOCUMENT, interpreation) == 0) {
                   item = new TextClipboardItem(ClipboardType.NONE, text); 
                }
                
                else if(strcmp(NFO.FILE_DATA_OBJECT, interpreation) == 0) {
                    item = new FileClipboardItem(ClipboardType.NONE, text);
                } 
                    
                else if(strcmp(NFO.IMAGE, interpreation) == 0) {
                    item = new ImageClipboardItem.with_payload(ClipboardType.NONE, payload);
                }
            } catch (Error e) {
                warning ("loading of item of interpreation %s with data %s failed. Cause: %s",
                    interpreation, text, e.message);
            } 
            
            return item;
        }
        
        private string get_interpretation(IClipboardItem item)
        {
            string interpretation = NFO.PLAIN_TEXT_DOCUMENT;
            if(item is FileClipboardItem) {
                interpretation = NFO.FILE_DATA_OBJECT;
            }
            else if (item is ImageClipboardItem) {
                interpretation = NFO.IMAGE;
            }
            
            return interpretation;
        }
        
        private GenericArray<Event> create_item_event_templates(IClipboardItem item)
        {
            GenericArray<Event> events = new GenericArray<Event>();
            
            Event event = new Event.full(
                ZG.CREATE_EVENT,
                ZG.USER_ACTIVITY,
                "application://diodon.desktop",
                null, // origin not necessary
                new Subject.full (
                    "clipboard://" + item.get_checksum(),
                    get_interpretation(item),
                    NFO.DATA_CONTAINER,
                    null,
                    null,
                    null,
                    null));
                    
            events.add(event);
            return events;
        }
    }  
}

