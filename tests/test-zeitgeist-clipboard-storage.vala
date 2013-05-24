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
        private delegate void CleanUpMethod();
        
        private ZeitgeistClipboardStorage storage;
        private Zeitgeist.Log log;
        private MainLoop mainloop;
        
	    public TestZeitgeistClipboardStorage()
	    {
		    base("TestZeitgeistClipboardStorage");
		    add_test("test_add_text_item", test_add_text_item);
		    add_test("test_remove_text_item", test_remove_text_item);
	    }
	    
	    public override void set_up()
	    {
	        this.log = Zeitgeist.Log.get_default();
            this.storage = new ZeitgeistClipboardStorage();
            
            // main loop needed as finding, deleting events is async and would
            // otherwise not be executed after test terminated.
            this.mainloop = new MainLoop(MainContext.default());
        }

	    public void test_add_text_item()
	    {
	        TextClipboardItem text_item = new TextClipboardItem(
	            ClipboardType.CLIPBOARD, "test_add_text_item");
 	        this.storage.add_item.begin(text_item, (obj, res) => {
 	            assert_text_item("test_add_text_item", 1,
 	                () => { this.mainloop.quit(); }
 	            );
 	        });
 	        
 	        this.mainloop.run();
	    }
	    
	    public void test_remove_text_item()
	    {
	        string test_text =  "test_remove_text_item";
	        
	        TextClipboardItem text_item = new TextClipboardItem(
	            ClipboardType.CLIPBOARD, test_text);
 	        this.storage.add_item.begin(text_item, (obj, res) => {
 	            assert_text_item(test_text, 1, null);
 	            this.storage.remove_item.begin(text_item, (obj, res) => {
 	                assert_text_item(test_text, 0,
 	                    () => { this.mainloop.quit(); }
 	                );
 	            }); 
 	        });
 	        
 	        this.mainloop.run();
	    }
	    
	    /**
	     * assert whether text item is added to Zeitgeist Log in assigned quantity
         */
	    private void assert_text_item(string text, uint qty, CleanUpMethod? clean_up)
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
                
	        this.log.find_events.begin(
                time_range,
                (owned)templates,
                StorageState.ANY,
                // not only one resp. qty as the event might be added more then once
                // and in this case the test should fail
                1 + qty,
                ResultType.MOST_RECENT_SUBJECTS,
                null,
                (obj, res) => {                     
                    try {
                        ResultSet results = this.log.find_events.end(res);
                        assert(results.size()==qty);
                     } catch(GLib.Error e) {
                        warning(e.message);
                        assert(false);
                    }
                    
                    if(clean_up != null) {
                        clean_up();
                    }
                });
    	}
	}
	
	
}

