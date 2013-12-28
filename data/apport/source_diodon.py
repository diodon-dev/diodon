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
    if not apport.packaging.is_distro_package(report['Package'].split()[0]):
        report['CrashDB'] = 'diodon'
