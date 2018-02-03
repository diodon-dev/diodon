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
		    add_async_test("test_get_recent_items_by_type",
		        cb => test_get_recent_items_by_type.begin(cb),
		        res => test_get_recent_items_by_type.end(res)
		    );
		    add_async_test("test_get_recent_items_image",
		        cb => test_get_recent_items_image.begin(cb),
		        res => test_get_recent_items_image.end(res)
		    );
		    add_async_test("test_get_item_by_checksum",
		        cb => test_get_item_by_checksum.begin(cb),
		        res => test_get_item_by_checksum.end(res)
		    );
		    add_async_test("test_clear",
		        cb => test_clear.begin(cb),
		        res => test_clear.end(res)
		    );
		    // TODO: issue to run DBus service in test
		    //add_async_test("test_get_items_by_search_query",
		    //    cb => test_get_items_by_search_query.begin(cb),
		    //    res => test_get_items_by_search_query.end(res)
		    //);
	    }

	    public override void set_up()
	    {
	        this.log = Zeitgeist.Log.get_default();
            this.storage = new ZeitgeistClipboardStorage();
        }

	    public async void test_add_text_item() throws FsoFramework.Test.AssertError
	    {
	        TextClipboardItem text_item = new TextClipboardItem(
	            ClipboardType.CLIPBOARD, "test_add_text_item", "/path/to/app", new DateTime.now_utc());
 	        yield this.storage.add_item(text_item);
 	        yield assert_text_item("test_add_text_item", 1);
	    }

	    public async void test_remove_text_item() throws FsoFramework.Test.AssertError
	    {
	        string test_text =  "test_remove_text_item";
	        TextClipboardItem text_item = new TextClipboardItem(
	            ClipboardType.CLIPBOARD, test_text, "/path/to/app", new DateTime.now_utc());
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
	                new TextClipboardItem(ClipboardType.CLIPBOARD, i.to_string(), "/path/to/app", new DateTime.now_utc()));
	        }
	        // add a duplicate to test that duplicates are being ignored
	        yield this.storage.add_item(new TextClipboardItem(ClipboardType.CLIPBOARD,
	            ITEMS.to_string(), "/path/to/app", new DateTime.now_utc()));

	        List<IClipboardItem> items = yield this.storage.get_recent_items(RECENT_ITEMS);
	        FsoFramework.Test.Assert.are_equal(items.length(), RECENT_ITEMS,
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
	        FsoFramework.Test.Assert.are_equal(items.length(), ITEMS,
	            "Invalid number of recent items");
	    }

	    public async void test_get_recent_items_by_type() throws FsoFramework.Test.AssertError, GLib.Error
	    {
	        // add test data
	        yield this.storage.add_item(new TextClipboardItem(ClipboardType.CLIPBOARD, "1", "/path/to/app", new DateTime.now_utc()));
	        yield this.storage.add_item(new FileClipboardItem(ClipboardType.CLIPBOARD,
	            Config.TEST_DATA_DIR + "Diodon-64x64.png", "/path/to/app", new DateTime.now_utc()));
	        Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(Config.TEST_DATA_DIR + "Diodon-64x64.png");
	        yield this.storage.add_item(new ImageClipboardItem.with_image(ClipboardType.CLIPBOARD,
	            pixbuf, "/path/to/app", new DateTime.now_utc()));

            List<IClipboardItem> items = yield this.storage.get_recent_items(3, new ClipboardCategory[]{ClipboardCategory.IMAGES});
	        FsoFramework.Test.Assert.are_equal(items.length(), 1, "Invalid number of recent items");
	        IClipboardItem item = items.nth_data(0);
	        FsoFramework.Test.Assert.are_equal_string(item.get_label(), "[64x64]", "Invalid image label");
	    }

	    public async void test_get_recent_items_image() throws FsoFramework.Test.AssertError, GLib.Error
	    {
	        // add image item
            Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(Config.TEST_DATA_DIR + "Diodon-64x64.png");
	        yield this.storage.add_item(new ImageClipboardItem.with_image(ClipboardType.CLIPBOARD,
	            pixbuf, "/path/to/app", new DateTime.now_utc()));

	        List<IClipboardItem> items = yield this.storage.get_recent_items(100);
	        FsoFramework.Test.Assert.are_equal(items.length(), 1, "Invalid number of recent items");
	        IClipboardItem item = items.nth_data(0);
	        FsoFramework.Test.Assert.are_equal_string(item.get_label(), "[64x64]", "Invalid image label");
	    }

	    public async void test_get_item_by_checksum() throws FsoFramework.Test.AssertError
	    {
	        // add test item
	        TextClipboardItem text_item = new TextClipboardItem(ClipboardType.CLIPBOARD, "checksum", "/path/to/app", new DateTime.now_utc());
	        yield this.storage.add_item(text_item);

	        // check item availability
	        IClipboardItem item = yield this.storage.get_item_by_checksum(text_item.get_checksum());
	        FsoFramework.Test.Assert.is_true(item != null, "Item not found");
	        FsoFramework.Test.Assert.are_equal_string("checksum", item.get_text(), "Invalid content");

	        // check item which is not available
	        IClipboardItem not_found = yield this.storage.get_item_by_checksum("invalidchecksum");
	        FsoFramework.Test.Assert.is_true(not_found == null, "Item was not null");
	    }

	    public async void test_clear() throws FsoFramework.Test.AssertError, GLib.Error
	    {
	        // add test data
	        yield this.storage.add_item(new TextClipboardItem(ClipboardType.CLIPBOARD, "1", "/path/to/app", new DateTime.now_utc()));
	        yield this.storage.add_item(new FileClipboardItem(ClipboardType.CLIPBOARD,
	            Config.TEST_DATA_DIR + "Diodon-64x64.png", "/path/to/app", new DateTime.now_utc()));
	        Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(Config.TEST_DATA_DIR + "Diodon-64x64.png");
	        yield this.storage.add_item(new ImageClipboardItem.with_image(ClipboardType.CLIPBOARD,
	            pixbuf, "/path/to/app", new DateTime.now_utc()));

	        yield this.storage.clear();

	        List<IClipboardItem> items = yield this.storage.get_recent_items(3);
	        FsoFramework.Test.Assert.are_equal(0, (int) items.length(), "Items found");
	    }

	    // TODO: get this up and running
	    /*public async void test_get_items_by_search_query() throws FsoFramework.Test.AssertError, GLib.Error
	    {
	        yield this.storage.add_item(new TextClipboardItem(ClipboardType.CLIPBOARD, "TestName", "/path/to/app"));
	        yield this.storage.add_item(new TextClipboardItem(ClipboardType.CLIPBOARD, "TestName", "/path/to/app"));
	        yield this.storage.add_item(new TextClipboardItem(ClipboardType.CLIPBOARD, "SampleName", "/path/to/app"));

	        Gee.List<IClipboardItem> items = yield this.storage.get_items_by_search_query("name");
	        FsoFramework.Test.Assert.are_equal(2, items.length(), "Invalid number of items found");

	        items = yield this.storage.get_items_by_search_query("sample");
	        FsoFramework.Test.Assert.are_equal(1, items.length(), "Invalid number of items found");
	    }*/

	    public override void tear_down()
	    {
	        try {
	            FsoFramework.Test.wait_for_async(1000,
	                cb => this.storage.clear.begin(null, cb),
	                res => this.storage.clear.end(res));
	        } catch(GLib.Error e) {
                warning(e.message);
            }
        }

	    /**
	     * assert whether text item is added to Zeitgeist Log in assigned quantity
         */
	    private async void assert_text_item(string text, uint qty) throws FsoFramework.Test.AssertError
	    {
	        GenericArray<Event> templates = new GenericArray<Event>();
	        TimeRange time_range = new TimeRange.anytime();
            Event template = new Zeitgeist.Event.full (
                                ZG.CREATE_EVENT,
                                ZG.USER_ACTIVITY,
                                null,
                                "application://diodon.desktop", // origin events added by diodon
                                new Subject.full (
                                    ZeitgeistClipboardStorage.CLIPBOARD_URI + "*",
                                    NFO.PLAIN_TEXT_DOCUMENT,
                                    NFO.DATA_CONTAINER,
                                    null,
                                    null,
                                    text,
                                    null));
            templates.add(template);

            try {
	            ResultSet results = yield this.log.find_events(
                    time_range,
                    templates,
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

