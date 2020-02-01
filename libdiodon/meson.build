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

libdiodon = shared_library('diodon',
    [
     'clipboard-configuration.vala',
     'clipboard-item.vala',
     'clipboard-manager.vala',
     'clipboard-menu-item.vala',
     'clipboard-menu.vala',
     'clipboard-type.vala',
     'controller.vala',
     'file-clipboard-item.vala',
     'image-clipboard-item.vala',
     'preferences-view.vala',
     'primary-clipboard-manager.vala',
     'text-clipboard-item.vala',
     'utility.vala',
     'zeitgeist-clipboard-storage.vala',
    ],
    soversion: 0,
    vala_args: common_vflags,
    vala_gir: 'Diodon-1.0.gir',
    c_args: common_cflags,
    dependencies: [
        gdk_dep,
        gdk_x11_dep,
        gtk_dep,
        libpeas_dep,
        libpeas_gtk_dep,
        x11_dep,
        xtst_dep,
        zeitgeist_dep,
    ],
    install: true,
    install_dir: [true, pkgincludedir, true, true],
)

libdiodon_inc = include_directories('.')

# TODO: replace string in requires with gtk_dep variable
# once meson build system requirement can be set higher than 0.45
pkg.generate(
	name: 'diodon',
	libraries: [libdiodon],
	requires: ['gtk+-3.0'],
	version: meson.project_version(),
	description: 'Diodon GTK+ Clipboard Manager'
)

# TODO: Workaround till following issue is fixed:
# https://github.com/mesonbuild/meson/issues/2296
custom_target('libdiodon typelib',
	command: [g_ir_compiler, '--shared-library=libdiodon', '--output', '@OUTPUT@', join_paths(meson.current_build_dir(), 'Diodon-1.0.gir')],
	output: 'Diodon-1.0.typelib',
	depends: libdiodon,
	install: true,
	install_dir: join_paths(get_option('libdir'), 'girepository-1.0')
)
