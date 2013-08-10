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
    class TestZeitgeistClipboardStorage : FsoFramework.Test.TestCase
    {
        private ZeitgeistClipboardStorage storage;
        private Zeitgeist.Log log;
        
	    public TestZeitgeistClipboardStorage()
	    {
		    base("TestZeitgeistClipboardStorage");
		    add_async_test("test_add_text_item",
		        cb => test_add_text_item.begin(cb),
		        res => test_add_text_item.end(res)
		    );
		    add_async_test("test_remove_text_item",
		        cb => test_remove_text_item.begin(cb),
		        res => test_remove_text_item.end(res)
		    );
		    add_async_test("test_get_recent_items",
		        cb => test_get_recent_items.begin(cb),
		        res => test_get_recent_items.end(res)
		    );
	    }
	    
	    public override void set_up()
	    {
	        this.log = Zeitgeist.Log.get_default();
            this.storage = new ZeitgeistClipboardStorage();
        }

	    public async void test_add_text_item() throws FsoFramework.Test.AssertError
	    {
	        TextClipboardItem text_item = new TextClipboardItem(
	            ClipboardType.CLIPBOARD, "test_add_text_item");
 	        yield this.storage.add_item(text_item);
 	        yield assert_text_item("test_add_text_item", 1);
	    }
	    
	    public async void test_remove_text_item() throws FsoFramework.Test.AssertError
	    {
	        string test_text =  "test_remove_text_item";
	        TextClipboardItem text_item = new TextClipboardItem(
	            ClipboardType.CLIPBOARD, test_text);
	        // add first item
	        yield this.storage.add_item(text_item);
	        yield assert_text_item(test_text, 1);
	        
	        // add another one
	        yield this.storage.add_item(text_item);
	        yield assert_text_item(test_text, 2);
	        
	        // remove item which should delete all (two) added
	        yield this.storage.remove_item(text_item);
	        yield assert_text_item(test_text, 0);
	    }
	    
	    public async void test_get_recent_items() throws FsoFramework.Test.AssertError
	    {
	        const int ITEMS = 10;
	        const int RECENT_ITEMS = 5;
	        
	        // add some items
	        for(int i=1; i<=ITEMS; ++i) {
	            yield this.storage.add_item(
	                new TextClipboardItem(ClipboardType.CLIPBOARD, i.to_string()));
	        }
	        // add a duplicate to test that duplicates are being ignored
	        yield this.storage.add_item(new TextClipboardItem(ClipboardType.CLIPBOARD,
	            ITEMS.to_string()));
	        
	        Gee.List<IClipboardItem> items = yield this.storage.get_recent_items(RECENT_ITEMS);
	        FsoFramework.Test.Assert.are_equal(items.size, RECENT_ITEMS,
	            "Invalid number of recent items");
	        
	        // recent items should be in reverse order
	        int current_item = ITEMS;
	        foreach(IClipboardItem item in items) {
                FsoFramework.Test.Assert.is_true(item is TextClipboardItem,
	                "Should be of type TextClipboardItem");
	            FsoFramework.Test.Assert.are_equal_string(item.get_text(),
	                current_item.to_string(), "Invalid clipboard item content");	            
	            --current_item;
	        }
	        
	        // only number of available items should be returned even when asked for more
	        items = yield this.storage.get_recent_items(ITEMS + 1);
	        FsoFramework.Test.Assert.are_equal(items.size, ITEMS,
	            "Invalid number of recent items");
	    }
	    
	    public override void tear_down()
	    {
	        try {
	            FsoFramework.Test.wait_for_async(1000,
	                cb => empty_zeitgeist_storage.begin(cb),
	                res => empty_zeitgeist_storage.end(res));
	        } catch(GLib.Error e) {
                warning(e.message);
            }
        }
	    
	    private async void empty_zeitgeist_storage()
	    {
	        PtrArray templates = new PtrArray.sized(1);
	        TimeRange time_range = new TimeRange.anytime();
            Event ev = new Zeitgeist.Event.full (ZG_CREATE_EVENT, ZG_USER_ACTIVITY, "",
                             new Subject.full ("clipboard*",
                                               NFO_PLAIN_TEXT_DOCUMENT,
                                               NFO_DATA_CONTAINER,
                                               "",
                                               "",
                                               "",
                                               ""));
            templates.add ((ev as GLib.Object).ref());
            
            try {
	            Array event_ids = yield log.find_event_ids(
	                time_range,
	                (owned)templates, 
                    StorageState.ANY,
                    uint32.MAX,
                    ResultType.MOST_RECENT_EVENTS,
                    null
                );
                
                yield log.delete_events((owned)event_ids, null);
            } catch(GLib.Error e) {
                warning(e.message);
            }
	    }
	    
	    /**
	     * assert whether text item is added to Zeitgeist Log in assigned quantity
         */
	    private async void assert_text_item(string text, uint qty) throws FsoFramework.Test.AssertError
	    {
	       
	        PtrArray templates = new PtrArray.sized(1);
	        TimeRange time_range = new TimeRange.anytime();
            Event ev = new Zeitgeist.Event.full (ZG_CREATE_EVENT, ZG_USER_ACTIVITY, "",
                             new Subject.full ("clipboard*",
                                               NFO_PLAIN_TEXT_DOCUMENT,
                                               NFO_DATA_CONTAINER,
                                               "",
                                               "",
                                               text,
                                               ""));
            templates.add ((ev as GLib.Object).ref());
                
            try {
	            ResultSet results = yield this.log.find_events(
                    time_range,
                    (owned)templates,
                    StorageState.ANY,
                    // not only one resp. qty as the event might be added more than
                    // once resp. qty and in such a case the test should fail
                    1 + qty,
                    ResultType.MOST_RECENT_EVENTS,
                    null);
                                   
                    FsoFramework.Test.Assert.are_equal(results.size(), qty,
                        "Result size did not match expected quantity");
                    
            } catch(GLib.Error e) {
                FsoFramework.Test.Assert.fail(e.message);
            }
    	}
	}
}

