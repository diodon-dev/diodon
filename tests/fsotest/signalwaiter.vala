/*
 * (C) 2011-2012 Simon Busch <morphis@gravedo.de>
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
 */

using GLib;

namespace FsoFramework.Test
{
    private class SignalWrapper
    {
        public Object emitter { get; set; }
        public string signame { get; set; default = ""; }
        public ulong id { get; set; }
        public int timeout { get; set; }
        public int catch_count { get; set; }

        public int callback()
        {
            catch_count++;
            triggered();
            return 0;
        }

        public void setup()
        {
            id = Signal.connect_swapped( emitter, signame, (Callback) SignalWrapper.callback, this );
            catch_count = 0;
        }

        public void release()
        {
            SignalHandler.disconnect( emitter, id );
        }

        public signal void triggered();
    }

    /**
     * Wait for one or more signals to arrived when executing a operation which causes
     * this signals to be triggered. The waiter will return a failure when a timeout is
     * reached and no or not all signals has triggered.
     *
     * Example:
     *  var waiter = new MultiSignalWaiter();
     *  waiter.add_signal( emitter, "signal0" );
     *  var result = waiter.run( () => { triggerSignal0(); } );
     **/
    public class MultiSignalWaiter : GLib.Object
    {
        private GLib.List<SignalWrapper> signals = new GLib.List<SignalWrapper>();
        private uint succeeded_count = 0;
        private MainLoop mainloop;

        /**
         * Add a signal of an object called emitter to listen for until a timeout is
         * reached.
         *
         * @param emitter Object which emits the signal
         * @param signame Name of the signal
         * @param timeout Timeout Specifies the maximum amount of time to wait for the
         *                signal to be triggerd.
         **/
        public void add_signal( Object emitter, string signame, int timeout = 200 )
        {
            var s = new SignalWrapper() { emitter = emitter, signame = signame, timeout = timeout };
            s.triggered.connect( () => {
                succeeded_count++;
                if ( succeeded_count == signals.length() )
                    mainloop.quit();
            } );
            signals.append( s );
        }

        /**
         * Run the code block which causes the added signals to be triggered. After block
         * is executed and timeout is reached or all signals has arrived the result is
         * returned to the caller.
         *
         * @param block Code block to execute
         * @param timeout Timeout to wait before returning to caller
         * @return True, if all signals has been triggered. False, if timeout is reached
         *         and not all signals has been triggered.
         **/
        public bool run( Block block, int timeout = 200 )
        {
            mainloop = new MainLoop(MainContext.default(), true);
            succeeded_count = 0;

            foreach ( var s in signals )
                s.setup();

            block();
            var t1 = Timeout.add( timeout, () => {
                mainloop.quit();
                return false;
            } );

            while ( mainloop.is_running() )
                mainloop.run();

            bool succeeded = true;
            foreach ( var s in signals )
            {
                s.release();
                if ( s.catch_count == 0 )
                    succeeded = false;
            }

            Source.remove( t1 );
            return succeeded;
        }
    }
}

// vim:ts=4:sw=4:expandtab
