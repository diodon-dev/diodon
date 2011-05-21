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

namespace Diodon.UnityLens
{
    /**
     * TODO: needs to be replaced with a diodon specific path
     * Absolute path to custom unity icons.
     */
    const string UNITY_ICON_PATH = "/usr/share/icons/unity-icon-theme/places/svg/";

    /**
     * A daemon for the unity lens
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class Daemon : GLib.Object, Unity.Activation
    {
        private Unity.PlaceController controller;
        private Unity.PlaceEntryInfo place_entry;
        
        /**
         * TODO: this is only a workaround and breaks the softwware design
         * the controller should actually expose all needed operations
         * from the clipboard model and the daemon should access the controller
         * directly. However should do for now as we only read.
         *
         * access to the clipboard model.
         */
        private ClipboardModel clipboard_model;
        
        /**
         * called when a uri needs to be activated
         */
        public signal void on_activate_uri(string uri);
        
        /**
         * Setup all models, the place_entry and controller
         * needed by the unity shell
         *
         * @param clipboard_model 
         */
        public Daemon(ClipboardModel clipboard_model)
        {
            this.clipboard_model = clipboard_model; 
            
            // Create all the models we need to share with the Unity shell.
            // The model column schemas must align with what we defined in
            // unity-lens-schemas.vala
            Dee.SharedModel sections_model = new Dee.SharedModel(
                Config.BUSNAME + ".SectionsModel");
            sections_model.set_schema("s");
            
            Dee.SharedModel groups_model = new Dee.SharedModel(
                Config.BUSNAME + ".GroupsModel");
            groups_model.set_schema("s", "s", "s");

            Dee.SharedModel global_groups_model = new Dee.SharedModel(
                 Config.BUSNAME + ".GlobalGroupsModel");
            global_groups_model.set_schema("s", "s", "s");
      
            Dee.SharedModel results_model = new Dee.SharedModel(
                Config.BUSNAME + ".ResultsModel");
            results_model.set_schema("s", "s", "u", "s", "s", "s");

            Dee.SharedModel global_results_model = new Dee.SharedModel(
                Config.BUSNAME + ".GlobalResultsModel");
            global_results_model.set_schema("s", "s", "u", "s", "s", "s");
            
            // Create a PlaceEntryInfo. The properties of the PlaceEntryInfo is
            // automatically mapped back and forth over the bus, and removes most
            // DBusisms from the place daemon code.
            // Object path of the PlaceEntryInfo must match the one defined in the
            // the place entry in the place .place file
            place_entry = new Unity.PlaceEntryInfo (Config.BUSOBJECTPATHCLIPBOARD);
            place_entry.sections_model = sections_model;
            place_entry.entry_renderer_info.groups_model = groups_model;
            place_entry.entry_renderer_info.results_model = results_model;
            place_entry.global_renderer_info.groups_model = global_groups_model;
            place_entry.global_renderer_info.results_model = global_results_model;
            
            populate_sections();
            populate_groups();
            
            // Unity preloads the icon defined in the .place file even before the
            // place daemon is running - when we come up it will ratify the icon
            place_entry.icon = "gtk-paste";

            // Listen for section changes and start updating our results model
            // accordingly
            place_entry.notify["active-section"].connect(update_entry_results_model);

            // Listen for changes to the place entry search
            place_entry.notify["active-search"].connect(update_entry_results_model);

            // Listen for changes to the global search
            place_entry.notify["active-global-search"].connect(update_global_results_model);

            // Listen for when the place is hidden/shown by the Unity Shell
            place_entry.notify["active"].connect(
                (obj, pspec) => {
                    debug(@"Activated: $(place_entry.active)");
                }
            );          

            /* The last thing we do is export the controller. Once that is up,
            * clients will expect the Dee.SharedModels to work.
            * The 'place' EntryInfo is exported for Unity to show by adding it to
            * the controller. You can add more than one EntryInfo here if you have
            * more than one place entry to export from the same place daemon */
            controller = new Unity.PlaceController(Config.BUSOBJECTPATH);
            controller.add_entry(place_entry);

            // Since the Daemon class implements the Unity.PlaceActivation interface
            // we can override the default activation handler on the controller.
            // We need to do that to properly handle the activation patternts we
            // registered in the .place file
            controller.activation = this;

            // Export the controller on the bus. Unity can see us past this point
            try {
                controller.export();
            } catch(IOError error) {
                critical("Failed to export DBus service for '%s': %s",
                    controller.dbus_path, error.message);
            }
        }
        
