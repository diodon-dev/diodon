#! /usr/bin/env python
# encoding: utf-8
# Oliver Sauder, 2010

import intltool, os, traceback, pproc as subprocess
import Scripting, Options, Utils

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
    opt.add_option('--update-po', action='store_true', default=False, dest='update_po', help='Update localization files')
    opt.add_option('--debug',     action='store_true', default=False, dest='debug',     help='Debug mode')

def configure(conf):
    conf.check_tool('compiler_cc cc vala intltool gnu_dirs')
    conf.check_cfg(package='glib-2.0',         uselib_store='GLIB',         atleast_version='2.10.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gtk+-2.0',         uselib_store='GTK',          atleast_version='2.10.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gee-1.0',          uselib_store='GEE',          atleast_version='0.5.0',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='libxml-2.0',       uselib_store='XML',          atleast_version='2.7.6',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='appindicator-0.1', uselib_store='APPINDICATOR', atleast_version='0.2.3',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='vala-1.0',         uselib_store='VALA',         atleast_version='0.8.0',  mandatory=1, args='--cflags --libs')

    conf.define ('PACKAGE_NAME', APPNAME)
    conf.define ('GETTEXT_PACKAGE', APPNAME)
    conf.define ('VERSION', VERSION)
    conf.define ('COPYRIGHT', COPYRIGHT)
    conf.define ('WEBSITE', WEBSITE)
    conf.define ('APPNAME', NAME)
    conf.define ('VAPI_VERSION', VERSION_MAJOR)
    
    # set 'default' variant
    conf.define ('DEBUG', 0)
    conf.env['CCFLAGS']=['-O2']
    conf.write_config_header ('config.h')
    
    # set 'debug' variant
    env_debug = conf.env.copy ()
    env_debug.set_variant ('debug')
    conf.set_env_name ('debug', env_debug)
    
    conf.setenv ('debug')
    conf.define ('DEBUG', 1)
    conf.env['CCFLAGS'] = ['-O0', '-g3']
    conf.env['VALAFLAGS'] = ['-g', '-v']
    conf.write_config_header ('config.h', env=env_debug)
   
def build(bld):
    bld.add_subdirs('po src')

def dist ():
  # set the compression type to gzip (default is bz2)
  Scripting.g_gz = 'gz'
  Scripting.dist (APPNAME, VERSION)
  
def shutdown ():
    if Options.options.update_po:
        os.chdir('./po')
        try:
            try:
                size_old = os.stat (APPNAME + '.pot').st_size
            except:
                size_old = 0
            subprocess.call (['intltool-update', '-p', '-g', APPNAME])
            size_new = os.stat (APPNAME + '.pot').st_size
            if size_new <> size_old:
                Utils.pprint ('YELLOW', "Updated po template.")
                try:
                    command = 'intltool-update -r -g %s' % APPNAME
                    Utils.exec_command (command)
                    Utils.pprint ('YELLOW', "Updated translations.")
                except:
                    Utils.pprint ('RED', "Failed to update translations.")
        except:
            traceback.print_exc(file=open("errlog.txt","a"))
            Utils.pprint ('RED', "Failed to generate po template.")
            Utils.pprint ('RED', "Make sure intltool is installed.")
        os.chdir ('..')
        
