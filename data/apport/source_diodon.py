'''
apport package hook for diodon

Copyright (C) 2010 Diodon Team
Author: Oliver Sauder <os@esite.ch>
'''

import apport
from apport.hookutils import *
from os import path, getenv

def add_info(report):
    local_dir = getenv('XDG_DATA_HOME', path.expanduser('~/.local/share'))
    storage_xml_file = path.join(local_dir, 'diodon/storage.xml')
    attach_file_if_exists(report, storage_xml_file, 'storage.xml')
    if not apport.packaging.is_distro_package(report['Package'].split()[0]):
        report['CrashDB'] = 'diodon'
