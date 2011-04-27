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

namespace Diodon.UnityLens
{
    /* Canonical schema for the results model shared with the Unity shell */
    public enum ResultsColumn
    {
        URI = 0,
        ICON_HINT,
        GROUP_ID,
        MIMETYPE,
        DISPLAY_NAME,
        COMMENT
    }

    /* Canonical schema for the sections model shared with the Unity shell */
    public enum SectionsColumn
    {
        DISPLAY_NAME = 0,
    }

    /* Canonical schema for the groups model shared with the Unity shell */
    public enum GroupsColumn
    {
        RENDERER = 0,
        DISPLAY_NAME,
        ICON_HINT
    }
}

