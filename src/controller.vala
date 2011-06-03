/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010-2011 Diodon Team <diodon-team@lists.launchpad.net>
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

namespace Diodon
{
    /**
     * The controller is responsible to interact with all managers and views
     * passing on information between such and storing the application state
     * in the available models.
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class Controller : GLib.Object
    {
        /**
         * Called when a item needs to be copied to a clipboard selection.
         */
        private signal void on_copy_selection(IClipboardItem item);
        
        /**
         * Called when a item has been selected.
         */
        private signal void on_select_item(IClipboardItem item);
        
        /**
         * Called when a new item has been available
         */
        private signal void on_new_item(IClipboardItem item);
        
        /**
         * Called when a item needs to be removed
         */
        private signal void on_remove_item(IClipboardItem item);
        
        /**
         * Called when all items need to be cleared
         */
        private signal void on_clear();
        
        /**
         * Called when the menu needs to be shown
         *
         * @param event 
         */
        private signal void on_show_menu();
        
        /**
         * indicator view property
         */        
        public IndicatorView indicator_view { get; set; default = new IndicatorView(); }
        
        /**
         * preferences dialog view property
         */
        public PreferencesView preferences_view { get; set; default = new PreferencesView(); }
        
        /**
         * configuration manager property
         */
        public ConfigurationManager configuration_manager { get; set; default = new ConfigurationManager(); }
        
        /**
         * keybinding manager property
         */
        public KeybindingManager keybinding_manager { get; set; default = new KeybindingManager(); }
        
#if(UNITY_LENS)

        /**
         * unity lens daemon
         */
        public UnityLens.Daemon lens_daemon
        {
            set {
                value.on_activate_uri.connect(activate_uri);
            }
        }

#endif
        
         /**
         * clipboard managers. Per default a primary and clipboard manager
         * are initialized in the default constructor.
         */
        public Gee.HashMap<ClipboardType, ClipboardManager> clipboard_managers
        {
            get;
            set;
        }
        
        /**
         * clipboard model property default set to a memory storage.
         */
        public ClipboardModel clipboard_model
        {
            get;
            set;
            // currently default for storage not needed
            //default = new ClipboardModel(new MemoryClipboardStorage());
         }
        
        /**
         * configuration model property
         */
        public ConfigurationModel configuration_model { get; set; default = new ConfigurationModel(); }
        
        /**
         * Default constructor
         */
        public Controller()
        {            
            // initialize needed clipboard managers
            clipboard_managers = new Gee.HashMap<ClipboardType, ClipboardManager>();
            clipboard_managers.set(ClipboardType.CLIPBOARD, new ClipboardManager(ClipboardType.CLIPBOARD));
            clipboard_managers.set(ClipboardType.PRIMARY, new PrimaryClipboardManager());
        }
        
        /**
         * Connects to all necessary processes and attaches
         * such to the controller signals as well. Finally the views
         * and the models will be initialized.
         */
        public void start()
        {               
            connect_signals();
            attach_signals();
            init();
        }
        
        /**
         * connects controller to all signals of injected managers and views
         */
        private void connect_signals()
        {
            // indicator
            indicator_view.on_quit.connect(quit);
            indicator_view.on_clear.connect(clear);
            indicator_view.on_show_preferences.connect(show_preferences);
            indicator_view.on_select_item.connect(select_item);
            
            // preferences
            preferences_view.on_change_use_clipboard.connect(change_use_clipboard_configuration);
            preferences_view.on_change_use_primary.connect(change_use_primary_configuration);
            preferences_view.on_change_synchronize_clipboards.connect(change_synchronize_clipboards_configuration);
            preferences_view.on_change_keep_cliboard_content.connect(change_keep_clipboard_content_configuration);
            preferences_view.on_change_clipboard_size.connect(change_clipboard_size_configuration);
            preferences_view.on_change_history_accelerator.connect(change_history_accelerator_configuration);
            preferences_view.on_close.connect(hide_preferences);
        }
        
        /**
         * attaches managers and views to signals of the controller
         */
        private void attach_signals()
        {
            on_select_item.connect(clipboard_model.select_item);
            on_select_item.connect(indicator_view.select_item);

            on_new_item.connect(clipboard_model.add_item);
            on_new_item.connect(indicator_view.prepend_item);
            on_new_item.connect(indicator_view.hide_empty_item);

            on_remove_item.connect(clipboard_model.remove_item);
            on_remove_item.connect(indicator_view.remove_item);
            
            on_clear.connect(clipboard_model.clear);
            on_clear.connect(indicator_view.clear);
            on_clear.connect(indicator_view.show_empty_item);
            
            on_show_menu.connect(indicator_view.show_menu);
        }
        
