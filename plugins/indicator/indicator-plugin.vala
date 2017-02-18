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
 *
 * Author:
 *  Oliver Sauder <os@esite.ch>
 */

namespace Diodon.Plugins
{
    /**
     * Providing access to clipboard history through an application
     * indicator.
     */
    public class IndicatorPlugin : Peas.ExtensionBase, Peas.Activatable
    {
        private AppIndicator.Indicator indicator;
        public Object object { owned get; construct; }

        public IndicatorPlugin()
        {
            Object();
        }

        public void activate()
        {
            Controller controller = object as Controller;

            if(indicator == null) {
                indicator = new AppIndicator.Indicator("Diodon", "diodon-panel",
                    AppIndicator.IndicatorCategory.APPLICATION_STATUS);

                indicator.set_menu(controller.get_recent_menu());

                controller.on_recent_menu_changed.connect(change_menu);
            }

            indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
        }

        public void deactivate()
        {
            Controller controller = object as Controller;

            if(indicator != null) {
                indicator.set_status(AppIndicator.IndicatorStatus.PASSIVE);
                controller.on_recent_menu_changed.disconnect(change_menu);
            }
        }

        public void update_state()
        {
        }

        private void change_menu(Gtk.Menu recent_menu)
        {
            indicator.set_menu(recent_menu);
        }
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
  Peas.ObjectModule objmodule = module as Peas.ObjectModule;
  objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (Diodon.Plugins.IndicatorPlugin));
}

