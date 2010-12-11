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

namespace Diodon
{
    /**
     * This class is in charge to grab keybindings on the X11 display
     * and filter X11-events and passing on such events to the registed
     * handler methods.
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class KeybindingManager : GLib.Object
    {
        /**
         * list of binded keybindings
         */
        private Gee.List<Keybinding> bindings = new Gee.ArrayList<Keybinding>();
        
        /**
         * Helper class to store keybinding
         */
        private class Keybinding
        {
            public Keybinding(string accelerator, int keycode,
                Gdk.ModifierType modifiers, KeybindingHandlerFunc handler)
            {
                this.accelerator = accelerator;
                this.keycode = keycode;
                this.modifiers = modifiers;
                this.handler = handler;
            }
        
            public string accelerator { get; set; }
            public int keycode { get; set; }
            public Gdk.ModifierType modifiers { get; set; }
            public KeybindingHandlerFunc handler { get; set; }
        }
        
        /**
         * Keybinding func needed to bind key to handler
         * 
         * @param event passing on gdk event
         */
        public delegate void KeybindingHandlerFunc(Gdk.Event event);
    
        /**
         * initialize keybinding
         */
        public void init()
        {
            // must be called before opening a display
            // or calling any other Xlib function
            X.init_threads();
            
            // init filter to retrieve X.Events
            Gdk.Window rootwin = Gdk.get_default_root_window();
            if(rootwin != null) {
                rootwin.add_filter(event_filter);
            }
        }
        
        /**
         * Bind accelerator to given handler
         *
         * @param accelerator accelerator parsable by Gtk.accelerator_parse
         * @param handler handler called when given accelerator is pressed
         */
        public void bind(string accelerator, KeybindingHandlerFunc handler)
        {
            debug("Binding key " + accelerator);
            
            // convert accelerator
            uint keysym;
            Gdk.ModifierType modifiers;
            Gtk.accelerator_parse(accelerator, out keysym, out modifiers);

            Gdk.Window rootwin = Gdk.get_default_root_window();     
            X.Display display = Gdk.x11_drawable_get_xdisplay(rootwin);
            X.ID xid = Gdk.x11_drawable_get_xid(rootwin);
            int keycode = display.keysym_to_keycode(keysym);            
                     
            if(keycode != 0) {
                // trap XErrors to avoid closing of application
                // even when grabing of key fails
                Gdk.error_trap_push();

                // grab key finally                
                display.grab_key(keycode, modifiers, xid, false, X.GrabMode.Async, X.GrabMode.Async);
                
                // wait until all X request have been processed
                Gdk.flush();
                
                // store binding
                Keybinding binding = new Keybinding(accelerator, keycode, modifiers, handler);
                bindings.add(binding);
                
                debug("Successfully binded key " + accelerator);
            }
        }
        
        /**
         * Unbind given accelerator.
         *
         * @param accelerator accelerator parsable by Gtk.accelerator_parse
         */
        public void unbind(string accelerator)
        {
            debug("Unbinding key " + accelerator);
            
            
        }
        
        /**
         * Event filter method needed to fetch X.Events
         */
        public Gdk.FilterReturn event_filter(Gdk.XEvent gdk_xevent, Gdk.Event gdk_event)
        {
            Gdk.FilterReturn filter_return = Gdk.FilterReturn.CONTINUE;
                       
            void* pointer = &gdk_xevent;
            X.Event* xevent = (X.Event*) pointer;
             
             if(xevent->type == X.EventType.KeyPress) {
                foreach(Keybinding binding in bindings) {
                    if(xevent->xkey.keycode == binding.keycode && xevent.xkey.state == binding.modifiers) {
                        // call all handlers with pressed key and modifiers
                        binding.handler(gdk_event);
                    }
                }
             }
             
            return filter_return;
        }
    }
}

