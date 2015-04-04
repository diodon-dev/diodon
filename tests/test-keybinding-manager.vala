/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2013 Diodon Team <diodon-team@lists.launchpad.net>
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
     * Testing of TestKeybindingManager functionality
     */
    class TestKeybindingManager : FsoFramework.Test.TestCase
    {
	    public TestKeybindingManager()
	    {
		    base("TestKeybindingManager");
		    add_test("remove_lockmodifiers", test_remove_lockmodifiers);
		    add_test("session_has_key_grabber_unity", test_session_has_key_grabber_unity);
		    add_test("session_has_key_grabber_gnome", test_session_has_key_grabber_gnome);
		    add_test("session_has_key_grabber_xfce", test_session_has_key_grabber_xfce);
		    add_test("session_has_key_grabber_null", test_session_has_key_grabber_null);
	    }

	    public void test_remove_lockmodifiers()
	    {
	        uint ctrl_alt = Gdk.ModifierType.CONTROL_MASK|Gdk.ModifierType.MOD1_MASK;
	        uint ctrl_alt_lockmodifiers = Gdk.ModifierType.CONTROL_MASK|
	            Gdk.ModifierType.MOD1_MASK|Gdk.ModifierType.LOCK_MASK|Gdk.ModifierType.MOD2_MASK|
	            Gdk.ModifierType.MOD5_MASK;
	        
	        uint result = KeybindingManager.remove_lockmodifiers(ctrl_alt_lockmodifiers);
	        
	        assert(result == ctrl_alt);
	    }
	    
	    public void test_session_has_key_grabber_unity()
	    {
	        Environment.set_variable("XDG_CURRENT_DESKTOP", "Unity", true);
	        assert(KeybindingManager.session_has_key_grabber());
	    }
	    
	    public void test_session_has_key_grabber_gnome()
	    {
	        Environment.set_variable("XDG_CURRENT_DESKTOP", "GNOME", true);
	        assert(KeybindingManager.session_has_key_grabber());
	    }
	    
	    public void test_session_has_key_grabber_xfce()
	    {
	        Environment.set_variable("XDG_CURRENT_DESKTOP", "XFCE", true);
	        // XFCE currently doesn't have a key grabber
	        assert(!KeybindingManager.session_has_key_grabber());
	    }
	    
	    public void test_session_has_key_grabber_null()
	    {
	        Environment.unset_variable("XDG_CURRENT_DESKTOP");
	        // if XDG_CURRENT_DESKTOP is not set there is no key grabber
	        assert(!KeybindingManager.session_has_key_grabber());
	    }
	}
}

