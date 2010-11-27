/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010 Diodon Team <diodon-team@lists.launchpad.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Diodon
{
    /**
     * This controller is responsible for interacting with the GConf
     * sub system. Configuration changes will be passed onto the
     * ClipboardController and the configuration state will be stored in the
     * ConfigurationModel.
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ConfigurationController : GLib.Object
    {
        /**
         * gconf client
         */
        //private GConf.Client client;
        
        /**
         * Constructor.
         */
        public ConfigurationController()
        {
            // client = GConf.Client.get_default();
        }

        /**
         * Starts process initializing configuration values with user defined
         * gconf options and hooks onto the gconf callback to be notified when a
         * gconf option has been changed.
         */
        public void start()
        {
            
        }
        
        public void update_configuration()
        {
        }
    }
}

