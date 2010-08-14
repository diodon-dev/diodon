#! /usr/bin/env python
# encoding: utf-8
# Oliver Sauder, 2010

import Scripting

NAME = 'Diodon'
VERSION = '0.0.1'
APPNAME = 'diodon'
WEBSITE = 'https://launchpad.net/diodon'
COPYRIGHT = "Copyright \xc2\xa9 2010 Diodon Team"

VERSION_MAJOR_MINOR = '.'.join (VERSION.split ('.')[0:2])
VERSION_MAJOR = '.'.join (VERSION.split ('.')[0:1])
srcdir = '.'
blddir = '_build_'

def set_options(opt):
    opt.tool_options('compiler_cc')
    opt.tool_options('vala')
    opt.tool_options('gnu_dirs')

def configure(conf):
    conf.check_tool('compiler_cc cc vala gnu_dirs')
    conf.check_cfg(package='glib-2.0',         uselib_store='GLIB',         atleast_version='2.10.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gtk+-2.0',         uselib_store='GTK',          atleast_version='2.10.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gee-1.0',          uselib_store='GEE',          atleast_version='0.5.0',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='appindicator-0.1', uselib_store='APPINDICATOR', atleast_version='0.2.3',  mandatory=1, args='--cflags --libs')

    conf.define ('PACKAGE_NAME', APPNAME)
    conf.define ('GETTEXT_PACKAGE', APPNAME)
    conf.define ('VERSION', VERSION)
    conf.define ('COPYRIGHT', COPYRIGHT)
    conf.define ('WEBSITE', WEBSITE)
    conf.define ('APPNAME', NAME)
    conf.define ('VAPI_VERSION', VERSION_MAJOR)
   
def build(bld):
    bld.add_subdirs('src')

def dist ():
  # set the compression type to gzip (default is bz2)
  Scripting.g_gz = 'gz'
  Scripting.dist (APPNAME, VERSION)

