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
 *
 * Author:
 *  Oliver Sauder <os@esite.ch>
 */

namespace Diodon
{
    public enum ClipboardType
    {
        /**
         * e.g when item is coming from storage
         */
        NONE,

        /**
         * normal clipboard
         */
        CLIPBOARD,

        /**
         * primary selection clipboard
         */
        PRIMARY;
    }

    public enum ClipboardCategory
    {
        // resp. all items
        CLIPBOARD = 0,
        TEXT,
        FILES,
        IMAGES;

        public static ClipboardCategory[] all()
        {
            // all categories excluding clipboard as it is a placeholder for all
            return { TEXT, FILES, IMAGES };
        }

        public string to_string()
        {
            switch (this) {
                case CLIPBOARD:
                    return "clipboard";

                case TEXT:
                    return "text";

                case FILES:
                    return "files";

                case IMAGES:
                    return "images";

                default:
                    assert_not_reached();
            }
        }

        public static ClipboardCategory from_string(string type)
        {
            switch(type) {
                case "clipboard":
                    return CLIPBOARD;
                case "text":
                    return TEXT;
                case "files":
                    return FILES;
                case "images":
                     return IMAGES;
                default:
                    assert_not_reached();
            }
        }
    }

    /**
     * Clipboard time range to filter results according to when it has been copied
     */
    public enum ClipboardTimerange
    {
        ALL = 0,
        LAST_24_HOURS,
        LAST_7_DAYS,
        LAST_30_DAYS,
        LAST_YEAR;

        public static ClipboardTimerange[] all()
        {
            // all time ranges excluding all as it represents all
            return { LAST_24_HOURS, LAST_7_DAYS, LAST_30_DAYS, LAST_YEAR };
        }

        public string to_string()
        {
            switch (this) {
                case ALL:
                    return "all";

                case LAST_24_HOURS:
                    return "last-24-hours";

                case LAST_7_DAYS:
                    return "last-7-days";

                case LAST_30_DAYS:
                    return "last-30-days";

                case LAST_YEAR:
                    return "last-year";

                default:
                    assert_not_reached();
            }
        }

        public static ClipboardTimerange from_string(string type)
        {
            switch(type) {
                case "all":
                    return ALL;
                case "last-24-hours":
                    return LAST_24_HOURS;
                case "last-7-days":
                    return LAST_7_DAYS;
                case "last-30-days":
                    return LAST_30_DAYS;
                case "last-year":
                     return LAST_YEAR;
                default:
                    assert_not_reached();
            }
        }
    }
}

