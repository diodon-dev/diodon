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
                get_path_of_active_application();
                
                Zeitgeist.Subject subject = new Zeitgeist.Subject();
                
                subject.set_uri("clipboard://" + item.get_checksum());
                subject.set_interpretation(Zeitgeist.NFO_TEXT_DOCUMENT);
                subject.set_manifestation(Zeitgeist.NFO_DATA_CONTAINER);
                subject.set_mimetype(item.get_mime_type());
                //subject.set_origin("clipboard");
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
            unowned X.Display display = Gdk.x11_get_default_xdisplay();
            
            X.Atom wm_pid = display.intern_atom("_NET_WM_PID", false);
            
            if(wm_pid != X.None) {
            
                X.Window focused_window;
                int revert_to_return;
                display.get_input_focus(out focused_window, out revert_to_return);
                
                X.Atom actual_type_return;
                int actual_format_return;
                ulong nitems_return;
                ulong bytes_after_return;
                void* prop_return = null;
                
                
                int status = display.get_window_property(focused_window, wm_pid, 0, 1024, false,
                    X.XA_CARDINAL, out actual_type_return, out actual_format_return,
                    out nitems_return, out bytes_after_return, out prop_return);
                    
                debug("Focused window %#x", (int)focused_window);
                    
                if(status == X.Success) {
                    debug("Success");
                    if(prop_return != null) {
                        ulong pid = *((ulong*)prop_return);
                        debug("Copied by process with pid %lu", pid);
                    }
                }
            }
            
            return null;
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

