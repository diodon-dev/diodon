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
        // FIXME this should be clipboard:// however as such is currently filtered
        // by zeitgeist we have to set an accepted uri otherwise clipboard events
        // won't be indexed by fts
        // see https://bugs.freedesktop.org/show_bug.cgi?id=70173
        public const string CLIPBOARD_URI = "dav:";
        
        private Zeitgeist.Log log;
        private Index index;
        private Monitor monitor;
        
        private Gee.HashMap<ClipboardType, IClipboardItem> current_items;
        
        /**
         * Called when a item has been inserted.
         */
        public signal void on_items_inserted();
        
        /**
         * Called when a item has been deleted.
         */
        public signal void on_items_deleted();
        
        public ZeitgeistClipboardStorage()
        {
            this.monitor = new Monitor(new TimeRange.from_now(),
                create_all_items_event_templates());
            this.monitor.events_inserted.connect(() => { on_items_inserted(); } );   
            this.monitor.events_deleted.connect(() => { on_items_deleted(); } );
            
            this.log = Zeitgeist.Log.get_default();
            
            try {
                this.log.install_monitor(monitor);
            } catch(GLib.Error e) {
                error("Could not install monitor: %s", e.message);
            }
            
            this.index = new Index();
            
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
                            "application://diodon.desktop", // origin events only added by diodon
                            new Subject.full (CLIPBOARD_URI + checksum,
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
                        break;
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
         * Get clipboard items which match given search query
         *
         * @param search_query query to search items for
         * @return clipboard items matching given search query
         */
        public async Gee.List<IClipboardItem> get_items_by_search_query(string search_query)
        {
            
            TimeRange time_range = new TimeRange.anytime();
            GenericArray<Event> templates = create_all_items_event_templates();
            
            string query = prepare_search_string(search_query);
            if(query != "") {
                debug("Get items by search query %s", search_query);
                try {
                    ResultSet events = yield index.search(
                        query,
                        time_range,
                        templates,
                        0,
                        100, // setting limit to 100 for now, for memory reasons
                        // this will filter duplicates according to their uri
                        ResultType.MOST_RECENT_SUBJECTS,
                        null); 
                        
                    return create_clipboard_items(events);
                    
                } catch(GLib.Error e) {
                    warning("Get items by search query '%s' not successful, error: %s",
                        search_query, e.message);
                }
            }
            
            return new Gee.ArrayList<IClipboardItem>();;
        }
        
        /**
         * Get most recent items limited by assigned num_items. List will filter
         * out any duplicates according to their checksum resp. uri in zeitgeist.
         * Most recent item will be on the top.
         *
         * @param num_items number of recent items
         * @return list of recent clipboard items
         */
        public async Gee.List<IClipboardItem> get_recent_items(uint32 num_items)
        {
            debug("Get recent %u items", num_items);
            
            TimeRange time_range = new TimeRange.anytime();
            GenericArray<Event> templates = create_all_items_event_templates();
            
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
                
                return create_clipboard_items(events);
                
            } catch(GLib.Error e) {
                warning("Get recent items not successful, error: %s",
                    e.message);
            }
            
            return new Gee.ArrayList<IClipboardItem>();;
        }
        
        /**
         * Add clipboard item as Zeitgeist event and subject to zeitgeist log.
         */
        public async void add_item(IClipboardItem item)
        {
            debug("Add item %s to clipboard", item.get_label());
            
            try {
                string interpretation = get_interpretation(item);
                
                Subject subject = new Subject();
                subject.uri = CLIPBOARD_URI + item.get_checksum();
                subject.interpretation = interpretation;
                subject.manifestation = NFO.DATA_CONTAINER;
                subject.mimetype = item.get_mime_type();
                subject.origin = item.get_origin();
                subject.text = item.get_text();
                
                Event event = new Event();
                // TODO: this should actually be a copy event
                event.interpretation = ZG.CREATE_EVENT;
                event.manifestation = ZG.USER_ACTIVITY;
                // event origin is which clipboard manager event comes from
                event.origin = "application://diodon.desktop";
                
                // actor is application triggering copy event
                if(subject.origin != null) {
                    try {
                        AppInfo appInfo = AppInfo.create_from_commandline(subject.origin,
                            null, AppInfoCreateFlags.NONE);
                        event.set_actor_from_app_info(appInfo);
                    } catch(GLib.Error e) {
                        warning("Could not create AppInfo for %s: %s",
                            subject.origin, e.message);
                    }
                }
                // actor is mandantory, fallback to diodon
                if(event.actor == null) {
                    event.actor = "application://diodon.desktop";
                }
                debug("event actor set to %s", event.actor);
                
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
            yield add_item(item);
            
            // verify that current items are selected correctly
            if(use_clipboard) {
                current_items.set(ClipboardType.CLIPBOARD, item);
            }
            if(use_primary) {
                current_items.set(ClipboardType.PRIMARY, item);
            }
        }
        
        /**
         * Clear all clipboard items in zeitgeist storage
         */
        public async void clear()
        {
            debug("Clear clipboard history");
            
            GenericArray<Event> templates = create_all_items_event_templates();
	        TimeRange time_range = new TimeRange.anytime();
            
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
            
            current_items.clear();
        }
        
        private static IClipboardItem? create_clipboard_item(Event event, Subject subject)
        {
            string interpreation = subject.interpretation;
            IClipboardItem item = null;
            string text = subject.text;
            string? origin = subject.origin;
            unowned ByteArray payload = event.payload;
            
            try {
                if(strcmp(NFO.PLAIN_TEXT_DOCUMENT, interpreation) == 0) {
                   item = new TextClipboardItem(ClipboardType.NONE, text, origin); 
                }
                
                else if(strcmp(NFO.FILE_DATA_OBJECT, interpreation) == 0) {
                    item = new FileClipboardItem(ClipboardType.NONE, text, origin);
                }
                    
                else if(strcmp(NFO.IMAGE, interpreation) == 0) {
                    item = new ImageClipboardItem.with_payload(ClipboardType.NONE, payload, origin);
                }
            } catch(GLib.FileError e) {  
                // file errors happen constantly when e.g. some moved/deleted a file which has been
                // copied in the past. Therefore we just note this as debug.
                debug("Could not create FileClipboardItem: %s", e.message);  
            } catch (Error e) {
                warning ("loading of item of interpreation %s with data %s failed. Cause: %s",
                    interpreation, text, e.message);
            } 
            
            return item;
        }
        
        private static string get_interpretation(IClipboardItem item)
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
        
        private static Gee.List<IClipboardItem> create_clipboard_items(ResultSet events)
        {
            Gee.List<IClipboardItem> items = new Gee.ArrayList<IClipboardItem>();
            
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
            
            debug("Created %d clipboard items", items.size);
            
            return items;
        }
        
        /**
         * Create array of event templates which matches all clipboard items.
         */
        private static GenericArray<Event> create_all_items_event_templates()
        {
            GenericArray<Event> templates = new GenericArray<Event>();
            Event template = new Event.full (
                            ZG.CREATE_EVENT,
                            ZG.USER_ACTIVITY,
                            null,
                            "application://diodon.desktop", // origin events only added by diodon
                            new Subject.full (CLIPBOARD_URI + "*",
                                               null,
                                               NFO.DATA_CONTAINER,
                                               null,
                                               null,
                                               null,
                                               null));
            templates.add (template);
            
            return templates;
        }
        
        private static GenericArray<Event> create_item_event_templates(IClipboardItem item)
        {
            GenericArray<Event> events = new GenericArray<Event>();
            
            Event event = new Event.full(
                ZG.CREATE_EVENT,
                ZG.USER_ACTIVITY,
                null, // find copy events for all actors / applications
                "application://diodon.desktop", // origin events only added by diodon
                new Subject.full (
                    CLIPBOARD_URI + item.get_checksum(),
                    get_interpretation(item),
                    NFO.DATA_CONTAINER,
                    null,
                    null,
                    null,
                    null));
                    
            events.add(event);
            return events;
        }
        
        private static string prepare_search_string(string search_string)
        {
            string s = search_string.strip();

            // TODO: query can have several parts and this needs to be taken
            // into consideration
            if (!s.has_suffix ("*") && s != "") {
                s = s + "*";
            }

            return s;
        }
    }  
}

