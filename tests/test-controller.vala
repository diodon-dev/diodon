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

namespace Diodon
{
    /**
     * Testing of Controller functionality
     */
    class TestController : FsoFramework.Test.TestCase
    {
        private Controller controller;

	    public TestController()
	    {
		    base("TestController");
		    add_test("test_filter_item_whitespace", test_filter_item_whitespace);
		    add_test("test_filter_item_whitespace", test_filter_item_none_whitespace);
	    }

	    public override void set_up()
	    {
	        ClipboardConfiguration cfg = new ClipboardConfiguration();
	        this.controller = new Controller.with_configuration(cfg, false);
        }

	    public void test_filter_item_whitespace() throws GLib.Error
	    {
	        assert(controller.filter_item(create_text_item(" ")));
	        assert(controller.filter_item(create_text_item("   ")));
	        assert(controller.filter_item(create_text_item("  \n ")));
	        assert(controller.filter_item(create_text_item("\t")));
	    }

	    public void test_filter_item_none_whitespace() throws GLib.Error
	    {
	        assert(!controller.filter_item(create_text_item("This is a item\n ")));
	        assert(!controller.filter_item(create_text_item("  \nThis is a item")));
	        assert(!controller.filter_item(create_text_item(" an item ")));
	        assert(!controller.filter_item(create_text_item("this is a item")));
	    }

	    private TextClipboardItem create_text_item(string text)
	    {
	        return new TextClipboardItem(ClipboardType.CLIPBOARD, text, null,
	            new DateTime.now_utc());
	    }
	}
}

