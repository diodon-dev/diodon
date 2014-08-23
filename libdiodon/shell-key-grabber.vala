/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2014 Diodon Team <diodon-team@lists.launchpad.net>
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
     * Access to dbus service org.gnome.Shell providing key grabbing methods.
     * At this point this service runs only under Unity and GNOME DE.
     */
    [DBus (name = "org.gnome.Shell")]
    private interface ShellKeyGrabber : GLib.Object
    {
        public abstract uint grab_accelerator(string accelerator, uint flags) throws IOError;
        public abstract bool ungrab_accelerator(uint action) throws IOError;
        public signal void accelerator_activated(uint action, uint device);
    }
}