        /**
         * Initializes views, models and managers.
         */
        private void init()
        {
             // add all available items from storage to indicator
            foreach(IClipboardItem item in clipboard_model.get_items()) {
                indicator_view.hide_empty_item();
                indicator_view.prepend_item(item);
            }
            
            init_configuration();
            
             // start clipboard managers
            foreach(ClipboardManager clipboard_manager in clipboard_managers.values) {
                clipboard_manager.start();
            }
            
            keybinding_manager.init();
        }
        
        /**
         * Initialize configuration values
         */
        private void init_configuration()
        {
             // use clipboard configuration
            configuration_manager.add_bool_notify(configuration_model.use_clipboard_key,
                () => {
                    enable_clipboard_manager(ClipboardType.CLIPBOARD);
                    configuration_model.use_clipboard = true;                        
                },
                () => {
                    disable_clipboard_manager(ClipboardType.CLIPBOARD);
                    configuration_model.use_clipboard = false;
                },
                configuration_model.use_clipboard // default value
            );
            
            // use primary configuration
            configuration_manager.add_bool_notify(configuration_model.use_primary_key,
                () => {
                    enable_clipboard_manager(ClipboardType.PRIMARY);
                    configuration_model.use_primary = true;
                },
                () => {
                    disable_clipboard_manager(ClipboardType.PRIMARY);
                    configuration_model.use_primary = false;
                },
                configuration_model.use_primary // default value
            );
            
            // synchronize clipboards
            configuration_manager.add_bool_notify(configuration_model.synchronize_clipboards_key,
                () => { configuration_model.synchronize_clipboards = true; },
                () => { configuration_model.synchronize_clipboards = false; },
                configuration_model.synchronize_clipboards // default value
            );
            
            // keep clipboard content
            configuration_manager.add_bool_notify(configuration_model.keep_clipboard_content_key,
                enable_keep_clipboard_content,
                disable_keep_clipboard_content,
                configuration_model.keep_clipboard_content  // default value
            );
            
            // clipboard size
            configuration_manager.add_int_notify(configuration_model.clipboard_size_key,
                change_clipboard_size, configuration_model.clipboard_size);
            
            // history_accelerator
            configuration_manager.add_string_notify(configuration_model.history_accelerator_key,
                change_history_accelerator, configuration_model.history_accelerator);
            
            // show app indicator
            configuration_manager.add_bool_notify(configuration_model.show_indicator_key,
                () => {
                    indicator_view.set_visible(true);
                    configuration_model.show_indicator = true;
                },
                () => {
                    indicator_view.set_visible(false);
                    configuration_model.show_indicator = false;
                },
                configuration_model.show_indicator // default value
            );
        }
        
        /**
         * Select item by moving it onto the top of the menu
         * respectively data storage and then copying it to the clipboard
         *
         * @param item item to be selected
         */
        private void select_item(IClipboardItem item)
        {
            // we do not destroy item here but just doing some rearrangement
            // therefore not calling remove_item
            on_remove_item(item);
            
            on_new_item(item);
            on_select_item(item);
            on_copy_selection(item);
        }
        
        /**
         * Remove given item from view, storage and finally destroy
         * it gracefully.
         *
         * @param item item to be removed
         */
        private void remove_item(IClipboardItem item)
        {
            on_remove_item(item);
            item.remove(); // finally cleaning up
        }
       
        /**
         * Handling text retrieved from clipboard by adding it to the storage
         * and appending it to the menu of the indicator
         * 
         * @param text text received
         */
        private void text_received(ClipboardType type, string text)
        {
            IClipboardItem item = new TextClipboardItem(type, text);
            item_received(item);
        }
        
        /**
         * Handling paths retrieved from clipboard by adding it to the storage
         * and appending it to the menu of the indicator
         * 
         * @param paths paths received
         */
        private void uris_received(ClipboardType type, string paths)
        {
            try {
                IClipboardItem item = new FileClipboardItem(type, paths);
                item_received(item);
            } catch(FileError e) {
                warning("Adding file(s) to history failed: " + e.message);
            }
        }
        
