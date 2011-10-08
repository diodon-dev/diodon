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
     * The configuration model encapsulates the configuration state.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ConfigurationModel : GLib.Object
    {
        private int _clipboard_size = 25;
        private string _history_accelerator = "<Ctrl><Alt>V";
    
        /**
         * flag whether primary selection is enabled
         */
        public bool use_primary { get; set; default = true; }
            
        /**
         * flag whether clipboard is enabled
         */
        public bool use_clipboard { get; set; default = true; }
        
        /**
         * flag whether clipboards should be in sync
         */
        public bool synchronize_clipboards { get; set; default = false; }
                
        /**
         * flag whether clipboard content should be restored when lost.
         */
        public bool keep_clipboard_content { get; set; default = true; }
                
        /**
         * flag whether clipboard content should be automatically pasted
         */
        public bool instant_paste { get; set; default = true; }
        
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
         * previous clipboard history accelerator
         */
        public string previous_history_accelerator { get; set; }
        
        /**
         * clipboard history accelerator
         */
        public string history_accelerator
        {
            get {
                return _history_accelerator;
            }
            set {
                previous_history_accelerator = _history_accelerator;
                _history_accelerator = value;
            }
        }
    }
}

