/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010-2019 Diodon Team <diodon-team@lists.launchpad.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Config
{
  public const string GETTEXT_PACKAGE;

  public const string PACKAGE;
  public const string VERSION;

  public const string LOCALE_DIR;
  public const string PKG_DATA_DIR;
  public const string PKG_PLUGINS_LIB_DIR;
  public const string PKG_PLUGINS_DATA_DIR;

  public const string TEST_DATA_DIR;
}

