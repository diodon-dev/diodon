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
    public errordomain AssertError
    {
        UNEXPECTED_VALUE,
        UNEXPECTED_STATE,
    }

    public class Assert : GLib.Object
    {
        private static string typed_value_to_string<T>( T value )
        {
            string result = "";

            Type value_type = typeof(T);
            if ( value_type.is_value_type() )
            {
                if ( value_type.is_a( typeof(string) ) )
                    result = @"$((string) value)";
                else if ( value_type.is_a( typeof(int32) ) )
                    result = @"$((int32) value)";
                else if ( value_type.is_a( typeof(uint32) ) )
                    result = @"$((uint32) value)";
                else if ( value_type.is_a( typeof(int16) ) )
                    result = @"$((int16) value)";
                else if ( value_type.is_a( typeof(uint16) ) )
                    result = @"$((uint16) value)";
                else if ( value_type.is_a( typeof(int8) ) )
                    result = @"$((int8) value)";
                else if ( value_type.is_a( typeof(uint8) ) )
                    result = @"$((uint8) value)";
                else if ( value_type.is_a( typeof(bool) ) )
                    result = @"$((bool) value)";
            }

            return result;
        }

        private static void throw_unexpected_value( string info, string message ) throws AssertError
        {
            throw new AssertError.UNEXPECTED_VALUE( info +  ( message.length > 0 ? @" : $(message)" : "" ) );
        }

        /**
         * Check wether two values of type T are the same. If both values are different an
         * exception of type AssertError is thrown.
         *
         * @param expected Expected value
         * @param actual Actual value to compare with the expected one
         * @param message Extra description message if both values are different
         **/
        public static void are_equal<T>( T expected, T actual, string message = "" ) throws AssertError
        {

            if ( expected != actual )
            {
                var msg = @"$(typed_value_to_string(expected)) != $(typed_value_to_string(actual))";
                throw_unexpected_value( @"Actual value is not the same as the expected one: $(msg)", message );
            }
        }

        /**
         * Check wether two values of type string are the same. If both values are different an
         * exception of type AssertError is thrown.
         *
         * @param expected Expected value
         * @param actual Actual value to compare with the expected one
         * @param message Extra description message if both values are different
         **/
        public static void are_equal_string ( string expected, string actual, string message = "" ) throws AssertError
        {
            if ( strcmp( expected, actual ) != 0 )
            {
                var msg = @"$(expected) != $(actual)";
                throw_unexpected_value( @"Actual value is not the same as the expected one: $(msg)", message );
            }
        }

        /**
         * Check wether two values of type T are not the same. If both values are the same an
         * exception of type AssertError is thrown.
         *
         * @param not_expected Not expected value
         * @param actual Actual value to compare with the not expected one
         * @param message Extra description message if both values are not different
         **/
        public static void are_not_equal<T>( T not_expected, T actual, string message = "" ) throws AssertError
        {
            if ( not_expected == actual )
            {
                var msg = "$(typed_value_to_string(expected)) == $(typed_value_to_string(actual))";
                throw_unexpected_value( @"Actual value is the same as the not expected one: $(msg)", message );
            }
        }

        /**
         * Check wether a boolean value is true and throw an exception otherwise.
         *
         * @param actual Value to check if it's true or not
         * @param message Text message to append to error message when assert failed
         **/
        public static void is_true( bool actual, string message = "" ) throws AssertError
        {
            if ( !actual )
                throw_unexpected_value( "Supplied value is not true", message );
        }

        /**
         * Check wether a boolean value is false and throw an exception otherwise.
         *
         * @param actual Value to check if it's false or not
         * @param message Text message to append to error message when assert failed
         **/
        public static void is_false( bool actual, string message = "" ) throws AssertError
        {
            if ( actual )
                throw_unexpected_value( "Supplied value is not false", message );
        }

        /**
         * Let test execution fail regardless any condition.
         *
         * @param message Text to append to error message
         **/
        public static void fail( string message ) throws AssertError
        {
            throw new AssertError.UNEXPECTED_STATE( message );
        }

        /**
         * Check wether an async operation throws a specific exception.
         *
         * @param fbegin Method to start execution of async operation
         * @param ffinish Method to finish execution of async operation
         * @param domain Error domain of the exception which should be thrown by the async
                         operation.
         * @param message Text message to append to error message when specific exception
         *                is not thrown.
         **/
        public static void should_throw_async( AsyncBegin fbegin, AsyncFinish ffinish, string domain, string message = "" ) throws AssertError
        {
            try
            {
                if ( !wait_for_async( 200, fbegin, ffinish ) )
                    throw_unexpected_value( "Execution of async method didn't returns the expected value", message );
            }
            catch ( GLib.Error err )
            {
                if ( err.domain.to_string() != domain )
                    throw_unexpected_value( @"Didn't receive the expected exception of type $domain", message );
                return;
            }

            throw new AssertError.UNEXPECTED_STATE( @"Function didn't throw expected exception" );
        }
    }
}

// vim:ts=4:sw=4:expandtab
