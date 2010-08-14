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
     * Represents an immutable item in the clipboard with all its information.
     * 
     * TODO; consider using a interface for a clipboard item to implement
     * the represantation of coping files or buffers.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ClipboardItem : GLib.Object
    {
        private string text;
       
        /**
         * Simple text constrcutor
         * 
         * @param text plain text
         */ 
        public ClipboardItem(string text)
        {
            this.text = text;
        }
    
        /**
         * get plain text
         */
        public string get_text()
        {
            return text;
        }
    }  
}
