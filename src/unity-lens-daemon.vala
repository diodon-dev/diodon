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
    public class Daemon : GLib.Object, Unity.Activation
    {
        private Unity.PlaceController controller;
        private Unity.PlaceEntryInfo place_entry;
        
        /**
         * Create all the models needed to share with the Unity shell.
         * The model column schemas must align with what is defined in
         * unity-lens-schemas.vala
         */
        public Daemon()
        {
        }
        
        /**
         * Override of the default activation handler. Unity will ask the
         * place daemon for activation of the URI pattern and mime type pattern
         * defined in the .place file.
         *
         * This method should return a member of the enumeration
         * Unity.ActivationStatus:
         *
         * - ActivationStatus.ACTIVATED_HIDE_DASH
         * - ActivationStatus.ACTIVATED_SHOW_DASH
         * - ActivationStatus.NOT_ACTIVATED
         *
         */
        public async uint32 activate (string uri)
        {
          debug ("Requested activation of: %s", uri);
          return Unity.ActivationStatus.NOT_ACTIVATED;
        }
    }
}

