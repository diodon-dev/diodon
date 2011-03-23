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

namespace Diodon
{
    /**
     * Specific clipboard manager for primary selection extending
     * basic functionality with primary selection specific use cases.
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class PrimaryClipboardManager : ClipboardManager
    {
        /**
         * Type is alwawys ClipboardType.PRIMARY for this specific primary
         * selection manager.
         */
        public PrimaryClipboardManager()
        {
            base(ClipboardType.PRIMARY);
        }
        
        /**
         * Owner does not always get changed when selection has been changed
         * therefore we need a timer for the primary selection.
         */
        public override void start()
        {
            Timeout.add(500, request_text_callback);
        }
        
        /**
         * Primary selection only supports text therefore ignoring
         * all others.
         *
         * @param item clipboard item to be selected
         */
        public override void select_item(IClipboardItem item)
        {
            if(item is TextClipboardItem) {
                base.select_item(item);
            }
        }
    
        /**
         * Additionaly check if the mouse button or shift button is pressed
         * before primary selection gets accepted. As otherwise the history
         * gets flodded with several clipboard items.
         *
         * @param text clipboard text
         * @return true if accepted; otherwise false.
         */
        protected override bool is_accepted(string text)
        {
            Gdk.Window rootwin = Gdk.get_default_root_window();
            Gdk.Display display = rootwin.get_display();
            Gdk.ModifierType modifier = 0;
            display.get_pointer(null, null, null, out modifier);
            
            // only accepted when left mouse button and shift button
            // are not pressed
            if((modifier & Gdk.ModifierType.BUTTON1_MASK) == 0) {
                if((modifier & Gdk.ModifierType.SHIFT_MASK) == 0) {
                    return true;
                }
            }
            
            return false;
        }
        
        /**
         * Helper method for requesting text within a timer
         * 
         * @return always true, no stopping of timer
         */
        private bool request_text_callback()
        {
            request_text();
            return true;
        }
    }
}

