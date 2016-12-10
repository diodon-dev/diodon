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
 *
 * Author:
 *  Oliver Sauder <os@esite.ch>
 */

namespace Diodon
{
    /**
     * Clipboard item interface to be implemented by various different
     * clipboard item types such as Text,File or Image.
     *
     * TODO
     * interface IClipboardItem should extends Gee.Hashable which currently ends
     * in a compliation error of classes implenting this interface.
     */
    public interface IClipboardItem : GLib.Object
    {
        /**
         * get clipboard type item is coming from
         *
         * @return type of clipboard
         */
        public abstract ClipboardType get_clipboard_type();

        /**
         * label of clipboard item used to show in user interface
         *
         * @return label of item
         */
        public abstract string get_label();

        /**
         * get mime type of given clipboard item
         *
         * @return mime type of item
         */
        public abstract string get_mime_type();

        /**
         * get clipboard category item belongs to
         *
         * @return clipboard category
         */
        public abstract ClipboardCategory get_category();

        /**
         * image to represent content of clipboard item
         *
         * @return image of item or null if not available
         */
        public abstract Gtk.Image? get_image();

        /**
         * icon to represent type of clipboard item
         *
         * @return icon of clipboard type
         */
        public abstract Icon get_icon();

        /**
         * Retrieves any additional data needed to reconstruct clipboard content
         */
        public abstract ByteArray? get_payload() throws GLib.Error;

        /**
         * Date of when clipboard item has been copied
         *
         * @return date
         */
        public abstract DateTime get_date_copied();

        /**
         * A string representing clipboard item.
         *
         * @return data
         */
        public abstract string get_text();

        /**
         * Get unique checksum for clipboard content.
         */
        public abstract string get_checksum();

        /**
         * Get origin resp. path of application which has triggered copy event
         * creating this clipboard item.
         *
         * @return origin as application path if available; otherwise null
         */
        public abstract string? get_origin();

        /**
         * Select the current item in the given gtk clipboard
         *
         * @param clipboard gtk clipboard
         */
        public abstract void to_clipboard(Gtk.Clipboard clipboard);

        /**
         * Check if given item is equal.
         *
         * @return true if equal; otherwise false.
         *
         */
        public abstract bool equals(IClipboardItem *item);

        /**
         * return hash code for implemented clipboard item
         *
         * @return hash code
         *
         */
        public abstract uint hash();

        /**
         * equal func helper comparing two clipboard items.
         *
         * @param item_a item to be compared
         * @param item_b other item to be compared
         *
         * @return true if equal; otherwise false.
         */
        public static bool equal_func(IClipboardItem* item_a, IClipboardItem* item_b)
        {
            return item_a->equals(item_b);
        }

        /**
         * hash func helper creating hash code for clipboard item.
         *
         * @param item item to create hash from
         *
         * @return generated hash code
         */
        public static uint hash_func (IClipboardItem* item)
        {
            return item->hash();
        }
    }
}

