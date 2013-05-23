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

using Zeitgeist;
 
namespace Diodon
{
    /**
     * Testing of ZeitgeistClipboardStorage functionality
     */
    class TestZeitgeistClipboardStorage : TestCase
    {
        private ZeitgeistClipboardStorage storage;
        private Zeitgeist.Log log;
        
	    public TestZeitgeistClipboardStorage()
	    {
		    base("ZeitgeistClipboardStorage");
		    add_test("test_add_text_item", test_add_text_item);
	    }
	    
	    public override void set_up()
	    {
	        this.log = Zeitgeist.Log.get_default();
            this.storage = new ZeitgeistClipboardStorage();
        }

	    public void test_add_text_item()
	    {   
	        TextClipboardItem text_item = new TextClipboardItem(
	            ClipboardType.CLIPBOARD, "test");
 	        this.storage.add_item(text_item);
 	        
 	        //this.log.find_events(
	    }
	}
}