        /**
         * Handling image retrieved from clipboard bu adding it to the storage
         * and appending it to the menu of the indicator.
         */
        private void image_received(ClipboardType type, Gdk.Pixbuf pixbuf)
        {
            try {
                IClipboardItem item = new ImageClipboardItem.with_image(type, pixbuf);
                item_received(item);
            } catch(GLib.Error e) {
                warning("Adding image to history failed: " + e.message);
            }
        }
        
        /**
         * Handling given item by checking if item is equal last added item
         * and if not so, adding it to history and indicator.
         *
         * @param item item received
         */
        private void item_received(IClipboardItem item)
        {
            ClipboardType type = item.get_clipboard_type();
            string label = item.get_label();
            IClipboardItem current_item = clipboard_model.get_current_item(type);
            
            // check if received item is different from last item
            if(current_item == null || !IClipboardItem.equal_func(current_item, item)) {
                debug("received item of type %s from clipboard %d with label %s",
                    item.get_type().name(), type, label);
                
                // remove item from clipboard if it already exists
                if(clipboard_model.get_items().contains(item)) {
                    int index = clipboard_model.get_items().index_of(item);
                    // remove the on item available in the list
                    remove_item(clipboard_model.get_items().get(index));
                }
                
                // check if maximum clipboard size has been reached
                if(configuration_model.clipboard_size == clipboard_model.get_size()) {
                    remove_item(clipboard_model.get_last_item());
                }
                
                on_new_item(item);
                on_select_item(item);

                // when synchronization is enabled                
                // set text on all other clipboards then current type
                // only text can be synchronized
                if(item is TextClipboardItem && configuration_model.synchronize_clipboards) {
                    foreach(ClipboardManager clipboard_manager in clipboard_managers.values) {
                        if(type != clipboard_manager.clipboard_type) {
                            clipboard_manager.select_item(item);
                        }
                    }
                }
            }
            else {
                // item is not used in history
                // therefore we need to clean up
                item.remove();
            }
        }
        
        /**
         * Activate given uri by finding corresponding item in clipboard
         * and select it.
         *
         * @param uri clipboard uri
         */
        private void activate_uri(string uri)
        {
            // check if uri is a clipboard uri
            if(str_equal(uri.substring(0, Config.CLIPBOARD_URI.length), Config.CLIPBOARD_URI)) {
                string checksum = uri.substring(Config.CLIPBOARD_URI.length);
                IClipboardItem item = clipboard_model.get_item_by_checksum(checksum);
                if(item != null) {
                    select_item(item);
                    return;
                }
            }
            
            warning("Could not activate uri %s", uri);
        }
        
        /**
         * Called when clipboard is empty and data might be needed to restored
         * 
         * @param type clipboard type
         */
        private void clipboard_empty(ClipboardType type)
        {               
            // check if a item is there to restore lost content
            IClipboardItem item = clipboard_model.get_current_item(type);
            if(item != null) {
                debug("Clipboard " + "%d".printf(type) + " is empty.");   
                ClipboardManager manager = clipboard_managers.get(type);
                manager.select_item(item);
            }
        }
        
        /**
         * Change size of clipboard history which might cause removing
         * of some items.
         * 
         * @param size clipboard history size
         */
        private void change_clipboard_size(int size)
        {
            configuration_model.clipboard_size = size;

            if(configuration_model.clipboard_size < clipboard_model.get_size()) {
                // create copy of items as otherwise
                // removing in a loop does not work
                Gee.ArrayList<IClipboardItem> items = new Gee.ArrayList<IClipboardItem>();
                items.add_all(clipboard_model.get_items());
                
                int remove = items.size - configuration_model.clipboard_size;
                for(int i = 0; i < remove; ++i) {
                    IClipboardItem item = items.get(i);
                    remove_item(item);
                }
            }
        }
        
         /**
         * Change setting of clipboard_size in configuration manager
         *
         * @param size clipboard size
         */        
        private void change_clipboard_size_configuration(int size)
        {
            configuration_manager.set_int_value(
                configuration_model.clipboard_size_key, size);
        }

