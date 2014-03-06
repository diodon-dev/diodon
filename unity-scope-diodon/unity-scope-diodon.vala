/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2014 Diodon Team <diodon-team@lists.launchpad.net>
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
 
namespace Diodon
{
    private static ZeitgeistClipboardStorage storage;
    const string GROUP_NAME = Config.BUSNAME + ".Unity.Scope.Clipboard";
    const string UNIQUE_NAME = Config.BUSOBJECTPATH + "/unity/scope/clipboard";
    const string ICON_PATH = "/usr/share/icons/unity-icon-theme/places/svg/";
    
    private const string[] ALL_TYPES =
    {
      "text",
      "files",
      "images",
    };
    
    /**
     * This is the main function providing access to clipboard history through
     * a unity scope; the scope is defined and exported, a DBUS connector is
     * created and the main loop is run
     */
    public static int main(string[] args)
    {
        debug("Start Unity Scope");
        
        storage = new ZeitgeistClipboardStorage();
        
        // Create and setup the scope
        Unity.SimpleScope scope = new Unity.SimpleScope();
        scope.group_name = GROUP_NAME;
        scope.unique_name = UNIQUE_NAME;
        scope.set_search_async_func(search_async);
        scope.search_hint = _("Search Clipboard");
        scope.set_preview_func(preview);
        scope.category_set = populate_categories();
        scope.filter_set = populate_filters();
        
        Unity.ScopeDBusConnector connector = new Unity.ScopeDBusConnector(scope);
        try {
            connector.export();
            Unity.ScopeDBusConnector.run();
            
            debug("Unity scope has been closed");
        } catch(Error error) {
            warning("Failed to export Unity ScopeDBusConnector': %s",
                error.message);
            return 1;
        }
        
        return 0;
    }
    
    private static Unity.CategorySet populate_categories()
    {
        File icon_dir = File.new_for_path (ICON_PATH);
        Icon catIcon = new ThemedIcon("diodon-panel");
        Unity.CategorySet cats = new Unity.CategorySet();
        
        Unity.Category clipboard = new Unity.Category("global", _("Clipboard"),
            catIcon, Unity.CategoryRenderer.HORIZONTAL_TILE);
        cats.add(clipboard);
        
        Unity.Category recent = new Unity.Category("recent", _("Recent"),
             new FileIcon(icon_dir.get_child("group-recent.svg")),
             Unity.CategoryRenderer.HORIZONTAL_TILE);
        cats.add(recent);
        
        Unity.Category text = new Unity.Category("text", _("Text"),
             new FileIcon(icon_dir.get_child("group-notes.svg")),
             Unity.CategoryRenderer.HORIZONTAL_TILE);
        cats.add(text);
        
        Unity.Category files = new Unity.Category("files", _("Files"),
             new FileIcon(icon_dir.get_child("group-files.svg")),
             Unity.CategoryRenderer.HORIZONTAL_TILE);
        cats.add(files);
        
        Unity.Category images = new Unity.Category("images", _("Images"),
             new FileIcon(icon_dir.get_child("group-photos.svg")),
             Unity.CategoryRenderer.HORIZONTAL_TILE);
        cats.add(images);
        
        return cats;
    }
    
    private static Unity.FilterSet populate_filters()
    {
        Unity.FilterSet filters = new Unity.FilterSet();
        
        Unity.CheckOptionFilter type = new Unity.CheckOptionFilter("type", _("Type"));
        type.sort_type = Unity.OptionsFilter.SortType.DISPLAY_NAME;
        
        type.add_option("text", _("Text"));
        type.add_option("files", _("Files"));
        type.add_option("images", _("Images"));
        
        filters.add(type);
        
        return filters;
    }
    
    private static void search_async(Unity.ScopeSearchBase search, Unity.ScopeSearchBaseCallback callback)
    {
       Diodon.search.begin(search, () => { callback(search); });
    }
    
    private static async void search(Unity.ScopeSearchBase search)
    {
        string[]? types = get_current_types(search.search_context.filter_state);
        Gee.List<IClipboardItem> items = yield storage.get_items_by_search_query(
            search.search_context.search_query, types);
        
        foreach(IClipboardItem item in items) {
            Unity.ScopeResult result = Unity.ScopeResult();
            string? origin = item.get_origin();
            
            result.uri = "clipboard:" + item.get_checksum();
            // TODO see comment ZeitgeistClipboardStorage.CLIPBOARD_URI but
            // here we actually need clipboard:// uri
            //result.uri = ZeitgeistClipboardStorage.CLIPBOARD_URI + item.get_checksum();
            result.title = item.get_label();
            result.icon_hint = item.get_icon().to_string();
            result.category = item.get_category();
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
    
    /**
     * Get currently set type filters. Return null if none or all are set.
     */
    private static string[]? get_current_types(Unity.FilterSet filter_state)
    {
        /* returns null if the filter is disabled / all options selected */
        Unity.CheckOptionFilter filter = filter_state.get_filter_by_id("type") as Unity.CheckOptionFilter;
        
        if (filter == null || !filter.filtering) return null;
      
        string[] types = {};

        foreach (unowned string type_id in ALL_TYPES)
        {
            var option = filter.get_option(type_id);
            if (option == null || !option.active) continue;

            types += type_id; 
        }

        if (types.length == ALL_TYPES.length) return null;

        return types;
    }
    
    private static Unity.AbstractPreview? preview(Unity.ResultPreviewer previewer)
    {
        Unity.ScopeResult result = previewer.result;
    
        Icon hint_icon = null;
        try {
            hint_icon = Icon.new_for_string(result.icon_hint);
        } catch(Error error) {
            warning("Could not convert icon_hint to an icon': %s",
                error.message);
            hint_icon = ContentType.get_icon("text/plain");
        }
            
        debug("Show preview for %s", result.title);
        Unity.Preview preview = new Unity.GenericPreview(result.title,
            result.comment, hint_icon);
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
