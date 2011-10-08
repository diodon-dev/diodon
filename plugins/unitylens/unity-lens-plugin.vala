/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2011 Diodon Team <diodon-team@lists.launchpad.net>
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

namespace Diodon.Plugins.UnityLens
{
    /**
     * TODO: needs to be replaced with a diodon specific path
     * Absolute path to custom unity icons.
     */
    const string UNITY_ICON_PATH = "/usr/share/icons/unity-icon-theme/places/svg/";
    
    /**
     * clipboard uri 
     */
    const string CLIPBOARD_URI = "clipboard://";

    /**
     * Providing access to clipboard history through a unity lens
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class UnityLensPlugin : Peas.ExtensionBase, Peas.Activatable
    {
        private uint dbus_id;
        private Unity.Lens lens;
        private Unity.Scope scope;
        
        public Object object { get; construct; }
        
        public UnityLensPlugin()
        {
            Object();
            dbus_id = 0;
        }
        
        public void activate()
        {
            debug("activate unitylens plugin");
            
            if(dbus_id == 0) {
                // Export the lens on the session bus - as everywhere else
                // these values should match those definedd in the .place file 
                dbus_id = Bus.own_name(BusType.SESSION, Config.BUSNAME + ".Unity.Lens.Diodon",
                    BusNameOwnerFlags.NONE, on_bus_acquired, on_name_acquired, on_name_lost);
             }
        }

        public void deactivate()
        {
            debug("deactivate unitylens plugin");
            if(dbus_id != 0) {
                Bus.unown_name(dbus_id);
                dbus_id = 0;
                lens = null;
            }
        }

        public void update_state ()
        {
        }
        
         /**
         * Called when bus has been acquired
         */
        private void on_bus_acquired (DBusConnection conn, string name)
        {
            debug("Connected to session bus - checking for existing instances...");
            
            /* We need to set up our DBus objects *before* we know if we've acquired
             * the name. This is a bit unfortunate because it means we might do work
             * for no reason if another daemon is already running. See
             * https://bugzilla.gnome.org/show_bug.cgi?id=640714 */
            scope = new Unity.Scope(Config.BUSOBJECTPATH + "/unity/scope/diodon");
            scope.search_in_global = false;
            scope.activate_uri.connect(activate_uri);
            
            lens = new Unity.Lens(Config.BUSOBJECTPATH + "/unity/lens/diodon", "diodon");
            lens.search_in_global = true;
            lens.search_hint = _("Search Clipboard");
            lens.visible = true;
            populate_categories();
            populate_filters();
            lens.add_local_scope(scope);
            
            // Listen for filter changes
            scope.filters_changed.connect(
                () => {          
                    if(scope.active_search != null)
                    {
                        scope.notify_property("active-search");
                    }
                }
            );
            
            // Listen for changes to the lens entry search
            scope.notify["active-search"].connect(
                (obj, pspec) => {
                    Unity.LensSearch search = scope.active_search;
                    update_search_async.begin(search);  
                }
            );
            
            // Listen for changes to the global search
            scope.notify["active-global-search"].connect(
                (obj, pspec) => {
                    Unity.LensSearch search = scope.active_search;
                    update_global_search_async.begin(search);  
                }
            );
            
            // Export the controller on the bus.
            // Unity can see us past this point
            try {
                lens.export();
            } catch(IOError error) {
                critical("Failed to export DBus service for '%s': %s",
                    lens.dbus_path, error.message);
            }
        }

        /**
         * Called when dbus connection name has been accired.
         */
        private void on_name_acquired(DBusConnection conn, string name)
        {
            debug("Acquired name %s. We're the main instance.\nAll system are go.",
                   name);
        }

        /**
         * Called when dbus connection has been lost
         */
        private void on_name_lost(DBusConnection conn, string name)
        {
            debug("Another daemon is running. Bailing out.");
        }
        
        private void populate_categories()
        {
            List<Unity.Category> categories = new List<Unity.Category>();
            File icon_dir = File.new_for_path(UNITY_ICON_PATH);
            
            Unity.Category cat = new Unity.Category(_("Text"),
                new FileIcon (icon_dir.get_child ("group-downloads.svg")));
            categories.append(cat);
            
            cat = new Unity.Category(_("Files"),
                new FileIcon (icon_dir.get_child ("open-folder.svg")));
            categories.append(cat);
        
            cat = new Unity.Category(_("Images"),
                new FileIcon (icon_dir.get_child ("group-mostused.svg")));
            categories.append(cat);
            
            lens.categories = categories;
        }
        
