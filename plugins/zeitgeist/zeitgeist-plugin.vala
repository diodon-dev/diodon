/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2012 Diodon Team <diodon-team@lists.launchpad.net>
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

namespace Diodon.Plugins
{
    /**
     * A Zeitgeist data provider for diodon
     *
     * @author Oliver Sauder <os@esite.ch>
     */
    public class ZeitgeistPlugin : Peas.ExtensionBase, Peas.Activatable
    {
        private Zeitgeist.Log log;
        public Object object { get; construct; }

        public ZeitgeistPlugin()
        {
            Object();
        }

        public void activate()
        {
            Controller controller = object as Controller;
           
            if(log == null) {
                log = new Zeitgeist.Log();
            }
            
            controller.on_add_item.connect(add_clipboard_item);
        }

        public void deactivate()
        {
            Controller controller = object as Controller;
            
            controller.on_add_item.disconnect(add_clipboard_item);
        }

        public void update_state()
        {
        }
        
        private void add_clipboard_item(IClipboardItem item)
        {
            if(item is TextClipboardItem) {
            
                debug("Add text item to zeitgeist");
                string? origin = get_path_of_active_application();
                
                Zeitgeist.Subject subject = new Zeitgeist.Subject();
                
                subject.set_uri("clipboard://" + item.get_checksum());
                subject.set_interpretation(Zeitgeist.NFO_TEXT_DOCUMENT);
                subject.set_manifestation(Zeitgeist.NFO_DATA_CONTAINER);
                subject.set_mimetype(item.get_mime_type());
                if(origin != null) {
                    subject.set_origin(origin);
                }
                subject.set_text(item.get_label());
                //subject.set_storage("");
                
                Zeitgeist.Event event = new Zeitgeist.Event();
                //event.set_id(
                event.set_interpretation(Zeitgeist.ZG_CREATE_EVENT);
                event.set_manifestation(Zeitgeist.ZG_USER_ACTIVITY);
                event.set_actor("application://diodon.desktop");
                event.add_subject(subject);
                //event.set_payload();
                
                TimeVal cur_time = TimeVal();
                int64 timestamp = Zeitgeist.Timestamp.from_timeval(cur_time);
                event.set_timestamp(timestamp);
                
                log.insert_events_no_reply(event, null);
            }
        }
        
        private string? get_path_of_active_application()
        {
            X.Window window = get_active_window();
            if(window != X.None) {
                ulong pid = get_pid(window);
                
                if(pid != 0) {
                    File file = File.new_for_path("/proc/" + pid.to_string() + "/exe");
                    try {
                        FileInfo info = file.query_info(FILE_ATTRIBUTE_STANDARD_SYMLINK_TARGET, 
                            FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                        if(info != null) {
                            string path = info.get_attribute_as_string(
                                FILE_ATTRIBUTE_STANDARD_SYMLINK_TARGET);
                            debug("Path is %s", path);
                            return path;
                        }
                    }
                    catch(GLib.Error e) {
                        debug("Error occured while reading %s: %s",
                            file.get_path(), e.message);
                    }
                }
            }
            
            return null;
        }
        
        private X.Window get_active_window()
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
        
        private ulong get_pid(X.Window window)
        {
            unowned X.Display display = Gdk.x11_get_default_xdisplay();
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
                        return pid;
                    }
                }
            }
            
            return 0;
        }
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
  Peas.ObjectModule objmodule = module as Peas.ObjectModule;
  objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (Diodon.Plugins.ZeitgeistPlugin));
}

