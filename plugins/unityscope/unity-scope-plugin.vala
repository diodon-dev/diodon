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
        
        public Object object { owned get; construct; }
        
        public UnityScopePlugin()
        {
            Object();
        }
        
        public void activate()
        {
            debug("activate unityscope plugin");
            
            // needs to be done async as ScopeDBusConnector.run otherwise
            // blocks this method to finish and successfully activate plugin
            setup_scope.begin();
        }

        public void deactivate()
        {
            debug("deactivate unityscope plugin");
            Unity.ScopeDBusConnector.quit();
        }

        public void update_state()
        {
        }
        
        private async void setup_scope()
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
            scope.set_search_async_func(search_async);
            scope.set_preview_func(preview);
            scope.category_set = cats;
            
            Unity.ScopeDBusConnector connector = new Unity.ScopeDBusConnector(scope);
            try {
                connector.export();
                Unity.ScopeDBusConnector.run();
                
                debug("Unity scope has been closed");
            } catch(Error error) {
                warning("Failed to export Unity ScopeDBusConnector': %s",
                    error.message);
            }
        }
        
        private void search_async(Unity.ScopeSearchBase search, Unity.ScopeSearchBaseCallback callback)
        {
           this.search.begin(search, () => { callback(search); });
        }
        
        private async void search(Unity.ScopeSearchBase search)
        {
            Gee.List<IClipboardItem> items = yield get_results(search.search_context.search_query);
            
            foreach(IClipboardItem item in items) {
                Unity.ScopeResult result = Unity.ScopeResult();
                string? origin = item.get_origin();
                
                result.uri = "clipboard://" + item.get_checksum();
                // TODO see comment ZeitgeistClipboardStorage.CLIPBOARD_URI but
                // here we actually need clipboard:// uri
                //result.uri = ZeitgeistClipboardStorage.CLIPBOARD_URI + item.get_checksum();
                result.title = item.get_label();
                result.icon_hint = item.get_icon().to_string();
                result.category = 0;
                result.result_type = Unity.ResultType.DEFAULT; 
                result.mimetype = item.get_mime_type();
                result.comment = item.get_text();
                result.dnd_uri = result.uri;
                
                result.metadata = new HashTable<string, Variant>(str_hash, str_equal);
                if(origin != null) {
                    result.metadata.insert("origin", new Variant.string(origin));
                }
                // TODO: add more metadata e.g. timestamp
                
                search.search_context.result_set.add_result(result);
            }
        }
        
        private async Gee.List<IClipboardItem> get_results(string search_query)
        {
            Controller controller = object as Controller;
            
            return yield controller.get_items_by_search_query(search_query);
        }
        
        private Unity.AbstractPreview? preview(Unity.ResultPreviewer previewer)
        {
            Unity.ScopeResult result = previewer.result;
        
            debug("Show preview for %s", result.title);
            
            Unity.Preview preview = new Unity.GenericPreview(result.title,
                result.comment, Icon.new_for_string(result.icon_hint));
            
            Unity.PreviewAction copy_action = new Unity.PreviewAction.with_uri(result.uri,
                _("Paste"), null);
            preview.add_action(copy_action);
            
            // add metadata if available
            if(result.metadata != null) {
                Variant? orign_variant = result.metadata.lookup("origin");
                if(orign_variant != null) {
                    Unity.InfoHint origin_info = new Unity.InfoHint.with_variant(
                        "origin", _("Origin"), null, orign_variant);
                    preview.add_info(origin_info);
                }
            }
            
            return preview;
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

