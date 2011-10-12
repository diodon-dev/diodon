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
 
using Gee;

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
    
    public enum ClipboardItemType
    {
        ALL = 0,
        TEXT,
        FILES,
        IMAGES;
        
        public string to_string()
        {
            switch (this) {
                case ALL:
                    return "all";

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
        
        public static ClipboardItemType from_string(string type)
        {
            switch(type) {
                case "all":
                    return ALL;
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
    
    public enum ClipboardCategory
    {
        TEXT,
        FILES,
        IMAGES
    }
}

