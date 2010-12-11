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
     * configuration errors
     */
    errordomain ConfigurationError {
       KEYNOTINITIALIZED 
    }

    /**
     * This manager is responsible for interacting with the GConf
     * sub system. Any process can register to any diodon specific
     * configuration value.
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ConfigurationManager : GLib.Object
    {
        private GConf.Client client;
        private static string GCONF_APP_PATH = "/apps/diodon";
        
        /**
         * delegate to be called when a integer value has been changed
         */
        public delegate void ChangeIntFunc(int value);
        
        public delegate void ChangeStringFunc(string value);
        
        /**
         * delegate to be called when a value has been enabled
         */
        public delegate void EnableFunc();
        
        /**
         * delegate to be called when a value has been disabled
         */
        public delegate void DisbaleFunc();
        
        /**
         * Constructor.
         */
        public ConfigurationManager()
        {
            client = GConf.Client.get_default();
            
            try {
                client.add_dir(GCONF_APP_PATH, GConf.ClientPreloadType.RECURSIVE);
            } catch(GLib.Error e) {
                warning("Could not add directory listener to GConf client. Error: " + e.message);
            }
        }
        
        /**
         * Add notify function for given diodon key of a string value. First
         * notify will be called immediately with the already available value
         * if valid otherwise the default value will be returned.
         * 
         * @param key configuration key
         * @param change_string_func called when value has been changed
         * @param default default value to be set if not available
         */
        public void add_string_notify(string key, ChangeStringFunc change_string_func, string default)
        {
            string value = default;
             try {
                GConf.Value conf_value = get_value(key);
                value = conf_value.get_string();
            } catch(GLib.Error e) {
                debug("Boolean value of key " + key + " is not available yet.");
                set_string_value(key, default);
            }
            
            // initial call
            change_string_func(value);
            
            try {
                client.notify_add(GCONF_APP_PATH + key, (client, cxnid, entry) => {
                    string new_value = entry.get_value().get_string();
                    debug("Value of key " + entry.get_key() + " has changed to " + new_value);
                    change_string_func(new_value);
                });
            } catch(GLib.Error e) {
                warning("Could not add notify of key " + key + " (Error: )" + e.message);
            }
        }
        
        /**
         * Add notify function for given diodon key of a integer value. First
         * notify will be called immediately with the already available value
         * if valid otherwise the default value will be returned.
         * 
         * @param key configuration key
         * @param change_int_func called when value has been changed
         * @param default default value to be set if not available
         */
        public void add_int_notify(string key, ChangeIntFunc change_int_func, int default)
        {
            int value = default;
            try {
                GConf.Value conf_value = get_value(key);
                value = conf_value.get_int();
            } catch(GLib.Error e) {
                debug("Boolean value of key " + key + " is not available yet.");
                set_int_value(key, default);
            }
            
            // initial call
            change_int_func(value);
            
            try {
                client.notify_add(GCONF_APP_PATH + key, (client, cxnid, entry) => {
                    int new_value = entry.get_value().get_int();
                    debug("Value of key " + entry.get_key() + " has changed to " + "%d".printf(new_value));
                    change_int_func(new_value);
                });
            } catch(GLib.Error e) {
                warning("Could not add notify of key " + key + " (Error: )" + e.message);
            }
        }
        
        /**
         * Set string value to given key.
         * 
         * @param key value key
         * @param value value to set
         */
        public void set_string_value(string key, string value)
        {
            try {
                // TODO: check if value is writable before writing
                client.set_string(GCONF_APP_PATH + key, value);
            } catch(GLib.Error e) {
                warning("Could not change string value of key " + key + " to " + 
                    value.to_string() + " (Error: )" + e.message);
            }
        }
        
        /**
         * Set integer value to given key.
         * 
         * @param key value key
         * @param value value to set
         */
        public void set_int_value(string key, int value)
        {
            try {
                // TODO: check if value is writable before writing
                client.set_int(GCONF_APP_PATH + key, value);
            } catch(GLib.Error e) {
                warning("Could not change integer value of key " + key + " to " + 
                    value.to_string() + " (Error: )" + e.message);
            }
        }
        
        /**
         * Add notify function for given diodon key of a boolean value. First
         * notify will be called immediately with the already available value
         * if valid otherwise the default value will be returned.
         * 
         * @param key configuration key
         * @param enable_func called when value has been enabled
         * @param disbale_func called when value has been disabled
         * @param default default to be set when not available
         */
        public void add_bool_notify(string key, EnableFunc enable_func, DisbaleFunc disable_func, bool default)
        {            
            bool value = default;
            try {
                GConf.Value conf_value = get_value(key);
                value = conf_value.get_bool();
            } catch(GLib.Error e) {
                debug("Boolean value of key " + key + " is not available yet.");
                set_bool_value(key, default);
            }
            
            // initial call
            enable_disable_handler(value, enable_func, disable_func);
                
            try {
                client.notify_add(GCONF_APP_PATH + key, (client, cxnid, entry) => {
                    debug("Value of key " + entry.get_key() + " has changed to " + value.to_string());
                    enable_disable_handler(entry.get_value().get_bool(),
                        enable_func, disable_func);
                });
            } catch(GLib.Error e) {
                warning("Could not add notify of key " + key + " (Error: )" + e.message);
            }
        }
        
        /**
         * Set boolean value to given key.
         * 
         * @param key value key
         * @param value value to set
         */
        public void set_bool_value(string key, bool value)
        {
            try {
                // TODO: check if value is writable before writing
                client.set_bool(GCONF_APP_PATH + key, value);
            } catch(GLib.Error e) {
                warning("Could not change boolean value of key " + key + " to " + 
                    value.to_string() + " (Error: )" + e.message);
            }
        }
        
        /**
         * Get value with given from gconf client. Throw error
         * either if not possible to get key or if key is not available.
         *
         * @param key key of value
         */
        private GConf.Value get_value(string key) throws GLib.Error
        {
            GConf.Value conf_value = client.get(GCONF_APP_PATH + key);
                
            if(conf_value == null) {
                throw new ConfigurationError.KEYNOTINITIALIZED("No value for " + key + " has been assigned.");
            }
            
            return conf_value;
        }
        
        /**
         * Helper method to either call enable_func when value is true
         * or otherwise the disable_func.
         */
        private void enable_disable_handler(bool value, EnableFunc enable_func, DisbaleFunc disable_func)
        {
            if(value) {
                enable_func();
            } else {
                disable_func();
            }
        }
    }
}

