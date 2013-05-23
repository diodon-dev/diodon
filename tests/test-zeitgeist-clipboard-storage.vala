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
	        unowned PtrArray zg_templates = new PtrArray.sized(1);
            var ev = new Zeitgeist.Event.full (ZG_CREATE_EVENT, ZG_USER_ACTIVITY, "",
                             new Subject.full ("clipboard*",
                                               NFO_PLAIN_TEXT_DOCUMENT,
                                               NFO_DATA_CONTAINER,
                                               "",
                                               "",
                                               "test_add_text_item",
                                               ""));
            zg_templates.add ((ev as GLib.Object).ref());
	    
	        TextClipboardItem text_item = new TextClipboardItem(
	            ClipboardType.CLIPBOARD, "test_add_text_item");
 	        this.storage.add_item(text_item);
 	        
 	        TimeRange time_range = new TimeRange.anytime();
            this.log.find_events.begin(
                time_range,
                zg_templates,
                StorageState.ANY,
                // not one as the event might be added more then once
                // and in this case the test fail
                40,
                ResultType.MOST_RECENT_SUBJECTS,
                null,
                (obj, res) => {                     
                    try {
                        ResultSet results = this.log.find_events.end(res);
                        // there should only be one test_add_text_item
                        assert(results.size()==1);
                     } catch(GLib.Error e) {
                        Test.message(e.message);
                        assert(false);
                    }
                });
	    }
	}
}

