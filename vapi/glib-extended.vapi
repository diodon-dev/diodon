using GLib;

/**
 * The vapi files shipped with valac 0.22 doesn't include
 * OptionContext.parse_strv.
 */
public class OptionContextExtended {
	[CCode (cname = "g_option_context_parse_strv")]
	public static bool parse_strv (OptionContext obj, [CCode (array_length = false, array_null_terminated = true)] ref string[] argv) throws OptionError;
}
