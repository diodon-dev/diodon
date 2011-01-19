/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010 Diodon Team <diodon-team@lists.launchpad.net>
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
     * The configuration model encapsulates the configuration state.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ConfigurationModel : GLib.Object
    {
        private int _clipboard_size = 25;
    
        /**
         * key of use primary key flag
         */
        public string use_primary_key { get { return "/clipboard/use_primary"; } }
        
        /**
         * flag whether primary selection is enabled
         */
        public bool use_primary { get; set; default = true; }
        
        /**
         * key for use clipboard key flag
         */
        public string use_clipboard_key { get { return "/clipboard/use_clipboard"; } }
        
        /**
         * flag whether clipboard is enabled
         */
        public bool use_clipboard { get; set; default = true; }
        
        /**
         * key for synchronize clipboards flag
         */
        public string synchronize_clipboards_key { get { return "/clipboard/synchronize_clipboards"; } }
        
        /**
         * flag whether clipboards should be in sync
         */
        public bool synchronize_clipboards { get; set; default = false; }
        
        /**
         * flag whether clipboard content should be restored when lost.
         */
        public bool keep_clipboard_content { get; set; default = true; }
        
        /**
         * key for keep clipboard content key
         */
        public string keep_clipboard_content_key { get { return "/clipboard/keep_clipboard_content"; } }
        
        /**
         * key of clipboard history size
         */
        public string clipboard_size_key { get { return "/clipboard/clipboard_size"; } }
        
        /**
         * size of clipboard history.
         * Value must be bigger than 0 and lower or equal than 100.
         */
        public int clipboard_size
        {
            get { 
                return _clipboard_size;
            }
            set {
                if(value > 0 && value <= 100) {
                    _clipboard_size = value;
                }
            }
        }
        
        /**
         * key for clipboard history accelerator
         */
       public string history_accelerator_key { get { return "/keybindings/history"; } }
       
       /**
        * clipboard history accelerator
        */
       public string history_accelerator { get; set; default = "<Ctrl><Alt>V"; }
    }
}

