/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010-2014 Diodon Team <diodon-team@lists.launchpad.net>
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
     * This class is in charge to grab keybindings first trying to use
     * ShellKeyGrabber to do so. As ShellKeyGrabber is at this point only available
     * on Unity and GNOME is a legacy mode for X11 still implemented.
     */
    public class KeybindingManager : GLib.Object
    {
        private ShellKeyGrabber key_grabber;
        private uint shell_owner_id = 0;
        
        /**
         * list of binded keybindings
         */
        private Gee.List<Keybinding> bindings = new Gee.ArrayList<Keybinding>();
        private Gee.List<Keybinding> unregistered_bindings = new Gee.ArrayList<Keybinding>();
        
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
            
            public Keybinding.with_action(string accelerator, uint action, KeybindingHandlerFunc handler)
            {
                this.accelerator = accelerator;
                this.action = action;
                this.handler = handler;
            }
        
            public string accelerator { get; set; }
            public int keycode { get; set; }
            public Gdk.ModifierType modifiers { get; set; }
            public uint action { get; set; }
            public unowned KeybindingHandlerFunc handler { get; set; }
        }
        
        /**
         * Keybinding func needed to bind key to handler
         * 
         * @param event passing on gdk event
         */
        public delegate void KeybindingHandlerFunc();
    
        public void init()
        {
            if(session_has_key_grabber()) {
                shell_owner_id = Bus.watch_name(BusType.SESSION, "org.gnome.Shell",
                    BusNameWatcherFlags.NONE, on_shell_appeared, on_shell_vanished);
            } else {
                debug("Falling back to legacy keybinder");
                
                // at this point only GNOME and Unity support the ShellKeyGrabber
                // so we have to remain with legacy X11 code for now for all
                // other DEs
                Gdk.Window rootwin = Gdk.get_default_root_window();
                if(rootwin != null) {
                    rootwin.add_filter(event_filter_legacy);
                }
            }
        }
        
        private void on_shell_appeared(GLib.DBusConnection connection, string name, string name_owner)
        {
            debug("Key grabber shell %s has appeared", name);
            // we just want to make sure that we really have a key grabber available
            if(session_has_key_grabber()) {
                
                try {
                    key_grabber = Bus.get_proxy_sync(BusType.SESSION, name, "/org/gnome/Shell");
                    key_grabber.accelerator_activated.connect(on_accelerator_activated);
                    
                    foreach(Keybinding binding in unregistered_bindings)
                    {
                        debug("Process unregistered binding %s", binding.accelerator);
                        bind_key_grabber(binding);
                    }
                    
                    unregistered_bindings.clear();
                } catch(IOError e) {
                    warning("Get ShellKeyGrabber proxy failed with error %s", e.message);
                }
            }
        }
        
        private void on_shell_vanished(GLib.DBusConnection connection, string name)
        {
            debug("Key grabber shell %s has vanished", name);
            
            if(session_has_key_grabber()) {
                unregistered_bindings.add_all(bindings);
                bindings.clear();
            }
            
            key_grabber = null;
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
            
            if(session_has_key_grabber()) {
                Keybinding binding = new Keybinding.with_action(accelerator, 0, handler);
                if(!bind_key_grabber(binding))
                {
                    debug("Key grabber is not ready yet to bind %s", accelerator);
                    unregistered_bindings.add(binding);
                }
            } else {
                bind_legacy(accelerator, handler);
            }
        }
        
        private bool bind_key_grabber(Keybinding binding)
        {
            try {
                if(key_grabber != null) {
                    uint action = key_grabber.grab_accelerator(binding.accelerator, 0);
                    debug("Key %s binded to action id %u", binding.accelerator, binding.action);
                    binding.action = action;
                    bindings.add(binding);
                    return true;
                }
            } catch(IOError e) {
                warning("Binding of accelerator %s failed with error %s",
                    binding.accelerator, e.message);
            }
            
            return false;
        }
        
        /**
         * Legacy X11 mod to bind accelerator
         *
         * @param accelerator accelerator parsable by Gtk.accelerator_parse
         * @param handler handler called when given accelerator is pressed
         */
        private void bind_legacy(string accelerator, KeybindingHandlerFunc handler)
        {
            // convert accelerator
            uint keysym;
            Gdk.ModifierType modifiers;
            Gtk.accelerator_parse(accelerator, out keysym, out modifiers);

            unowned X.Display display = Gdk.x11_get_default_xdisplay();
            int keycode = display.keysym_to_keycode(keysym);
                     
            if(keycode != 0) {
                X.Window root_window = Gdk.x11_get_default_root_xwindow();
                
                // trap XErrors to avoid closing of application
                // even when grabing of key fails
                Gdk.error_trap_push();

                // grab key finally
                // also grab all keys which are combined with a lock key such NumLock
                foreach(uint lock_modifier in lock_modifiers) {     
                    display.grab_key(keycode, modifiers|lock_modifier, root_window, false,
                        X.GrabMode.Async, X.GrabMode.Async);
                }
                
                // wait until all X request have been processed
                Gdk.flush();
                Gdk.error_trap_pop_ignored();
                
                // store binding
                Keybinding binding = new Keybinding(accelerator, keycode, modifiers, handler);
                bindings.add(binding);
                
                debug("Successfully binded key %s in legacy mode.", accelerator);
            }
        }
        
        /**
         * Unbind given accelerator.
         *
         * @param accelerator accelerator parsable by Gtk.accelerator_parse
         */
        public void unbind(string accelerator) throws IOError
        {
            debug("Unbinding key " + accelerator);
            
            if(session_has_key_grabber()) {
                // unbind all keys with given accelerator
                Gee.List<Keybinding> remove_bindings = new Gee.ArrayList<Keybinding>();
                foreach(Keybinding binding in bindings) {
                    if(strcmp(accelerator, binding.accelerator) == 0) {
                        // if key grabber is not available, unbinding has already been done
                        bool unbind_successful = true;
                        if(key_grabber != null) {
                            unbind_successful = key_grabber.ungrab_accelerator(binding.action);
                        }
                        
                        if(unbind_successful) {
                            debug("Unbinding key %s successful", accelerator);
                            remove_bindings.add(binding);
                        }
                    }
                }
                // remove unbinded keys
                bindings.remove_all(remove_bindings);   

                // remove all unregistered binding with given accelerator as well                
                remove_bindings.clear();             
                foreach(Keybinding binding in unregistered_bindings) {
                    if(strcmp(accelerator, binding.accelerator) == 0) {
                        remove_bindings.add(binding);
                    }
                }
                unregistered_bindings.remove_all(remove_bindings);
            } else {
                unbind_legacy(accelerator);
            }
        }
        
        public override void dispose()
        {
            if(key_grabber != null) {
                foreach(Keybinding binding in bindings) {
                    debug("Unbinding key %s", binding.accelerator);
                    try {
                        key_grabber.ungrab_accelerator(binding.action);
                    } catch(IOError e) {
                        debug("During clean up unbinding key failed: %s", e.message);
                    }
                }
                
                bindings.clear();
            }
            
            if(shell_owner_id > 0) {
                Bus.unwatch_name(shell_owner_id);
            }
            
            base.dispose();
        }
        
        /**
         * Legacy X11 mode to unbind accelerator
         *
         * @param accelerator accelerator parsable by Gtk.accelerator_parse
         */
        private void unbind_legacy(string accelerator)
        {
            unowned X.Display display = Gdk.x11_get_default_xdisplay();
            X.Window root_window = Gdk.x11_get_default_root_xwindow();
            
            // trap XErrors to avoid closing of application
            // even when grabing of key fails
            Gdk.error_trap_push();
            
            // unbind all keys with given accelerator
            Gee.List<Keybinding> remove_bindings = new Gee.ArrayList<Keybinding>();
            foreach(Keybinding binding in bindings) {
                if(strcmp(accelerator, binding.accelerator) == 0) {
                    foreach(uint lock_modifier in lock_modifiers) {
                        display.ungrab_key(binding.keycode, binding.modifiers, root_window);
                    }
                    debug("Unbinding key %s successful in legacy mode", accelerator);
                    remove_bindings.add(binding);
                }
            }
            
            // wait until all X request have been processed
            Gdk.flush();
            Gdk.error_trap_pop_ignored();
            
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
            if(perform_key_event(accelerator, true, 100)) {
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
            if(perform_key_event(accelerator, false, 0)) {
                debug("Successfully released key " + accelerator);
            }
        }
        
        /**
         * Remove lock modifiers (NumLock, CapsLock, ScrollLock) from
         * key state
         *
         * @param state key state of a gdk event
         */
        public static uint remove_lockmodifiers(uint state)
        {
            return state & ~ (Gdk.ModifierType.MOD2_MASK|Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD5_MASK);
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
        private bool perform_key_event(string accelerator, bool press, ulong delay)
        {
            // convert accelerator
            uint keysym;
            Gdk.ModifierType modifiers;
            Gtk.accelerator_parse(accelerator, out keysym, out modifiers);
            unowned X.Display display = Gdk.x11_get_default_xdisplay();
            int keycode = display.keysym_to_keycode(keysym);
            
            // FIXME: there must be an easier way
            int modifierykey = 0;
            switch(modifiers) {
                case Gdk.ModifierType.CONTROL_MASK:
                    // currently missing in the gdk binding
                    //modifierykey = Gdk.Key.Control_L;
                    modifierykey = 0xffe3;
                    break;
                case Gdk.ModifierType.SHIFT_MASK:
                    // currently missing in the gdk binding
                    //modifierykey = Gdk.Key.Shift_L;
                    modifierykey = 0xffe1;
                    break;
            }
            int modifiercode = display.keysym_to_keycode(modifierykey);
            
            if(keycode != 0) {
                
                if(modifiercode != 0) {
                    XTest.fake_key_event(display, modifiercode, press, delay);                
                }
                
                XTest.fake_key_event(display, keycode, press, delay);                
                
                return true;
            }
            
            return false;
        }
        
        /**
         * Check whether current session as shell key grabber. Such is currently
         * only supported in Gnome and Unity.
         */
        public static bool session_has_key_grabber()
        {
            unowned string desktop = Environment.get_variable("XDG_CURRENT_DESKTOP");
            debug("Current desktop: %s", desktop);
            
            return (desktop != null) && (strcmp(desktop.down(), "unity") == 0 || strcmp(desktop.down(), "gnome") == 0);
        }
        
        /**
         * Triggered when ShellKeyGrabber detected pressed accelerator
         */
        private void on_accelerator_activated(uint action, uint device)
        {
            foreach(Keybinding binding in bindings) {
                if(binding.action == action) {
                    debug("Keybinding hit with action id %u and accelerator %s",
                        action, binding.accelerator);
                    binding.handler();
                }
            }
        }
        
        /**
         * Event filter method needed to fetch X.Events in legacy mode
         */
        private Gdk.FilterReturn event_filter_legacy(Gdk.XEvent gdk_xevent, Gdk.Event gdk_event)
        {
            X.Event* xevent = (X.Event*) gdk_xevent;
            
            // ungrab keyboard device so no more events are passed on
            // and interrupt following events till keyboard is grabbed again
            unowned Gdk.Display display = Gdk.Display.get_default();
            unowned Gdk.DeviceManager dm = display.get_device_manager();
            foreach(Gdk.Device device in dm.list_devices(Gdk.DeviceType.MASTER)) {
                if(device.get_source() == Gdk.InputSource.KEYBOARD) {
                    device.ungrab(Gtk.get_current_event_time());
                }
            }
            
            Gdk.flush();
            
            if(xevent->type == X.EventType.KeyPress) {
                debug("Key pressed, keycode: %u, modifiers: %u",
                    xevent->xkey.keycode, xevent->xkey.state);
                    
                foreach(Keybinding binding in bindings) {
                    uint event_mods = remove_lockmodifiers(xevent.xkey.state);
                    if(xevent->xkey.keycode == binding.keycode && event_mods == binding.modifiers) {
                        debug("Keybinding hit with accelerator %s",
                            binding.accelerator);
                        
                        // call all handlers with pressed key and modifiers
                        // execute handler in main loop
                        // to avoid dead lock
                        Timeout.add(100, () => {
                            binding.handler();
                            return false; // stop timer
                        });
                        
                        return Gdk.FilterReturn.REMOVE;
                    }
                }
            }
             
            return Gdk.FilterReturn.CONTINUE;
        }
    }
}