        private void populate_filters()
        {
            List<Unity.Filter> filters = new List<Unity.Filter>();
            
            /* Type filter */
            {
                Unity.RadioOptionFilter filter = new Unity.RadioOptionFilter(
                    "type", _("Type"));
                
                filter.add_option("text", _("Text"));
                filter.add_option("files", _("Files"));
                filter.add_option("images", _("Images"));
                
                filters.append(filter);
            }
            
            lens.filters = filters;
        }
        
        private async void update_search_async(Unity.LensSearch search)
        {
            Dee.SharedModel results_model = scope.results_model;
            
            // Prevent concurrent searches and concurrent updates of our models,
            // by preventing any notify signals from propagating to us.
            // Important: Remeber to thaw the notifys again!
            scope.freeze_notify();
            
            string search_string = search.search_string ?? "";
            ClipboardItemType item_type = get_current_type();
            
            update_results_model(results_model, search_string,
                item_type);
                
            // Allow new searches once we enter an idle again.
            // We don't do it directly from here as that could mean we start
            // changing the model even before we had flushed out current changes
            Idle.add (() => {
                scope.thaw_notify ();
                return false;
            });
            
            search.finished();
        }
        
        private async void update_global_search_async(Unity.LensSearch search)
        {
            Dee.SharedModel results_model = scope.global_results_model;
            
            // Prevent concurrent searches and concurrent updates of our models,
            // by preventing any notify signals from propagating to us.
            // Important: Remeber to thaw the notifys again!
            scope.freeze_notify();
            
            string search_string = search.search_string ?? "";
            
            update_results_model(results_model, search_string,
                ClipboardItemType.ALL);
                
            // Allow new searches once we enter an idle again.
            // We don't do it directly from here as that could mean we start
            // changing the model even before we had flushed out current changes
            Idle.add (() => {
                scope.thaw_notify ();
                return false;
            });
            
            search.finished();
        }
        
        /**
         * Get the current type to filter by
         * 
         * @return current type
         */
        private ClipboardItemType get_current_type()
        {
            Unity.RadioOptionFilter filter = scope.get_filter("type") as Unity.RadioOptionFilter;
            Unity.FilterOption? option = filter.get_active_option();
            string type_id = option == null ? "all" : option.id;
            return ClipboardItemType.from_string(type_id);
        }

        private void update_results_model(Dee.Model results_model, string search, ClipboardItemType type)
        {
            Controller controller = object as Controller;
            debug("Rebuilding results model");
            results_model.clear();
            
            Gee.List<IClipboardItem> items = controller.get_items();
            
            // add items in reverse order as last added items are
            // more important
            for(int i = items.size -1; i >=0; --i) {
                IClipboardItem item = items.get(i);
                if(item.matches(search, type)) {
                    results_model.append(
                        CLIPBOARD_URI + item.get_checksum(),
                        item.get_icon().to_string(),
                        item.get_category(),
                        item.get_mime_type(),
                        item.get_label(),
                        _("Copy to clipboard")
                    );
                }
            }
        }
        
        private Unity.ActivationResponse activate_uri(string uri)
        {
            Controller controller = object as Controller;
            debug("Requested activation of: %s", uri);
            
            // check if uri is a clipboard uri
            if(str_equal(uri.substring(0, CLIPBOARD_URI.length), CLIPBOARD_URI)) {
                string checksum = uri.substring(CLIPBOARD_URI.length);
                IClipboardItem item = controller.get_item_by_checksum(checksum);
                if(item != null) {
                    controller.select_item(item);
                    return new Unity.ActivationResponse(
                        Unity.HandledType.HIDE_DASH);
                }
            }
            
            warning("Could not activate uri %s", uri);
            return new Unity.ActivationResponse(Unity.HandledType.NOT_HANDLED);
        }
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
  Peas.ObjectModule objmodule = module as Peas.ObjectModule;
  objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (Diodon.Plugins.UnityLens.UnityLensPlugin));
}