        /**
         * change history accelerator key and bind new key to open_history.
         *
         * @param accelerator accelerator parseable by Gtk.accelerator_parse
         */        
        private void change_history_accelerator(string accelerator)
        {
            keybinding_manager.unbind(configuration_model.history_accelerator);
            configuration_model.history_accelerator = accelerator;
            keybinding_manager.bind(accelerator, open_history);
        }
        
        /**
         * Change setting of history_accelerator in configuration manager
         *
         * @param accelerator accelerator parseable by Gtk.accelerator_parse
         */        
        private void change_history_accelerator_configuration(string accelerator)
        {
            configuration_manager.set_string_value(
                configuration_model.history_accelerator_key, accelerator);
        }

        /**
         * Open indicator to view history
         */        
        private void open_history()
        {
            // execute show_menu in main loop
            // do avoid dead lock
            Timeout.add(100, () => {
                on_show_menu();
                return false; // stop timer
            });
        }

        /**
         * connect and attach to signals of given clipboard type to enable it.
         *
         * @param type type of clipboard
         */
        private void enable_clipboard_manager(ClipboardType type)
        {
            ClipboardManager manager = clipboard_managers.get(type);
            manager.on_text_received.connect(text_received);
            manager.on_uris_received.connect(uris_received);
            manager.on_image_received.connect(image_received);
            on_copy_selection.connect(manager.select_item);
            on_clear.connect(manager.clear);
        }

        /**
         * disconnect and dis-attach to signals of given manager to disable it.
         *
         * @param type type of clipboard
         */
        private void disable_clipboard_manager(ClipboardType type)
        {
            ClipboardManager manager = clipboard_managers.get(type);
            manager.on_text_received.disconnect(text_received);
            manager.on_uris_received.disconnect(uris_received);
            on_copy_selection.disconnect(manager.select_item);
            on_clear.disconnect(manager.clear);
        }
        
        /**
         * connect to signals of all clipboard manager to enable
         * keep clipboard content support
         */
        private void enable_keep_clipboard_content()
        {
            foreach(ClipboardManager clipboard_manager in clipboard_managers.values) {
                clipboard_manager.on_empty.connect(clipboard_empty);
            }
            
            configuration_model.keep_clipboard_content = true;
        }
        
        /**
         * disconnect to signals of all clipboard manager to disable
         * keep clipboard content support
         */
        private void disable_keep_clipboard_content()
        {
            foreach(ClipboardManager clipboard_manager in clipboard_managers.values) {
                clipboard_manager.on_empty.disconnect(clipboard_empty);
            }
            
            configuration_model.keep_clipboard_content = false;
        }

        /**
         * Change setting of use_clipboard in configuration manager
         */        
        private void change_use_clipboard_configuration()
        {
            configuration_manager.set_bool_value(
                configuration_model.use_clipboard_key,
                !configuration_model.use_clipboard);
        }
        
        /**
         * Change setting of use_primary in configuration manager
         */        
        private void change_use_primary_configuration()
        {
            configuration_manager.set_bool_value(
                configuration_model.use_primary_key,
                !configuration_model.use_primary);
        }
        
        /**
         * Change setting of synchronize_clipboards in configuration manager
         */        
        private void change_synchronize_clipboards_configuration()
        {
            configuration_manager.set_bool_value(
                configuration_model.synchronize_clipboards_key,
                !configuration_model.synchronize_clipboards);
        }
        
         /**
         * Change setting of keep_clipboard_content in configuration manager
         */  
        private void change_keep_clipboard_content_configuration()
        {
            configuration_manager.set_bool_value(
                configuration_model.keep_clipboard_content_key,
                !configuration_model.keep_clipboard_content);
        }
        
        /**
         * Show preferences dialog
         */
        private void show_preferences()
        {
            preferences_view.show(configuration_model);
        }
        
        /**
         * Hide preferences dialog
         */
        private void hide_preferences()
        {
            preferences_view.hide();
        }
        
        /**
         * Clear all items from the clipboard and reset selected items
         */
        private void clear()
        {
            // get list of items for cleaning it up later
            Gee.ArrayList<IClipboardItem> items = new Gee.ArrayList<IClipboardItem>();
                items.add_all(clipboard_model.get_items());
                
            on_clear();
            
            // finally cleaning up items
            foreach(IClipboardItem item in items) {
                item.remove();
            }
        }
        
        /**
         * Quit diodon
         */
        private void quit()
        {
            Gtk.main_quit();
        }
    }  
}
 
