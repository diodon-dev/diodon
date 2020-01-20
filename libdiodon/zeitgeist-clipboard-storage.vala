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
	[DBus (name = "org.gnome.zeitgeist.Blacklist")]
	interface BlacklistInterface : Object {
        public signal void template_added (string blacklist_id, [DBus (signature = "(asaasay)")] Variant blacklist_template);

        public signal void template_removed (string blacklist_id, [DBus (signature = "(asaasay)")] Variant blacklist_template);

        [DBus (signature = "a{s(asaasay)}")]
        public abstract Variant get_templates () throws Error;
	}


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
        private BlacklistInterface blacklist;

        private HashTable<ClipboardType, IClipboardItem> current_items;
        private HashTable<int?, Event> cat_templates;

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
            this.cat_templates = new HashTable<int?, Event>(int_hash, int_equal);
            prepare_category_templates(this.cat_templates);

            try {
                this.blacklist = Bus.get_proxy_sync(
                    BusType.SESSION, "org.gnome.zeitgeist.Engine",
                    "/org/gnome/zeitgeist/blacklist"
                );
                this.blacklist.template_added.connect((id, variant) => { on_items_inserted(); } );
                this.blacklist.template_removed.connect((id, variant) => { on_items_deleted(); } );
            } catch(GLib.Error e) {
                warning("Could not connect to blacklist interface: %s", e.message);
            }

            this.monitor = new Monitor(new TimeRange.from_now(),
                get_items_event_templates());
            this.monitor.events_inserted.connect(() => { on_items_inserted(); } );
            this.monitor.events_deleted.connect(() => { on_items_deleted(); } );

            this.log = Zeitgeist.Log.get_default();

            try {
                this.log.install_monitor(monitor);
            } catch(GLib.Error e) {
                error("Could not install monitor: %s", e.message);
            }

            this.index = new Index();

            this.current_items = new HashTable<ClipboardType, IClipboardItem>(null, null);
        }

        /**
         * Check whether privacy mode is enabled or not. When privacy
         * mode is enabled no new clipboard items will be added to history.
         *
         * @return true if privacy mode is enabled; otherwise false.
         */
        public bool is_privacy_mode_enabled()
        {
            if(this.blacklist == null) {
                return false;
            }

            try {
                Variant var_blacklists = this.blacklist.get_templates();

                foreach(Variant variant in var_blacklists) {
                    VariantIter iter = variant.iterator();
                    string template_id = iter.next_value().get_string();
                    if(template_id == "block-all" || template_id == "interpretation-document") {
                        debug("Zeitgeist privacy mode is enabled");
                        return true;
                    }
                }
            } catch(GLib.Error e) {
                warning("Could not determine state of privacy mode: %s", e.message);
            }

            debug("Zeitgeist privacy mode is disabled");
            return false;
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
        public async void remove_item(IClipboardItem item, Cancellable? cancellable = null)
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
                    cancellable);

                Array<uint32> events = new Array<uint32>();
                events.append_vals(ids, ids.length);
                yield log.delete_events(events, cancellable);
            } catch (IOError.CANCELLED ioe) {
                debug("Remove item %s got cancelled, error: %s",
                    item.get_checksum(), ioe.message);
            } catch(GLib.Error e) {
                warning("Remove item %s not successful, error: %s",
                    item.get_checksum(), e.message);
            }
        }

        /**
         * Get clipboard item by its given checksum
         *
         * @param checksum checksum of clipboard item
         * @return clipboard item of given checksum; otherwise null if not available
         */
        public async IClipboardItem? get_item_by_checksum(string checksum, Cancellable? cancellable = null)
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
                    cancellable
                );

                foreach(Event event in events) {
                    if (event.num_subjects() > 0) {
                        Subject subject = event.get_subject(0);
                        item = create_clipboard_item(event, subject);
                        break;
                    }
                }
            } catch (IOError.CANCELLED ioe) {
                debug("Get item by checksum '%s' got cancelled, error: %s",
                    checksum, ioe.message);
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
         * @param cats categories for search query or null for all
         * @param date_copied filter results by given timerange; all per default
         * @param cancellable optional cancellable handler
         * @return clipboard items matching given search query
         */
        public async List<IClipboardItem> get_items_by_search_query(string search_query, ClipboardCategory[]? cats = null,
            ClipboardTimerange date_copied = ClipboardTimerange.ALL, Cancellable? cancellable = null)
        {
            TimeRange time_range = create_timerange(date_copied);
            GenericArray<Event> templates = get_items_event_templates(cats);

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
                        cancellable);

                    return create_clipboard_items(events);
                } catch (IOError.CANCELLED ioe) {
                    debug("Get items with search query '%s' got cancelled, error: %s",
                        search_query, ioe.message);
                } catch(GLib.Error e) {
                    warning("Get items by search query '%s' not successful, error: %s",
                        search_query, e.message);
                }
            // when there is no search query show last 100 items
            } else {
                return yield get_recent_items(100, cats, date_copied, cancellable);
            }

            return new List<IClipboardItem>();
        }

        /**
         * Get most recent items limited by assigned num_items. List will filter
         * out any duplicates according to their checksum resp. uri in zeitgeist.
         * Most recent item will be on the top.
         *
         * @param num_items number of recent items
         * @param cats categories of recent items to get; null for all
         * @param date_copied filter results by given timerange; all per default
         * @param cancellable optional cancellable handler
         * @return list of recent clipboard items
         */
        public async List<IClipboardItem> get_recent_items(uint32 num_items, ClipboardCategory[]? cats = null,
            ClipboardTimerange date_copied = ClipboardTimerange.ALL, Cancellable? cancellable = null)
        {
            debug("Get recent %u items", num_items);

            TimeRange time_range = create_timerange(date_copied);
            GenericArray<Event> templates = get_items_event_templates(cats);

            try {
	            ResultSet events = yield log.find_events(
	                time_range,
	                templates,
                    StorageState.ANY,
                    num_items,
                    // this will filter duplicates according to their uri
                    ResultType.MOST_RECENT_SUBJECTS,
                    cancellable
                );

                return create_clipboard_items(events);
            } catch (IOError.CANCELLED ioe) {
                    debug("Get recent items got cancelled, error: %s", ioe.message);
            } catch(GLib.Error e) {
                warning("Get recent items not successful, error: %s",
                    e.message);
            }

            return new List<IClipboardItem>();
        }

        /**
         * Add clipboard item as Zeitgeist event and subject to zeitgeist log.
         */
        public async void add_item(IClipboardItem item, Cancellable? cancellable = null)
        {
            debug("Add item to clipboard (Label: %s Checksum: %s)",
                item.get_label(), item.get_checksum()
            );

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

                yield log.insert_events(events, cancellable);
            } catch (IOError.CANCELLED ioe) {
                debug("Add item got cancelled, error: %s", ioe.message);
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
        public async void select_item(IClipboardItem item, bool use_clipboard, bool use_primary, Cancellable? cancellable = null)
        {
            // selected item is always at the end of history, so we need to
            // add it again
            yield add_item(item, cancellable);

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
        public async void clear(Cancellable? cancellable = null)
        {
            debug("Clear clipboard history");

            GenericArray<Event> templates = get_items_event_templates();
	        TimeRange time_range = new TimeRange.anytime();

            try {
	            uint32[] ids = yield log.find_event_ids(
	                time_range,
	                templates,
                    StorageState.ANY,
                    uint32.MAX,
                    ResultType.MOST_RECENT_EVENTS,
                    cancellable
                );

                Array<uint32> events = new Array<uint32>();
                events.append_vals(ids, ids.length);
                yield log.delete_events(events, cancellable);

            } catch (IOError.CANCELLED ioe) {
                debug("Clear items got cancelled, error: %s", ioe.message);
            } catch(GLib.Error e) {
                warning("Failed to clear items: %s", e.message);
            }

            current_items.remove_all();
        }

        private static void prepare_category_templates(HashTable<int?, Event> templates)
        {
            // match all
            templates[ClipboardCategory.CLIPBOARD] = new Event.full(
                                            ZG.CREATE_EVENT, ZG.USER_ACTIVITY,
                                            null,
                                            // origin events only added by diodon
                                            "application://diodon.desktop",
                                            new Subject.full(
                                                            CLIPBOARD_URI + "*",
                                                            null,
                                                            NFO.DATA_CONTAINER,
                                                            null,
                                                            null,
                                                            null,
                                                            null));

            templates[ClipboardCategory.TEXT] = new Event.full(
                                            ZG.CREATE_EVENT, ZG.USER_ACTIVITY,
                                            null,
                                            // origin events only added by diodon
                                            "application://diodon.desktop",
                                            new Subject.full(
                                                            CLIPBOARD_URI + "*",
                                                            NFO.PLAIN_TEXT_DOCUMENT,
                                                            NFO.DATA_CONTAINER,
                                                            null,
                                                            null,
                                                            null,
                                                            null));

            templates[ClipboardCategory.FILES] = new Event.full(
                                            ZG.CREATE_EVENT, ZG.USER_ACTIVITY,
                                            null,
                                            // origin events only added by diodon
                                            "application://diodon.desktop",
                                            new Subject.full(
                                                            CLIPBOARD_URI + "*",
                                                            NFO.FILE_DATA_OBJECT,
                                                            NFO.DATA_CONTAINER,
                                                            null,
                                                            null,
                                                            null,
                                                            null));

            templates[ClipboardCategory.IMAGES] = new Event.full(
                                            ZG.CREATE_EVENT, ZG.USER_ACTIVITY,
                                            null,
                                            // origin events only added by diodon
                                            "application://diodon.desktop",
                                            new Subject.full(
                                                            CLIPBOARD_URI + "*",
                                                            NFO.IMAGE,
                                                            NFO.DATA_CONTAINER,
                                                            null,
                                                            null,
                                                            null,
                                                            null));
        }

        private static TimeRange create_timerange(ClipboardTimerange timerange)
        {
            switch(timerange)
            {
                case ClipboardTimerange.LAST_24_HOURS:
                    return new TimeRange(Timestamp.from_now() - Timestamp.HOUR * 24, Timestamp.from_now());
                case ClipboardTimerange.LAST_7_DAYS:
                    return new TimeRange (Timestamp.from_now() - Timestamp.WEEK, Timestamp.from_now());
                case ClipboardTimerange.LAST_30_DAYS:
                    return new TimeRange (Timestamp.from_now() - (Timestamp.WEEK * 4), Timestamp.from_now());
                case ClipboardTimerange.LAST_YEAR:
                    return new TimeRange (Timestamp.from_now() - Timestamp.YEAR, Timestamp.from_now ());
                default:
                    return new TimeRange.anytime();
            }
        }

        private static IClipboardItem? create_clipboard_item(Event event, Subject subject)
        {
            string interpretation = subject.interpretation;
            IClipboardItem item = null;
            string text = subject.text;
            string? origin = subject.origin;
            unowned ByteArray payload = event.payload;
            DateTime date_copied = new DateTime.from_timeval_utc(Zeitgeist.Timestamp.to_timeval(event.timestamp));

            try {
                if(strcmp(NFO.PLAIN_TEXT_DOCUMENT, interpretation) == 0) {
                   item = new TextClipboardItem(ClipboardType.NONE, text, origin, date_copied);
                }

                else if(strcmp(NFO.FILE_DATA_OBJECT, interpretation) == 0) {
                    item = new FileClipboardItem(ClipboardType.NONE, text, origin, date_copied);
                }

                else if(strcmp(NFO.IMAGE, interpretation) == 0) {
                    item = new ImageClipboardItem.with_payload(ClipboardType.NONE, payload, origin, date_copied);
                }

                else {
                    warning("Unknown subject with interpretation: %s", interpretation);
                }
            } catch(GLib.FileError e) {
                // file errors happen constantly when e.g. some moved/deleted a file which has been
                // copied in the past. Therefore we just note this as debug.
                debug("Could not create FileClipboardItem: %s", e.message);
            } catch (Error e) {
                warning ("loading of item of interpreation %s with data %s failed. Cause: %s",
                    interpretation, text, e.message);
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

        private static List<IClipboardItem> create_clipboard_items(ResultSet events)
        {
            List<IClipboardItem> items = new List<IClipboardItem>();

            foreach(Event event in events) {
                if (event.num_subjects() > 0) {
                    Subject subject = event.get_subject(0);
                    IClipboardItem item = create_clipboard_item(event, subject);
                    if(item != null) {
                        items.append(item);
                    }
                } else {
                  warning ("Unexpected event without subject");
                  continue;
                }
            }

            debug("Created %d clipboard items", (int) items.length());

            return items;
        }

        /**
         * Get array of event templates which matches clipboard items with
         * given categories.
         *
         * @param cats list of clipboard item cats or null if all
         */
        private GenericArray<Event> get_items_event_templates(ClipboardCategory[]? cats = null)
        {
            GenericArray<Event> templates = new GenericArray<Event>();

            if(cats == null || cats.length == 0) {
                templates.add(cat_templates[ClipboardCategory.CLIPBOARD]);
            } else {
                foreach(unowned ClipboardCategory cat in cats) {
                    templates.add(cat_templates[cat]);
                }
            }

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

