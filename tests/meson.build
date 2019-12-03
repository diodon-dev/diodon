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

# TODO add zeitgeist integration tests

test_diodon = executable('test-diodon', [
        'test-clipboard-configuration.vala',
        'test-controller.vala',
        'test-image-clipboard-item.vala',
        'test-main.vala',
        'test-zeitgeist-clipboard-storage.vala',
        'fsotest/assert.vala',
        'fsotest/asynchelpers.vala',
        'fsotest/signalwaiter.vala',
        'fsotest/testcase.vala',
    ],
    vala_args: common_vflags,
    c_args: common_cflags,
    dependencies: [
        gio_unix_dep,
        gtk_dep,
        zeitgeist_dep,
    ],
    link_with: [libdiodon],
    include_directories: [libdiodon_inc])


test('test-diodon', xvfb_run,
    env: ['top_builddir=' + meson.build_root(),
          'top_srcdir=' + meson.source_root(),
          'srcdir=' + meson.current_source_dir()],
    args: [test_diodon.full_path()])
