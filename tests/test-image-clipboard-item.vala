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
     * Testing of ImageClipboardItem functionality
     */
    class TestImageClipboardItem : FsoFramework.Test.TestCase
    {
	    public TestImageClipboardItem()
	    {
		    base("TestImageClipboardItem");
		    add_test("test_image_clipboard_item_new_with_payload", test_image_clipboard_item_new_with_payload);
	    }

	    public void test_image_clipboard_item_new_with_payload() throws GLib.Error
	    {
            Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(Path.build_filename(Config.TEST_DATA_DIR, "Diodon-64x64.png"));

            ImageClipboardItem item1 = new ImageClipboardItem.with_image(ClipboardType.CLIPBOARD, pixbuf, null, new DateTime.now_utc());
            string checksum1 = item1.get_checksum();

            ImageClipboardItem item2 = new ImageClipboardItem.with_payload(ClipboardType.CLIPBOARD, item1.get_payload(), null, new DateTime.now_utc());
            string checksum2 = item2.get_checksum();

            FsoFramework.Test.Assert.are_equal_string(checksum1, checksum2, "Images are not the same");
	    }
	}
}

