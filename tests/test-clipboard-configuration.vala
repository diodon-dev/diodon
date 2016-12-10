/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2015 Diodon Team <diodon-team@lists.launchpad.net>
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

using FsoFramework.Test;

namespace Diodon
{
    /**
     * Testing of TestClipboardConfiguration functionality
     */
    class TestClipboardConfiguration : FsoFramework.Test.TestCase
    {
        private ClipboardConfiguration configuration;

	    public TestClipboardConfiguration()
	    {
		    base("TestClipboardConfiguration");
		    add_test("test_lookup_app_paste_keybinding", test_lookup_app_paste_keybinding);
	    }

	    public override void set_up()
	    {
	        this.configuration = new ClipboardConfiguration();
	        this.configuration.app_paste_keybindings = new string[2];
	        this.configuration.app_paste_keybindings[0] = "/some/invalid/pattern";
	        this.configuration.app_paste_keybindings[1] = "/usr/bin/gnome-terminal|<Ctrl><Shift>v";
        }

	    public void test_lookup_app_paste_keybinding() throws GLib.Error
	    {
	        string? key = configuration.lookup_app_paste_keybinding(null);
	        assert(key==null);

	        key = configuration.lookup_app_paste_keybinding("/path/not/available");
	        assert(key==null);

	        key = configuration.lookup_app_paste_keybinding("/usr/bin/gnome-terminal");
	        Assert.are_equal_string(key, "<Ctrl><Shift>v", "Invalid keybinding");

	        uint keyacc;
	        Gdk.ModifierType mods;
	        Gtk.accelerator_parse("<Shift><Ctrl>V", out keyacc, out mods);
	        assert(mods != 0);
	    }
	}
}

