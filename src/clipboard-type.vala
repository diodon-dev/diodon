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
 
using Gee;

namespace Diodon
{
    /**
     * This enum is a list of different clipboard types.
     *
     * @author Oliver Sauder <os@esite.ch>
     */
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
}

