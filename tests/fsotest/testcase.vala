/* testcase.vala
 *
 * Copyright (C) 2009-2012 Julien Peeters
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *  Julien Peeters <contact@julienpeeters.fr>
 *
 * Copied from libgee/tests/testcase.vala.
 */

public abstract class FsoFramework.Test.TestCase : Object
{
    private GLib.TestSuite _suite;
    private Adaptor[] _adaptors = new Adaptor[0];

    public delegate void TestMethod () throws GLib.Error;

    protected TestCase (string name)
    {
        this._suite = new GLib.TestSuite (name);
    }

    public void add_test (string name, owned TestMethod test)
    {
        var adaptor = new Adaptor (name, (owned)test, this);
        this._adaptors += adaptor;

        this._suite.add (new GLib.TestCase (adaptor.name, adaptor.set_up, adaptor.run, adaptor.tear_down, sizeof(Adaptor)));
    }

    public void add_async_test (string name, AsyncBegin async_begin, AsyncFinish async_finish, int timeout = 200)
    {
        var adaptor = new Adaptor (name, () => { }, this);
        adaptor.is_async = true;
        adaptor.async_begin = async_begin;
        adaptor.async_finish = async_finish;
        adaptor.async_timeout = timeout;
        this._adaptors += adaptor;

        this._suite.add (new GLib.TestCase (adaptor.name, adaptor.set_up, adaptor.run, adaptor.tear_down, sizeof(Adaptor)));
    }

    public virtual void set_up ()
    {
    }

    public virtual void tear_down ()
    {
    }

    public GLib.TestSuite get_suite ()
    {
        return this._suite;
    }

    private class Adaptor
    {
        public string name { get; private set; }
        public int async_timeout { get; set; }

        private unowned TestMethod _test;
        private TestCase _test_case;

        public bool is_async = false;
        public unowned AsyncBegin async_begin;
        public unowned AsyncFinish async_finish;

        public Adaptor (string name, TestMethod test, TestCase test_case)
        {
            this._name = name;
            this._test = test;
            this._test_case = test_case;
        }

        public void set_up (void* fixture)
        {
            GLib.set_printerr_handler (Adaptor._printerr_func_stack_trace);
            Log.set_default_handler (this._log_func_stack_trace);
            this._test_case.set_up ();
        }

        private static void _printerr_func_stack_trace (string? text)
        {
            if (text == null || str_equal (text, ""))
                return;

            stderr.printf (text);

            /* Print a stack trace since we've hit some major issue */
            GLib.on_error_stack_trace ("libtool --mode=execute gdb");
        }

        private void _log_func_stack_trace (string? log_domain, LogLevelFlags log_levels, string message)
        {
            Log.default_handler (log_domain, log_levels, message);

            /* Print a stack trace for any message at the warning level or above */
            if ((log_levels & (LogLevelFlags.LEVEL_WARNING | LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL)) != 0)
            {
                GLib.on_error_stack_trace ("libtool --mode=execute gdb");
            }
        }

        public void run (void* fixture)
        {
            if (this.is_async)
            {
                try
                {
                    assert( wait_for_async (async_timeout, this.async_begin, this.async_finish) );
                }
                catch (GLib.Error err)
                {
                    message(@"Got exception while excuting asynchronous test: $(err.message)");
                    GLib.Test.fail();
                }
            }
            else
            {
                try
                {
                    this._test ();
                }
                catch (GLib.Error err)
                {
                    message(@"Got exception while excuting test: $(err.message)");
                    GLib.Test.fail();
                }
            }
        }

        public void tear_down (void* fixture)
        {
            this._test_case.tear_down ();
        }
    }
}
