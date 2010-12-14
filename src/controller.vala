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
        private signal void on_copy_selection(ClipboardItem item);
        
        /**
         * Called when a item has been selected.
         */
        private signal void on_select_item(ClipboardItem item);
        
        /**
         * Called when a new item has been available
         */
        private signal void on_new_item(ClipboardItem item);
        
        /**
         * Called when a item needs to be removed
         */
        private signal void on_remove_item(ClipboardItem item);
        
        /**
         * Called when all items need to be cleared
         */
        private signal void on_clear();
        
        /**
         * Called when the menu needs to be shown
         *
         * @param event 
         */
        private signal void on_show_menu(Gdk.Event event);

        /**
         * indicator view property
         */        
        public IndicatorView indicator_view { get; set; default = new IndicatorView(); }
        
        /**
         * configuration manager property
         */
        public ConfigurationManager configuration_manager { get; set; default = new ConfigurationManager(); }
        
        /**
         * keybinding manager property
         */
        public KeybindingManager keybinding_manager { get; set; default = new KeybindingManager(); }
        
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
            default = new ClipboardModel(new MemoryClipboardStorage());
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
            // TODO: checkout how to get values from enum
            // to generalize this code
            clipboard_managers = new Gee.HashMap<ClipboardType, ClipboardManager>();
            clipboard_managers.set(ClipboardType.CLIPBOARD, new ClipboardManager(ClipboardType.CLIPBOARD));
            clipboard_managers.set(ClipboardType.PRIMARY, new ClipboardManager(ClipboardType.PRIMARY));
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
            indicator_view.on_select_item.connect(select_item);
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

            on_remove_item.connect(clipboard_model.remove_item);
            on_remove_item.connect(indicator_view.remove_item);
            
            on_clear.connect(clipboard_model.clear);
            on_clear.connect(indicator_view.clear);
            
            on_show_menu.connect(indicator_view.show_menu);
        }
        
        /**
         * Initializes views, models and managers.
         */
        private void init()
        {
             // add all available items from storage to indicator
            foreach(ClipboardItem item in clipboard_model.get_items()) {
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
                () => { enable_clipboard_manager(ClipboardType.CLIPBOARD); },
                () => { disable_clipboard_manager(ClipboardType.CLIPBOARD); },
                configuration_model.use_clipboard
            );
            
            // use primary configuration
            configuration_manager.add_bool_notify(configuration_model.use_primary_key,
                () => { enable_clipboard_manager(ClipboardType.PRIMARY); },
                () => { disable_clipboard_manager(ClipboardType.PRIMARY); },
                configuration_model.use_primary
            );
            
            // clipboard size
            configuration_manager.add_int_notify(configuration_model.clipboard_size_key,
                change_clipboard_size, configuration_model.clipboard_size);
            
            // history_accelerator
            configuration_manager.add_string_notify(configuration_model.history_accelerator_key,
                change_history_accelerator, configuration_model.history_accelerator);
        }
        
        /**
         * Select item by moving it onto the top of the menu
         * respectively data storage and then copying it to the clipboard
         *
         * @param item item to be selected
         */
        private void select_item(ClipboardItem item)
        {
            on_remove_item(item);
            on_new_item(item);
            on_select_item(item);
            on_copy_selection(item);
        }
       
        /**
         * Handling text retrieved from clipboard by adding it to the storage
         * and appending it to the menu of the indicator
         * 
         * @param text text received
         */
        private void text_received(ClipboardType type, string text)
        {
            ClipboardItem current_item = clipboard_model.get_current_item(type);
            if(current_item == null || text != current_item.text) {
                debug("received text from clipboard " + "%d".printf(type) + ": " + text);
                ClipboardItem item = new ClipboardItem(type, text);
                
                // remove item from clipboard if it already exists
                if(clipboard_model.get_items().contains(item)) {
                    on_remove_item(item);
                }
                
                // check if maximum clipboard size has been reached
                if(configuration_model.clipboard_size == clipboard_model.get_size()) {
                    on_remove_item(clipboard_model.get_last_item());
                }
                
                on_new_item(item);
                on_select_item(item);
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
                Gee.ArrayList<ClipboardItem> items = new Gee.ArrayList<ClipboardItem>();
                items.add_all(clipboard_model.get_items());
                
                int remove = items.size - configuration_model.clipboard_size;
                for(int i = 0; i < remove; ++i) {
                    ClipboardItem item = items.get(i);
                    on_remove_item(item);
                }
            }
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
         * Open indicator to view history
         */        
        private void open_history(Gdk.Event event)
        {
            on_show_menu(event);
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
            on_copy_selection.disconnect(manager.select_item);
            on_clear.disconnect(manager.clear);
        }
        
        /**
         * Clear all items from the clipboard and reset selected items
         */
        private void clear()
        {
            on_clear();
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
 
