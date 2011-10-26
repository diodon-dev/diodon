/* xtst.vapi
 *
 * Copyright (C) 2011  Alexander Kurtz
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Alexander Kurtz <kurtz.alex@xxxxxxxxxxxxxx>
 */


[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "X11/extensions/XTest.h")]
namespace X {
	public class Test {
		[CCode (cname = "XTestQueryExtension")]
		public static bool query_extension(Display display, int event_base_return, int error_base_return, int major_version_return, int minor_version_return);

		//[CCode (cname = "XTestCompareCursorWithWindow")]
		//public static bool compare_cursor_with_window(Display display, Window window, Cursor cursor);

		[CCode (cname = "XTestCompareCurrentCursorWithWindow")]
		public static bool compare_current_cursor_with_window(Display display, Window window);

		[CCode (cname = "XTestFakeKeyEvent")]
		public static int fake_key_event(Display display, uint keycode, bool is_press, ulong delay);

		[CCode (cname = "XTestFakeButtonEvent")]
		public static int fake_button_event(Display display, uint button, bool is_press, ulong delay);

		[CCode (cname = "XTestFakeMotionEvent")]
		public static int fake_motion_event(Display display, int screen_number, int x, int y, ulong delay);
		
		[CCode (cname = "XTestFakeRelativeMotionEvent")]
		public static int fake_relative_motion_event(Display display, int screen_number, int x, int y, ulong delay);

		[CCode (cname = "XTestGrabControl")]
		public static int grab_control(Display display, bool impervious);

		//[CCode (cname = "XTestSetGContextOfGC")]
		//public static void set_g_context_of_gc(GC gc, GContext gid);

		//[CCode (cname = "XTestSetVisualIDOfVisual")]
		//public static void set_visual_id_of_visual(Visual visual, VisualID visualid);

		[CCode (cname = "XTestDiscard")]
		public static Status discard(Display display);
	}
}
