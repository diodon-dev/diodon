'''
apport package hook for diodon

Copyright (C) 2010-2013 Diodon Team
Author: Oliver Sauder <os@esite.ch>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.  See http://www.gnu.org/copyleft/gpl.html for
the full text of the license.
'''

import apport
from apport.hookutils import attach_file_if_exists
import os
from os import path, getenv

def add_info(report, ui):
    response = ui.choice("Should your clipboard history (storage.xml) be added to the bug report as well?", ["Yes, add my clipboard history", "No, do not add my clipboard history"], False)

    if response == None: # user cancelled
        raise StopIteration

    if response[0] == 0: # yes, add clipboard history
        local_dir = getenv('XDG_DATA_HOME', path.expanduser('~/.local/share'))
        storage_xml_file = path.join(local_dir, 'diodon/storage.xml')
        attach_file_if_exists(report, storage_xml_file, 'storage.xml')

    if not apport.packaging.is_distro_package(report['Package'].split()[0]):
        report['CrashDB'] = 'diodon'