        /**	
         * Populate sections of place currently just text, files and images
         * available.
         */
        private void populate_sections()
        {
            Dee.Model sections = place_entry.sections_model;

            // The row offsets should match those from the ClipboardSection enum
            sections.append(_("All Clipboard"), "");
            sections.append(_("Text"), "");
            sections.append(_("Files"), "");
            sections.append(_("Images"), "");
        }

        /**
         * Populate groups of place currently just text, files and images
         * available.
         */
        private void populate_groups()
        {
            Dee.Model groups = place_entry.entry_renderer_info.groups_model;

            // The row offsets should match those from the ClipboardGroup enum
            // TODO: we need to replace this unity icons with
            // some diodon specific ones
            groups.append("UnityDefaultRenderer", _("Text"), UNITY_ICON_PATH + "group-downloads.svg");
            groups.append("UnityFileInfoRenderer", _("Files"), UNITY_ICON_PATH + "open-folder.svg");
            groups.append("UnityDefaultRenderer", _("Images"), UNITY_ICON_PATH + "group-mostused.svg");
        }
        
        /**
         * Update results model when either section or search has changed.
         * Is only performed when the diodon lens is active
         */
        private void update_entry_results_model ()
        {
            // If we're not active just ignore anything Unity tells us to do
            // it's not gonna show on the screen anyway
            if (!place_entry.active) {
                return;
            }
                        
            Dee.Model results_model = place_entry.entry_renderer_info.results_model;
            Dee.Model groups_model = place_entry.entry_renderer_info.groups_model;
            string search = place_entry.active_search.get_search_string();
            ClipboardSection section = (ClipboardSection)place_entry.active_section;          

            update_results_model(results_model, groups_model, search, section);
        }

        /**
         * Update results model when global search has changed.
         * Unlike update_entry_model() the global model may be updated
         * even though we are not active
         */
        private void update_global_results_model()
        {
            Dee.Model results_model = place_entry.global_renderer_info.results_model;
            Dee.Model groups_model = place_entry.global_renderer_info.groups_model;
            string search = place_entry.active_global_search.get_search_string();
            // we have no active section in global mode
            ClipboardSection section = ClipboardSection.ALL_CLIPBOARD; 

            update_results_model(results_model, groups_model, search, section);
        }

        /**
         * Generic method to update a results model.
         */
        private void update_results_model(Dee.Model results_model, Dee.Model groups_model,
                                          string search, ClipboardSection section)
        {
            debug("Rebuilding results model");
            results_model.clear();
            
            Gee.List<IClipboardItem> items = clipboard_model.get_items();
            
            // add items in reverse order as last added items are
            // more important
            for(int i = items.size -1; i >=0; --i) {
                IClipboardItem item = items.get(i);
                if(item.matches(search, section)) {
                    results_model.append(
                        // FIXME: item itself should implement a sensable uri
                        Config.CLIPBOARD_URI + item.get_checksum(),
                        item.get_icon().to_string(),
                        item.get_group(),
                        item.get_mime_type(),
                        item.get_label(),
                        _("Copy to clipboard")
                    );
                }
            }
        }
        
        /**
         * Override of the default activation handler. Unity will ask the
         * place daemon for activation of the URI pattern and mime type pattern
         * defined in the .place file.
         *
         * This method should return a member of the enumeration
         * Unity.ActivationStatus:
         *
         * - ActivationStatus.ACTIVATED_HIDE_DASH
         * - ActivationStatus.ACTIVATED_SHOW_DASH
         * - ActivationStatus.NOT_ACTIVATED
         *
         */
        public async uint32 activate (string uri)
        {
            debug("Requested activation of: %s", uri);
            on_activate_uri(uri);
            return Unity.ActivationStatus.ACTIVATED_HIDE_DASH;
        }
    }
}

