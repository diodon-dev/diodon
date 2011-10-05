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

namespace Diodon.Plugins.Indicator
{
    /**
     * Providing access to clipboard history through an application
     * indicator.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class IndicatorPlugin : Peas.ExtensionBase, Peas.Activatable
    {
        public Object object { owned get; construct; }

        public IndicatorPlugin()
        {
            Object();
        }

        public void activate()
        {
            debug("activated indicator plugin");                    
        }

        public void deactivate()
        {
          debug("deactivated indicator plugin");
        }

        public void update_state ()
        {
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

