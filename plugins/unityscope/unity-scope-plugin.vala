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

namespace Diodon.Plugins
{
    /**
     * Providing access to clipboard history through a unity scope
     */
    public class UnityScopePlugin : Peas.ExtensionBase, Peas.Activatable
    {
        const string GROUP_NAME = Config.BUSNAME + ".Unity.Scope.Clipboard";
        const string UNIQUE_NAME = Config.BUSOBJECTPATH + "/unity/scope/clipboard";
        const string CLIPBOARD_URI = "clipboard://";
        private uint dbus_id;
        
        public Object object { get; construct; }
        
        public UnityScopePlugin()
        {
            Object();
            dbus_id = 0;
        }
        
        public void activate()
        {
            debug("activate unityscope plugin");
            
            if(dbus_id == 0) {
                // Export the scope on the session bus - as everywhere else
                // these values should match those definedd in the .scope file 
                dbus_id = Bus.own_name(BusType.SESSION, GROUP_NAME,
                    BusNameOwnerFlags.NONE, on_bus_acquired, on_name_acquired, on_name_lost);
             }
        }

        public void deactivate()
        {
            debug("deactivate unityscope plugin");
        }

        public void update_state()
        {
        }
        
        /**
         * Called when bus has been acquired
         */
        private void on_bus_acquired(DBusConnection conn, string name)
        {
            // Create and set up clipboard category for the scope, including an icon
            Icon catIcon = new ThemedIcon("diodon-panel");
            Unity.Category cat = new Unity.Category("global", _("Clipboard"),
                catIcon, Unity.CategoryRenderer.HORIZONTAL_TILE);
            Unity.CategorySet cats = new Unity.CategorySet();
            cats.add(cat);
            
            // Create and setup the scope
            Unity.SimpleScope scope = new Unity.SimpleScope();
            scope.group_name = GROUP_NAME;
            scope.unique_name = UNIQUE_NAME;
            scope.set_search_func(search);
            scope.set_preview_func(preview);
            scope.category_set = cats;
            
            Unity.ScopeDBusConnector connector = new Unity.ScopeDBusConnector(scope);
            try {
                connector.export();
                Unity.ScopeDBusConnector.run();
            } catch(Error error) {
                warning("Failed to export Unity ScopeDBusConnector': %s",
                    error.message);
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
        
        private static void search(Unity.ScopeSearchBase search)
        {
            Gee.List<IClipboardItem> items = get_results(search.search_context.search_query);
            
            foreach(IClipboardItem item in items) {
                Unity.ScopeResult result = Unity.ScopeResult();
                
                result.uri = CLIPBOARD_URI + item.get_checksum();
                result.title = item.get_label();
                result.icon_hint = item.get_icon().to_string();
                result.category = 0;
                result.result_type = Unity.ResultType.DEFAULT; //?
                result.mimetype = item.get_mime_type();
                result.comment = item.get_text();
                result.dnd_uri = result.uri; //?
                // TODO: metadata
                
                search.search_context.result_set.add_result(result);
            }
        }
        
        private static Gee.List<IClipboardItem> get_results(string search_query)
        {
            // TODO: access zeitgeist
            Gee.List<IClipboardItem> items = new Gee.ArrayList<IClipboardItem>();
            items.add(new TextClipboardItem(ClipboardType.NONE, "test1"));
            items.add(new TextClipboardItem(ClipboardType.NONE, "test2"));
            
            return items;
        }
        
        private static Unity.AbstractPreview? preview(Unity.ResultPreviewer previewer)
        {
            return null;
        }
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
  Peas.ObjectModule objmodule = module as Peas.ObjectModule;
  objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (Diodon.Plugins.UnityScopePlugin));
}

