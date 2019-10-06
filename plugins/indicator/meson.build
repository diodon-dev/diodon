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

plugin_indicator = shared_library('indicator',
    [
     'indicator-plugin.vala',
    ],
    vala_args: common_vflags,
    c_args: common_cflags,
    link_with: [libdiodon],
    dependencies: [
        gtk_dep,
        libpeas_dep,
        appindicator_dep
    ],
    include_directories: [libdiodon_inc],
    install: true,
    install_dir: join_paths(pkgpluginslibdir, 'indicator'),
)

i18n.merge_file(
    type: 'desktop',
    input: 'indicator.plugin.in',
    output: 'indicator.plugin',
    po_dir: podir,
    install: true,
    install_dir: join_paths(pkgpluginslibdir, 'indicator')
)
