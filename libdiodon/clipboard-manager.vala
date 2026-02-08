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
 *
 * Author:
 *  Oliver Sauder <os@esite.ch>
 */

namespace Diodon
{
    /**
     * This class is in charge of retrieving information from
     * the encapsulated gnome clipboard and passing on such to the processes connected
     * to the given signals.
     */
    class ClipboardManager : GLib.Object
    {
        protected ClipboardType type;
        protected Gtk.Clipboard _clipboard = null;
        protected ClipboardConfiguration _configuration;

        /**
         * Called when text from the clipboard has been received
         *
         * @param type type of clipboard text belongs to
         * @param text received text from clipboard which is never null or empty
         */
        public signal void on_text_received(ClipboardType type, string text, string? origin);

        /**
         * Called when uris have been received from clipboard.
         * The given paths are not uris appended with file://
         * but just full paths.
         *
         * @param type type of clipboard uris belong to
         * @param paths paths separated with /n.
         */
        public signal void on_uris_received(ClipboardType type, string paths, string? origin);

        /**
         * Called when a image has been received from the clipboard.
         *
         * @param type type of clipboard image belongs to
         * @param pixbuf image as a pixbuf object
         */
        public signal void on_image_received(ClipboardType type, Gdk.Pixbuf pixbuf, string? origin);

        /**
         * Called when the clipboard is empty
         *
         * @param type type of clipboard which is empty
         */
        public signal void on_empty(ClipboardType type);

        /**
         * get type of given clipboard manager
         */
        public ClipboardType clipboard_type { get { return type; } }

        /**
         * Constructor
         *
         * @param clipboard clipboard to be managed
         * @param configuration access to clipboard configuration
         * @param type of clipboard
         */
        public ClipboardManager(ClipboardType type, ClipboardConfiguration configuration)
        {
            // TODO: might consider this block to be replaced with a HashMap
            if(type == ClipboardType.CLIPBOARD) {
                _clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD);
            } else if(type == ClipboardType.PRIMARY) {
                _clipboard = Gtk.Clipboard.get(Gdk.SELECTION_PRIMARY);
            }

            this.type = type;
            this._configuration = configuration;
        }

        /**
         * Starts the process requesting data from encapsulated clipboard.
         * The owner has to change when new data is set in the clipboard
         * therefore just connecting to owner_change will do the trick.
         */
        public virtual void start()
        {
            _clipboard.owner_change.connect(check_clipboard);
        }

        /**
         * Stop the process requesting data from encapsulated clipboard.
         */
        public virtual void stop()
        {
            _clipboard.owner_change.disconnect(check_clipboard);
        }

        /**
         * Select item in the managed clipboard.
         *
         * @param item item to be selected
         */
        public virtual void select_item(IClipboardItem item)
        {
            item.to_clipboard(_clipboard);
        }

        /**
         * Clear managed clipboard.
         *
         * Releases Diodon's clipboard ownership first (triggering
         * clipboard_clear_func which nulls _pixbuf), then sets empty
         * text. This prevents the "Zombie Clipboard" bug where
         * Ctrl+V after Clear History could still paste sensitive data
         * from a lingering pixbuf reference.
         */
        public void clear()
        {
            // Release ownership — triggers clipboard_clear_func on the
            // current owner (ImageClipboardItem), nulling its _pixbuf.
            // This is safe to call even if Diodon doesn't own the clipboard.
            _clipboard.clear();

            // Set empty text so the clipboard isn't completely blank
            // (some apps crash on truly empty selections).
            _clipboard.set_text("", -1);
        }

        /**
         * Request text from managed clipboard. If result is valid
         * on_text_received will be called.
         */
        protected virtual void check_clipboard()
        {
            // === Ownership Check (self-loop detection) ===
            // When Diodon sets the clipboard via set_with_owner(),
            // the owner_change signal fires back. Instead of reading
            // the clipboard data and hashing pixels (expensive!),
            // we check if WE still own the clipboard. If so, this is
            // our own feedback loop — skip immediately.
            //
            // get_owner() returns the GObject passed to set_with_owner().
            // For ImageClipboardItem: returns the item instance.
            // For text (set_text): returns null (no ownership tracking).
            // When another app takes ownership: GTK clears the owner.
            GLib.Object? owner = _clipboard.get_owner();
            if (owner != null && owner is IClipboardItem) {
                debug("Clipboard owned by Diodon (%s), skipping self-feedback",
                      owner.get_type().name());
                return;
            }

            // on java applications such as jEdit wait_is_text_available returns
            // false even when some text is available
            string? text = request_text();
            bool text_available = (text != null && text != "") || _clipboard.wait_is_text_available();
            bool image_available = _configuration.add_images && _clipboard.wait_is_image_available();
            bool uris_available = _clipboard.wait_is_uris_available();

            // checking if any content known is available
            if(text_available || image_available || uris_available) {
                string? origin = Utility.get_path_of_active_application();

                // checking for uris
                if(text_available) {
                    // check if text is valid
                    if(text != null && text != "") {
                        if(uris_available) {
                            on_uris_received(type, text, origin);
                         }
                         else {
                            on_text_received(type, text, origin);
                         }
                    }
                }
                // checking for image
                else if(image_available) {
                    Gdk.Pixbuf? pixbuf = request_image();
                    if(pixbuf != null) {
                        on_image_received(type, pixbuf, origin);
                    }
                }
            }
            // checking if clipboard might be empty
            else {
                check_clipboard_emptiness();
            }
        }

        /**
         * Request image from clipboard and return it
         *
         * @return returns requested image from clipboard
         */
        protected Gdk.Pixbuf? request_image()
        {
            Gdk.Pixbuf? result = _clipboard.wait_for_image();
            return result;
        }

        /**
         * request text from clipboard and return it
         *
         * @return returns text available in clipboard
         */
        protected string? request_text()
        {
            string? result = _clipboard.wait_for_text();
            return result;
        }

        /**
         * Check if clipboard content has been lost.
         */
        protected void check_clipboard_emptiness()
        {
            Gdk.Atom[] targets = null;
            if(!_clipboard.wait_for_targets(out targets)) {
                on_empty(type);
            }
        }
    }
}

