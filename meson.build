# -*- Mode: Meson; indent-tabs-mode: nil; tab-width: 4 -*-
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation, either version 2 of the License, or (at
#  your option) any later version.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
#  License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  Author:
#   Oliver Sauder <os@esite.ch>

project('diodon', ['vala', 'c'],
    version: '1.11.2',
    license: 'GPLv2+',
    default_options: [
        'warning_level=1',
        'buildtype=debugoptimized',
    ],
    meson_version: '>= 0.45')

gnome = import('gnome')
i18n = import('i18n')
pkg = import('pkgconfig')

# Source paths
podir = join_paths(meson.current_source_dir(), 'po')
vapidir = join_paths(meson.current_source_dir(), 'vapi')
testdatadir = join_paths(meson.current_source_dir(), 'tests', 'data')

# Install paths
prefix = get_option('prefix')
bindir = join_paths(prefix, get_option('bindir'))
datadir = join_paths(prefix, get_option('datadir'))
etcdir = get_option('sysconfdir')
libdir = join_paths(prefix, get_option('libdir'))
pkgincludedir = join_paths(prefix, get_option('includedir'), 'diodon')
localedir = join_paths(prefix, get_option('localedir'))
pkgdatadir = join_paths(datadir, meson.project_name())
pkglibdir = join_paths(libdir, meson.project_name())
pkgpluginslibdir = join_paths(pkglibdir, 'plugins')
pkgpluginsdatadir = join_paths(pkgdatadir, 'plugins')

# Dependencies
if not get_option('disable-indicator-plugin')
	appindicator_dep = dependency('ayatana-appindicator3-0.1', version: '>=0.5.3')
endif
if get_option('enable-unity-scope')
	unity_dep = dependency('unity', version: '>=7.1.0')
endif
gdk_dep = dependency('gdk-3.0', version: '>=3.0.8')
gdk_x11_dep = dependency('gdk-x11-3.0', version: '>=3.0.8')
gio_dep = dependency('gio-2.0', version: '>= 2.46')
gio_unix_dep = dependency('gio-unix-2.0', version: '>=2.46')
glib_dep = dependency('glib-2.0', version: '>=2.46.0')
gtk_dep = dependency('gtk+-3.0', version: '>= 3.22')
libpeas_dep = dependency('libpeas-1.0', version: '>=1.1.0')
libpeas_gtk_dep = dependency('libpeas-gtk-1.0', version: '>=1.1.0')
xtst_dep = dependency('xtst', version: '>=1.2.0')
x11_dep = dependency('x11', version: '>=1.6.3')
zeitgeist_dep = dependency('zeitgeist-2.0', version: '>=0.9.14')

# Programs

glib_compile_schemas = find_program('glib-compile-schemas')
desktop_file_validate = find_program('desktop-file-validate')
g_ir_compiler = find_program('g-ir-compiler')
xvfb_run = find_program('xvfb-run')

common_vflags = [
    '--pkg=config',
    '--pkg=posix',
    '--disable-assert',
    '--target-glib=2.46',
    '--vapidir', vapidir,
]

common_cflags = [
    '-w',
    '-DPACKAGE="@0@"'.format(meson.project_name()),
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DVERSION="@0@"'.format(meson.project_version()),
    '-DLOCALE_DIR="@0@"'.format(localedir),
    '-DPKG_DATA_DIR="@0@"'.format(pkgdatadir),
    '-DPKG_PLUGINS_LIB_DIR="@0@"'.format(pkgpluginslibdir),
    '-DPKG_PLUGINS_DATA_DIR="@0@"'.format(pkgpluginsdatadir),
    '-DTEST_DATA_DIR="@0@"'.format(testdatadir),
]

subdir('data')
subdir('libdiodon')
subdir('diodon')
subdir('po')
subdir('plugins')
subdir('tests')
if get_option('enable-unity-scope')
	subdir('unity-scope-diodon')
endif
