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
    const string GROUP_NAME ="net.launchpad.Diodon.Unity.Scope.Clipboard";
    const string UNIQUE_NAME = "/net/launchpad/diodon/unity/scope/clipboard";
    const string ICON_PATH = "/usr/share/icons/unity-icon-theme/places/svg/";

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

        // result needs to be invalidated whenever clipboard history changes
        storage.on_items_deleted.connect(() => { scope.results_invalidated(Unity.SearchType.DEFAULT); });
        storage.on_items_inserted.connect(() => { scope.results_invalidated(Unity.SearchType.DEFAULT); });

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

        Unity.CheckOptionFilter category = new Unity.CheckOptionFilter("category", _("Category"));
        category.sort_type = Unity.OptionsFilter.SortType.DISPLAY_NAME;

        category.add_option("text", _("Text"));
        category.add_option("files", _("Files"));
        category.add_option("images", _("Images"));

        filters.add(category);

        Unity.RadioOptionFilter date_copied = new Unity.RadioOptionFilter("date_copied", _("Date copied"));

        date_copied.add_option("last-24-hours", _("Last 24 hours"));
        date_copied.add_option("last-7-days", _("Last 7 days"));
        date_copied.add_option("last-30-days", _("Last 30 days"));
        date_copied.add_option("last-year", _("Last year"));

        filters.add(date_copied);

        return filters;
    }

    private static void search_async(Unity.ScopeSearchBase search, Unity.ScopeSearchBaseCallback callback)
    {
       Diodon.search.begin(search, () => { callback(search); });
    }

    private static async void search(Unity.ScopeSearchBase search)
    {
        Cancellable? cancellable = search.search_context.cancellable.get_gcancellable();
        ClipboardCategory[]? cats = get_filter_categories(search.search_context.filter_state);
        ClipboardTimerange date_copied = get_filter_datecopied(search.search_context.filter_state);
        List<IClipboardItem> items = yield storage.get_items_by_search_query(
            search.search_context.search_query, cats, date_copied, cancellable);

        if(!search.search_context.cancellable.is_cancelled()) {
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
                DateTime local_date_copied = item.get_date_copied().to_local();
                result.metadata.insert("date_copied", new Variant.string(local_date_copied.format("%Y-%m-%d %H:%M:%S")));

                search.search_context.result_set.add_result(result);
            }
        }
    }

    /**
     * Get currently set cateogry filters. Return null if none or all are set.
     */
    private static ClipboardCategory[]? get_filter_categories(Unity.FilterSet filter_state)
    {
        /* returns null if the filter is disabled / all options selected */
        Unity.CheckOptionFilter filter = filter_state.get_filter_by_id("category") as Unity.CheckOptionFilter;

        if (filter == null || !filter.filtering) return null;

        ClipboardCategory[] cats = {};

        foreach (ClipboardCategory cat in ClipboardCategory.all())
        {
            Unity.FilterOption? option = filter.get_option(cat.to_string());
            if (option == null || !option.active) continue;

            cats += cat;
        }

        if (cats.length == ClipboardCategory.all().length) return null;

        return cats;
    }

    private static ClipboardTimerange get_filter_datecopied(Unity.FilterSet filter_state)
    {
        Unity.RadioOptionFilter filter = filter_state.get_filter_by_id("date_copied") as Unity.RadioOptionFilter;
        Unity.FilterOption? option = filter.get_active_option();

        string date_copied = option == null ? "all" : option.id;

        return ClipboardTimerange.from_string(date_copied);
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

        // add metadata
        if(result.metadata != null) {
            Variant? orign_variant = result.metadata.lookup("origin");
            if(orign_variant != null) {
                Unity.InfoHint origin_info = new Unity.InfoHint.with_variant(
                    "origin", _("Origin"), null, orign_variant);
                preview.add_info(origin_info);
            }

            Variant? date_copied_variant = result.metadata.lookup("date_copied");
            if(date_copied_variant != null) {
                Unity.InfoHint date_copied_info = new Unity.InfoHint.with_variant(
                    "date_copied", _("Date copied"), null, date_copied_variant);
                preview.add_info(date_copied_info);
            }
        }

        return preview;
    }
}
