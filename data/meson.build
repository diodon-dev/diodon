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

install_man('diodon.1')
install_data('preferences.ui', install_dir: pkgdatadir)
install_data('diodon.deps', install_dir: join_paths(datadir, 'vala', 'vapi'))

diodon_autostart_desktop = 'diodon-autostart.desktop'

i18n.merge_file(
    type: 'desktop',
    input: 'diodon-autostart.desktop.in',
    output: diodon_autostart_desktop,
    po_dir: podir,
    install: true,
    install_dir: join_paths(etcdir, 'xdg', 'autostart'))

test('validate-diodon-autostart-desktop', desktop_file_validate,
    args: [join_paths(meson.current_build_dir(), diodon_autostart_desktop)])

diodon_desktop = 'diodon.desktop'

i18n.merge_file(
    type: 'desktop',
    input: 'diodon.desktop.in',
    output: diodon_desktop,
    po_dir: podir,
    install: true,
    install_dir: join_paths(datadir, 'applications'))

test('validate-diodon-desktop', desktop_file_validate,
    args: [join_paths(meson.current_build_dir(), diodon_desktop)])

diodon_gschema = 'net.launchpad.Diodon.gschema.xml'

install_data(diodon_gschema,
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'))

test('validate-gschema', glib_compile_schemas,
    args: ['--strict', '--dry-run', '--schema-file',
           join_paths(meson.current_source_dir(), diodon_gschema)])

subdir('icons')

meson.add_install_script('post-install.sh', datadir)
message('''You may need to recompile your gsettings schemas or regenerate
         your icon cache after installation.''')
