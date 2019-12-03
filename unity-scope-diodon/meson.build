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

unity_scope = executable('unity-scope-diodon', [
        'unity-scope-diodon.vala',
    ],
    vala_args: common_vflags,
    c_args: common_cflags,
    dependencies: [
        gtk_dep,
        unity_dep,
    ],
    link_with: [libdiodon],
    include_directories: [libdiodon_inc],
    install: true,
    install_dir: pkglibdir)

conf_data = configuration_data()
conf_data.set('DATADIR', datadir)
conf_data.set('PKGLIBDIR', pkglibdir)

configure_file(input : 'clipboard.scope.in.in',
               output : 'clipboard.scope.in',
               configuration : conf_data)

i18n.merge_file(
    type: 'desktop',
    input: join_paths(meson.current_build_dir(), 'clipboard.scope.in'),
    output: 'clipboard.scope',
    po_dir: podir,
    install: true,
    install_dir: join_paths(datadir, 'unity', 'scopes')
)

configure_file(input : 'unity-scope-diodon.service.in',
    output : 'unity-scope-diodon.service',
    configuration : conf_data,
    install_dir: join_paths(datadir, 'dbus-1', 'services')
)

install_data('unity-scope-diodon.gschema.override',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'))
