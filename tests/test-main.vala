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
 *
 * Author:
 *  Oliver Sauder <os@esite.ch>
 */
 
namespace Diodon
{
    public static int main(string[] args)
    {
        Test.init(ref args);
        Gtk.init(ref args);
        
	    TestSuite.get_root().add_suite(new TestTextClipboardItem().get_suite());
	    TestSuite.get_root().add_suite(new TestKeybindingManager().get_suite());
	    TestSuite.get_root().add_suite(new TestZeitgeistClipboardStorage().get_suite());
	    
	    return Test.run ();
    }
}

