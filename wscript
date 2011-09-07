#! /usr/bin/env python
# encoding: utf-8
# Oliver Sauder, 2010

import subprocess, os, traceback
import Options, Logs

NAME = 'Diodon'
VERSION = '0.5.0'
APPNAME = 'diodon'
WEBSITE = 'https://launchpad.net/diodon'
COPYRIGHT = 'Copyright \xc2\xa9 2010 Diodon Team'
BUSNAME = 'net.launchpad.Diodon'
BUSOBJECTPATH = '/net/launchpad/diodon'
CLIPBOARD_URI = 'clipboard://'

VERSION_MAJOR_MINOR = '.'.join (VERSION.split ('.')[0:2])
VERSION_MAJOR = '.'.join (VERSION.split ('.')[0:1])
top = '.'
out = '_build_'

def options(opt):
    opt.tool_options('compiler_c')
    opt.tool_options('vala')
    opt.tool_options('gnu_dirs')
    opt.tool_options('intltool')
    opt.tool_options('glib2')
    opt.add_option('--update-po',         action='store_true', default=False, dest='update_po', help='Update localization files')
    opt.add_option('--debug',             action='store_true', default=False, dest='debug',     help='Debug mode')
    opt.add_option('--enable-unity-lens', action='store_true', default=False, dest='unity_lens', help='Enable unity lens support')

def configure(conf):
    conf.load('compiler_c intltool gnu_dirs glib2')
    
    conf.load('vala', funs='')
    conf.check_vala(min_version=(0,13,0))
    
    conf.check_cfg(package='appindicator3-0.1', uselib_store='APPINDICATOR', atleast_version='0.3.0',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gdk-x11-3.0',       uselib_store='GDKX',         atleast_version='3.0.8',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gee-1.0',           uselib_store='GEE',          atleast_version='0.5.0',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gio-2.0',           uselib_store='GIO',          atleast_version='2.26.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gio-unix-2.0',      uselib_store='GIOUNIX',      atleast_version='2.26.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='glib-2.0',          uselib_store='GLIB',         atleast_version='2.26.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gtk+-3.0',          uselib_store='GTK',          atleast_version='3.0.8',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='libxml-2.0',        uselib_store='XML',          atleast_version='2.7.6',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='x11',               uselib_store='X11',          atleast_version='1.3.2',  mandatory=1, args='--cflags --libs')
    
    # check if unity lens should be built
    if Options.options.unity_lens:
        conf.check_cfg(package='unity',   uselib_store='UNITY', atleast_version='4.0.0',  mandatory=1, args='--cflags --libs')
        conf.check_cfg(package='dee-1.0', uselib_store='DEE',   atleast_version='0.5.18', mandatory=1, args='--cflags --libs')

    conf.define('PACKAGE_NAME', APPNAME)
    conf.define('GETTEXT_PACKAGE', APPNAME)
    conf.env['GETTEXT_PACKAGE'] = APPNAME
    conf.define('VERSION', VERSION)
    conf.define('COPYRIGHT', COPYRIGHT)
    conf.define('WEBSITE', WEBSITE)
    conf.define('APPNAME', NAME)
    conf.define('BUSNAME', BUSNAME)
    conf.env['BUSNAME'] = BUSNAME
    conf.define('BUSOBJECTPATH', BUSOBJECTPATH)
    conf.env['BUSOBJECTPATH'] = BUSOBJECTPATH
    conf.define('SHAREDIR', os.path.join(conf.env['DATADIR'], APPNAME))
    conf.define('CLIPBOARD_URI', CLIPBOARD_URI)
      
    # set 'default' variant
    conf.define ('DEBUG', 0)
    conf.env['CFLAGS']=['-O2']
    conf.env['VALAFLAGS'] = ['--disable-assert']
    
    # set some debug relevant config values
    if Options.options.debug:
        conf.define ('DEBUG', 1)
        conf.env['CFLAGS'] = ['-O0', '-g3']
        conf.env['VALAFLAGS'] = ['-g', '-v', '--enable-checking']

    conf.write_config_header ('config.h', remove=False)
   
def build(bld):
    bld.add_subdirs('po data src')

def dist(ctx):
    # set the compression type to gzip (default is bz2)
    ctx.algo = "tar.gz"
  
def shutdown(self):
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
                Logs.info("Updated po template.")
                try:
                    command = 'intltool-update -r -g %s' % APPNAME
                    self.exec_command (command)
                    Logs.info("Updated translations.")
                except:
                    Logs.error("Failed to update translations.")
        except:
            traceback.print_exc(file=open("errlog.txt","a"))
            Logs.error("Failed to generate po template.")
            Logs.errors("Make sure intltool is installed.")
        os.chdir ('..')
        
