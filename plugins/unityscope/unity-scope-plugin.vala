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
        
        public Object object { get; construct; }
        
        public UnityScopePlugin()
        {
            Object();
        }
        
        public void activate()
        {
            debug("activate unityscope plugin");
            
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
                warning("Failed to Unity ScopeDBusConnector': %s",
                    error.message);
            }
        }

        public void deactivate()
        {
            debug("deactivate unityscope plugin");
        }

        public void update_state ()
        {
        }
        
        private static void search(Unity.ScopeSearchBase search)
        {
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

