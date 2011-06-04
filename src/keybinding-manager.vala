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
         * locked modifiers used to grab all keys whatever lock key
         * is pressed.
         */
        private static uint[] lock_modifiers = {
            0,
            Gdk.ModifierType.MOD2_MASK, // NUM_LOCK
            Gdk.ModifierType.LOCK_MASK, // CAPS_LOCK
            Gdk.ModifierType.MOD5_MASK, // SCROLL_LOCK
            Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK,
            Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.MOD5_MASK,
            Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK,
            Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK
        };
        
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
            unowned X.Display display = Gdk.x11_drawable_get_xdisplay(rootwin);
            X.ID xid = Gdk.x11_drawable_get_xid(rootwin);
            int keycode = display.keysym_to_keycode(keysym);            
                     
            if(keycode != 0) {
                // trap XErrors to avoid closing of application
                // even when grabing of key fails
                Gdk.error_trap_push();

                // grab key finally
                // also grab all keys which are combined with a lock key such NumLock
                foreach(uint lock_modifier in lock_modifiers) {     
                    display.grab_key(keycode, modifiers|lock_modifier, xid, false,
                        X.GrabMode.Async, X.GrabMode.Async);
                }
                
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
            
            Gdk.Window rootwin = Gdk.get_default_root_window();     
            unowned X.Display display = Gdk.x11_drawable_get_xdisplay(rootwin);
            X.ID xid = Gdk.x11_drawable_get_xid(rootwin);
            
            // unbind all keys with given accelerator
            Gee.List<Keybinding> remove_bindings = new Gee.ArrayList<Keybinding>();
            foreach(Keybinding binding in bindings) {
                if(str_equal(accelerator, binding.accelerator)) {
                    foreach(uint lock_modifier in lock_modifiers) {
                        display.ungrab_key(binding.keycode, binding.modifiers, xid);
                    }
                    remove_bindings.add(binding);                    
                }
            }
            
            // remove unbinded keys
            bindings.remove_all(remove_bindings);
        }
        
        /**
         * Press given accelerator on current display on the window which
         * has focus at the time given.
         *
         * @param accelerator accelerator parsable by Gtk.accelerator_parse
         */
        public void press(string accelerator)
        {
            X.KeyEvent key_event = X.KeyEvent();
            if(create_key_event(accelerator, X.EventType.KeyPress, out key_event)) {
                X.Event event = (X.Event)key_event;
                key_event.display.send_event(key_event.window, false,
                    X.EventMask.KeyPressMask, ref event);
                
                debug("Successfully pressed key " + accelerator);
            }
        }
        
        /**
         * Release given accelerator on current display on the window which
         * has focus at the time given.
         *
         * @param accelerator accelerator parsable by Gtk.accelerator_parse
         */
        public void release(string accelerator)
        {
            X.KeyEvent key_event = X.KeyEvent();
            if(create_key_event(accelerator, X.EventType.KeyRelease, out key_event)) {
                X.Event event = (X.Event)key_event;
                key_event.display.send_event(key_event.window, false,
                    X.EventMask.KeyReleaseMask, ref event);
                
                debug("Successfully released key " + accelerator);
            }
        }
        
        /**
         * Helper method create key event for pressing and releasing a
         * key on current x display and window which has currently
         * the focus
         *
         * @param accelerator accelerator parsable by Gtk.accelerator_parse
         * @param event_type an event type of enum EventType
         * @param key_event out param for created key event
         * @return true if creation was successful; otherwise false.
         */
        private bool create_key_event(string accelerator, int event_type, out X.KeyEvent key_event)
        {
            // convert accelerator
            uint keysym;
            Gdk.ModifierType modifiers;
            Gtk.accelerator_parse(accelerator, out keysym, out modifiers);
            Gdk.Window rootwin = Gdk.get_default_root_window();
            unowned X.Display display = Gdk.x11_drawable_get_xdisplay(rootwin);
            
            int keycode = display.keysym_to_keycode(keysym);
            
            if(keycode != 0) {
                X.Window root_window = Gdk.x11_get_default_root_xwindow();
                
                // get window with focus
                X.Window focus;
                int revert_to_return;
                display.get_input_focus(out focus, out revert_to_return);
                
                key_event.display = display;
                key_event.root = root_window;
                key_event.window = focus;
                key_event.subwindow = X.None;
                key_event.time = X.CURRENT_TIME;
                key_event.keycode = keycode;
                key_event.state = modifiers;
                key_event.type = event_type;
                key_event.x = 1;
                key_event.y = 1;
                key_event.x_root = 1;
                key_event.y_root = 1;
                
                return true;
            }
            
            return false;
        }
        
        /**
         * Event filter method needed to fetch X.Events
         */
        private Gdk.FilterReturn event_filter(Gdk.XEvent gdk_xevent, Gdk.Event gdk_event)
        {
            Gdk.FilterReturn filter_return = Gdk.FilterReturn.CONTINUE;
                       
            void* pointer = &gdk_xevent;
            X.Event* xevent = (X.Event*) pointer;
             
             if(xevent->type == X.EventType.KeyPress) {
                foreach(Keybinding binding in bindings) {
                    // remove NumLock, CapsLock and ScrollLock from key state
                    uint event_mods = xevent.xkey.state & ~ (lock_modifiers[7]);
                    if(xevent->xkey.keycode == binding.keycode && event_mods == binding.modifiers) {
                        // call all handlers with pressed key and modifiers
                        binding.handler(gdk_event);
                    }
                }
             }
             
            return filter_return;
        }
    }
}

