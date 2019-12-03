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
     * Class for defining utility methods to be used in any part of diodon.
     */
    public abstract class Utility : GLib.Object
    {
        /**
         * Get diodon user data dir.
         *
         * @return path to diodon user data dir
         */
        public static string get_user_data_dir()
        {
            return Path.build_filename(Environment.get_user_data_dir(), Config.PACKAGE);
        }

        /**
         * Create directory with all its parents logging error if not successful.
         * Checks first if directory already exists.
         *
         * @param directory directory to be created
         * @return returns true if directory already exists or creation was successful
         */
        public static bool make_directory_with_parents(string directory)
        {
            bool result = true;

            // make sure that all parent directories exist
            try {
                File dir = File.new_for_path(directory);
                if(!dir.query_exists(null)) {
                    result = dir.make_directory_with_parents(null);
                }
            } catch (Error e) {
                warning ("could not create directory %s", directory);
                result = false;
            }

            return result;
        }

        /**
         * Get executable path of application which is currently running.
         *
         * @return path of currently active application or null if not possible to determine
         */
        public static string? get_path_of_active_application()
        {
            Gdk.error_trap_push();
            string? path = null;

            X.Window window = get_active_window();
            if(window != X.None) {
                ulong pid = get_pid(window);

                if(pid != 0) {
                    File file = File.new_for_path("/proc/" + pid.to_string() + "/exe");
                    try {
                        FileInfo info = file.query_info(FileAttribute.STANDARD_SYMLINK_TARGET,
                            FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                        if(info != null) {
                            path = info.get_attribute_as_string(
                                FileAttribute.STANDARD_SYMLINK_TARGET);
                            if(path == null) {
                                // in case we do not have permission to read exe, we try to parse cmdline
                                File cmdline = File.new_for_path("/proc/" + pid.to_string() + "/cmdline");
                                if (file.query_exists()) {
                                    DataInputStream cmdline_data = new DataInputStream(cmdline.read());
                                    string cmd = cmdline_data.read_line();
                                    if(cmd != null) {
                                        path = Environment.find_program_in_path(cmd);
                                    }
                                }
                            }
                            debug("Path is %s", path);
                        }
                    }
                    catch(GLib.Error e) {
                        debug("Error occurred while reading %s: %s",
                            file.get_path(), e.message);
                    }
                }
            }

            Gdk.error_trap_pop_ignored();
            return path;
        }

        /**
         * Helper method performing given accelerator on current active
         * window.
         *
         * @param accelerator accelerator parsable by Gtk.accelerator_parse
         * @param press true for press key; false for releasing
         * @param delay delay in milli seconds
         * @return true if creation was successful; otherwise false.
         */
        public static bool perform_key_event(string accelerator, bool press, ulong delay)
        {
            // convert accelerator
            uint keysym;
            Gdk.ModifierType modifiers;
            Gtk.accelerator_parse(accelerator, out keysym, out modifiers);
            unowned X.Display display = Gdk.X11.get_default_xdisplay();
            int keycode = display.keysym_to_keycode(keysym);

            if(keycode != 0) {

                if(Gdk.ModifierType.CONTROL_MASK in modifiers) {
                    int modcode = display.keysym_to_keycode(Gdk.Key.Control_L);
                    XTest.fake_key_event(display, modcode, press, delay);
                }
                if(Gdk.ModifierType.SHIFT_MASK in modifiers) {
                    int modcode = display.keysym_to_keycode(Gdk.Key.Shift_L);
                    XTest.fake_key_event(display, modcode, press, delay);
                }

                XTest.fake_key_event(display, keycode, press, delay);

                return true;
            }

            return false;
        }

        private static X.Window get_active_window()
        {
            unowned Gdk.Screen screen = Gdk.Screen.get_default();
            Gdk.Window active_window = screen.get_active_window();
            if(active_window != null) {
                X.Window xactive_window = Gdk.X11Window.get_xid(active_window);
                debug("Active window %#x", (int)xactive_window);
                return xactive_window;
            }

            return X.None;
        }

        private static ulong get_pid(X.Window window)
        {
            unowned X.Display display = Gdk.X11.get_default_xdisplay();
            X.Atom wm_pid = display.intern_atom("_NET_WM_PID", false);

            if(wm_pid != X.None) {
                X.Atom actual_type_return;
                int actual_format_return;
                ulong nitems_return;
                ulong bytes_after_return;
                void* prop_return = null;

                int status = display.get_window_property(window, wm_pid, 0,
                    long.MAX, false, 0, out actual_type_return, out actual_format_return,
                    out nitems_return, out bytes_after_return, out prop_return);

                if(status == X.Success) {
                    if(prop_return != null) {
                        ulong pid = *((ulong*)prop_return);
                        debug("Copied by process with pid %lu", pid);
                        X.free(prop_return);
                        return pid;
                    }
                }
            }

            return 0;
        }
    }
}

