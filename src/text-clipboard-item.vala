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
     * Represents a text clipboard item holding simple text.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class TextClipboardItem : GLib.Object, IClipboardItem
    {
        private string _text;
        private ClipboardType _clipboard_type;
       
        /**
         * Default data constructor needed for reflection.
         * 
         * @param type clipboard type item is coming from
         * @param data simple text
         */ 
        public TextClipboardItem(ClipboardType clipboard_type, string data)
        {
            _clipboard_type = clipboard_type;
            _text = data;
        }
    
        /**
	     * {@inheritDoc}
	     */
        public ClipboardType get_clipboard_type()
        {
            return _clipboard_type;
        }
        
        /**
	     * {@inheritDoc}
	     */
	    public string get_clipboard_data()
        {
            return _text;
        }

        /**
	     * {@inheritDoc}
	     */
        public string get_label()
        {
            // label should not be longer than 50 letters
            string label = _text.replace("\n", " ");
            if (label.length > 50) {
                label = label.substring(0, 50) + "...";
            }
            
            return label;
        }
        
        /**
	     * {@inheritDoc}
	     */
        public void to_clipboard(Gtk.Clipboard clipboard)
        {
            clipboard.set_text(_text, -1);
            clipboard.store();
        }
        
                /**
	     * {@inheritDoc}
	     */
	    public void remove()
        {
            // no cleaning up needed
        }
    }  
}
