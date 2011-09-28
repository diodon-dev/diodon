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
        private Settings settings;
        private Settings settings_clipboard;
        private Settings settings_keybindings;
        private Gee.HashMap<ClipboardType, ClipboardManager> clipboard_managers;
        private ClipboardModel clipboard_model;
        private ConfigurationModel configuration_model;
        private IndicatorView indicator_view;
        private PreferencesView preferences_view;
        private KeybindingManager keybinding_manager;
        private Peas.ExtensionSet extension_set;
        private Peas.Engine peas_engine;
        
        /**
         * Called when a item has been selected.
         */
        public signal void on_select_item(IClipboardItem item);
        
        /**
         * Called when a new item is added
         */
        public signal void on_add_item(IClipboardItem item);
        
        /**
         * Called when a item needs to be removed
         */
        public signal void on_remove_item(IClipboardItem item);
        
        /**
         * Called when all items need to be cleared
         */
        public signal void on_clear();
        
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
        
        public Controller()
        {            
            string diodon_dir = Utility.get_user_data_dir();
            clipboard_managers = new Gee.HashMap<ClipboardType, ClipboardManager>();
            
            clipboard_managers.set(ClipboardType.CLIPBOARD, new ClipboardManager(ClipboardType.CLIPBOARD));
            clipboard_managers.set(ClipboardType.PRIMARY, new PrimaryClipboardManager());
            
            keybinding_manager = new KeybindingManager();
            
            settings = new Settings("net.launchpad.Diodon");
            settings_clipboard = new Settings("net.launchpad.Diodon.clipboard");
            settings_keybindings = new Settings("net.launchpad.Diodon.keybindings");
            
            peas_engine = Peas.Engine.get_default();
            peas_engine.add_search_path(Config.PLUGINS_DIR, Config.PLUGINS_DATA_DIR);
            string user_plugins_dir = Path.build_filename(diodon_dir, "plugins");
            peas_engine.add_search_path(user_plugins_dir, user_plugins_dir);
            peas_engine.enable_loader("python");
            
            IClipboardStorage storage = new XmlClipboardStorage(diodon_dir,
                "storage.xml");
            clipboard_model = new ClipboardModel(storage);
            
            configuration_model = new ConfigurationModel();   
            
            indicator_view = new IndicatorView(this);    
            preferences_view = new PreferencesView();                  
        }
        
        /**
         * Initializes clipboard and activates installed plugins
         */
        public void activate()
        {               
            connect_signals();
            init();
            
            extension_set = new Peas.ExtensionSet(peas_engine, typeof(Peas.Activatable),
                "object", this);
            extension_set.@foreach((Peas.ExtensionSetForeachFunc)on_extension_added, null);
            
            extension_set.extension_added.connect((info, exten) => {
                ((Peas.Activatable)exten).activate();
            });
            extension_set.extension_removed.connect((info, exten) => {
                ((Peas.Activatable)exten).deactivate();
            });
            
            indicator_view.activate();
        }
        
        private void on_extension_added(Peas.ExtensionSet set, Peas.PluginInfo info, 
            Peas.Extension exten, void* data)
        {
            ((Peas.Activatable)exten).activate();
        }
        
        /**
         * connects controller to all signals of injected managers and views
         */
        private void connect_signals()
        {
            // preferences
            preferences_view.on_change_use_clipboard.connect(change_use_clipboard_configuration);
            preferences_view.on_change_use_primary.connect(change_use_primary_configuration);
            preferences_view.on_change_synchronize_clipboards.connect(change_synchronize_clipboards_configuration);
            preferences_view.on_change_keep_clipboard_content.connect(change_keep_clipboard_content_configuration);
            preferences_view.on_change_instant_paste.connect(change_instant_paste_configuration);
            preferences_view.on_change_clipboard_size.connect(change_clipboard_size_configuration);
            preferences_view.on_change_history_accelerator.connect(change_history_accelerator_configuration);
            preferences_view.on_close.connect(hide_preferences);
        }
        
        /**
         * Initializes views, models and managers.
         */
        private void init()
        {
            init_configuration();
            
             // start clipboard managers
            foreach(ClipboardManager clipboard_manager in clipboard_managers.values) {
                clipboard_manager.start();
            }
            
            keybinding_manager.init();
        }
        
        /**
         * Initialize configuration values
         * 
         * TODO: remove duplicated code of change event and init call
         */
        private void init_configuration()
        {
            settings_clipboard.bind("use-clipboard", configuration_model,
                "use-clipboard", SettingsBindFlags.DEFAULT);
            settings_clipboard.changed["use-clipboard"].connect(
                (key) => {
                    debug ("Changed use clipboard");
                    enable_clipboard_manager(ClipboardType.CLIPBOARD,
                        configuration_model.use_clipboard);
                }
            );
            enable_clipboard_manager(ClipboardType.CLIPBOARD,
                configuration_model.use_clipboard);
                
            settings_clipboard.bind("use-primary", configuration_model,
                "use-primary", SettingsBindFlags.DEFAULT);
            settings_clipboard.changed["use-primary"].connect(
                (key) => {
                    enable_clipboard_manager(ClipboardType.PRIMARY,
                        configuration_model.use_primary);
                }
            );
            enable_clipboard_manager(ClipboardType.PRIMARY,
                configuration_model.use_primary);
            
            settings_clipboard.bind("synchronize-clipboards", configuration_model,
                "synchronize-clipboards", SettingsBindFlags.DEFAULT);

            settings_clipboard.bind("keep-clipboard-content", configuration_model,
                "keep-clipboard-content", SettingsBindFlags.DEFAULT);
            settings_clipboard.changed["keep-clipboard-content"].connect(
                (key) => {
                    enable_keep_clipboard_content(
                        configuration_model.keep_clipboard_content);
                }
            );
            enable_keep_clipboard_content(
                configuration_model.keep_clipboard_content);
            
            settings_clipboard.bind("instant-paste", configuration_model,
                "instant-paste", SettingsBindFlags.DEFAULT);
                
            settings_clipboard.bind("clipboard-size", configuration_model,
                "clipboard-size", SettingsBindFlags.DEFAULT);
            settings_clipboard.changed["clipboard-size"].connect(
                (key) => {
                    change_clipboard_size(configuration_model.clipboard_size);
                }
            );
            change_clipboard_size(configuration_model.clipboard_size);
                
            // we cannot bind this property as we need the previous value
            configuration_model.history_accelerator =
                settings_keybindings.get_string("history-accelerator");
            settings_keybindings.changed["history-accelerator"].connect(
                (key) => {
                    change_history_accelerator(
                        settings_keybindings.get_string("history-accelerator"));
                }   
            );
            keybinding_manager.bind(configuration_model.history_accelerator, open_history);
                
            settings.bind("show-indicator", configuration_model,
                "show-indicator", SettingsBindFlags.DEFAULT);
            settings.changed["show-indicator"].connect(
                (key) => {
                    indicator_view.set_visible(configuration_model.show_indicator);
                }
            );
            indicator_view.set_visible(configuration_model.show_indicator);
        }
        
        /**
         * Select clipboard item
         *
         * @param item item to be selected
         */
        public void select_item(IClipboardItem item)
        {   
            clipboard_model.select_item(item);
            
            on_select_item(item);
            
            if(configuration_model.instant_paste) {
                execute_paste(item);
            }
        }

        /**
         * Execute paste instantly according to set preferences.
         * 
         * @param item item to be pasted
         */
        public void execute_paste(IClipboardItem item)
        {
            string key = null;
            if(configuration_model.use_clipboard) {
                key = "<Ctrl>V";
            }
            
            // prefer primary selection paste as such works
            // in more cases (e.g. terminal)
            // however it does not work with files and images
            if(configuration_model.use_primary && item is TextClipboardItem) {
                key = "<Shift>Insert";
            }
            
            if(key != null) {
                keybinding_manager.press(key);
                keybinding_manager.release(key);
            }
        }
        
        /**
         * Remove given item from view, storage and finally destroy
         * it gracefully.
         *
         * @param item item to be removed
         */
        public void remove_item(IClipboardItem item)
        {
            clipboard_model.remove_item(item);
            on_remove_item(item);
        }
       
        /**
         * Add given text as text item to current clipboard history
         * 
         * @param text text to be added
         */
        public void add_as_text_item(ClipboardType type, string text)
        {
            IClipboardItem item = new TextClipboardItem(type, text);
            add_item(item);
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
                add_item(item);
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
                add_item(item);
            } catch(GLib.Error e) {
                warning("Adding image to history failed: " + e.message);
            }
        }
        
        /**
         * Handling given item by checking if item is equal last added item
         * and if not so, adding it to history
         *
         * @param item item received
         */
        public void add_item(IClipboardItem item)
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
                
                clipboard_model.add_item(item);
                on_add_item(item);

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
         * Get all clipboard items
         * 
         * @return list of clipboard items
         */ 
        public Gee.List<IClipboardItem> get_items()
        {
            return clipboard_model.get_items();
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
         * Change setting of clipboard_size in configuration model
         *
         * @param size clipboard size
         */        
        private void change_clipboard_size_configuration(int size)
        {
            configuration_model.clipboard_size = size;
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
         * Change setting of history_accelerator in GSettings itself
         *
         * @param accelerator accelerator parseable by Gtk.accelerator_parse
         */        
        private void change_history_accelerator_configuration(string accelerator)
        {
            settings_keybindings.set_string("history-accelerator", accelerator);
        }

        /**
         * Open indicator to view history
         */        
        private void open_history()
        {
            // execute show_menu in main loop
            // to avoid dead lock
            Timeout.add(100, () => {
                indicator_view.show_menu();
                return false; // stop timer
            });
        }

        /**
         * connect/disconnect and attach/disattach to signals of given clipboard
         * type to enable/disable it.
         *
         * @param type type of clipboard
         * @param enable true for enabling; false for disabling
         */
        private void enable_clipboard_manager(ClipboardType type, bool enable)
        {
            ClipboardManager manager = clipboard_managers.get(type);
            
            if(enable) {
                manager.on_text_received.connect(add_as_text_item);
                manager.on_uris_received.connect(uris_received);
                manager.on_image_received.connect(image_received);
                on_select_item.connect(manager.select_item);
                on_clear.connect(manager.clear);
            }
            else {
                manager.on_text_received.disconnect(add_as_text_item);
                manager.on_uris_received.disconnect(uris_received);
                on_select_item.disconnect(manager.select_item);
                on_clear.disconnect(manager.clear);    
            }
        }
                
        /**
         * connect/disconnect to signals of all clipboard manager to
         * enable/disable keep clipboard content support
         * 
         * @param enable true for enabling; false for disabling
         */
        private void enable_keep_clipboard_content(bool enable)
        {
            foreach(ClipboardManager clipboard_manager in clipboard_managers.values) {
                if(enable) {
                    clipboard_manager.on_empty.connect(clipboard_empty);
                }
                else {
                    clipboard_manager.on_empty.disconnect(clipboard_empty);    
                }
            }
        }

        /**
         * Change setting of use_clipboard in configuration model
         */        
        private void change_use_clipboard_configuration()
        {
            configuration_model.use_clipboard = !configuration_model.use_clipboard;
        }
        
        /**
         * Change setting of use_primary in configuration model
         */        
        private void change_use_primary_configuration()
        {
            configuration_model.use_primary = !configuration_model.use_primary;
        }
        
        /**
         * Change setting of synchronize_clipboards in configuration model
         */        
        private void change_synchronize_clipboards_configuration()
        {
            configuration_model.synchronize_clipboards = !configuration_model.synchronize_clipboards;
        }
        
        /**
         * Change setting of keep_clipboard_content in configuration model
         */  
        private void change_keep_clipboard_content_configuration()
        {
            configuration_model.keep_clipboard_content = !configuration_model.keep_clipboard_content;
        }
        
        /**
         * Change setting of instant_paste in configuration model
         */  
        private void change_instant_paste_configuration()
        {
            configuration_model.instant_paste = !configuration_model.instant_paste;
        }
        
        /**
         * Show preferences dialog
         */
        public void show_preferences()
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
         * Clear all clipboard items from history
         */
        public void clear()
        {
            clipboard_model.clear();
            on_clear();
        }
        
        /**
         * Quit diodon
         */
        public void quit()
        {
            Gtk.main_quit();
        }
    }  
}

