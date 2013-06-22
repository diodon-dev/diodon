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
    /**
     * Testing of TextClipboardItem functionality
     */
    class TestTextClipboardItem : FsoFramework.Test.TestCase
    {
	    public TestTextClipboardItem()
	    {
		    base("TestTextClipboardItem");
		    add_test("test_matches", test_matches);
	    }

	    public void test_matches()
	    {
	        TextClipboardItem item = new TextClipboardItem(ClipboardType.NONE,
	            "Test");
	        
		    assert(item.matches("TEST", ClipboardItemType.ALL));
		    assert(item.matches("test", ClipboardItemType.TEXT));
		    assert(!item.matches("othertest", ClipboardItemType.TEXT));
		    assert(!item.matches("test", ClipboardItemType.FILES));
	    }
	}
}

