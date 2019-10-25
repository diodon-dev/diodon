#! /usr/bin/env python
# encoding: utf-8
# Oliver Sauder, 2010

import os
import random
import signal
import subprocess
import tempfile
import time
import traceback
from subprocess import PIPE, Popen

import Logs
import Options
from waflib.Build import BuildContext
from waflib.Tools import waf_unit_test

NAME = 'Diodon'
VERSION = '1.8.0'
APPNAME = 'diodon'
WEBSITE = 'https://launchpad.net/diodon'
COPYRIGHT = 'Copyright \xc2\xa9 2010-2018 Diodon Team'
BUSNAME = 'net.launchpad.Diodon'
BUSOBJECTPATH = '/net/launchpad/diodon'

VERSION_MAJOR_MINOR = '.'.join(VERSION.split('.')[0:2])
VERSION_MAJOR = '.'.join(VERSION.split('.')[0:1])
top = '.'
out = '_build_'


class CustomBuildContext(BuildContext):
    zeitgeist_process = None
    display_process = None


def options(opt):
    opt.tool_options('compiler_c')
    opt.tool_options('waf_unit_test')
    opt.tool_options('vala')
    opt.tool_options('gnu_dirs')
    opt.tool_options('intltool')
    opt.tool_options('glib2')
    opt.add_option('--update-po',                action='store_true', default=False, dest='update_po', help='Update localization files')
    opt.add_option('--debug',                    action='store_true', default=False, dest='debug',     help='Debug mode')
    opt.add_option('--disable-indicator-plugin', action='store_true', default=False, dest='disable_indicator', help='Disable build of indicator plugin')
    opt.add_option('--enable-unityscope',        action='store_true', default=False, dest='enable_unityscope', help='Enable build of unity scope')
    opt.add_option('--build-doc',                action='store_true', default=False, dest='doc', help='Build the api documentation')
    opt.add_option('--skiptests',                action='store_true', default=False, dest='skiptests', help='Skip unit tests')


def configure(conf):
    conf.load('compiler_c intltool gnu_dirs glib2 waf_unit_test')
    if Options.options.doc:
        conf.load('valadoc')

    conf.load('vala', funs='')
    conf.check_vala(min_version=(0, 30, 0))

    conf.check_cfg(package='gdk-3.0',           uselib_store='GDK',          atleast_version='3.0.8',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gdk-x11-3.0',       uselib_store='GDKX',         atleast_version='3.0.8',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='libpeas-1.0',       uselib_store='PEAS',         atleast_version='1.1.0',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='libpeas-gtk-1.0',   uselib_store='PEASGTK',      atleast_version='1.1.0',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gio-2.0',           uselib_store='GIO',          atleast_version='2.32.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gio-unix-2.0',      uselib_store='GIOUNIX',      atleast_version='2.32.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='glib-2.0',          uselib_store='GLIB',         atleast_version='2.32.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='gtk+-3.0',          uselib_store='GTK',          atleast_version='3.10.0',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='x11',               uselib_store='X11',          atleast_version='1.2.0',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='xtst',              uselib_store='XTST',         atleast_version='1.2.0',  mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='zeitgeist-2.0',     uselib_store='ZEITGEIST',    atleast_version='0.9.14', mandatory=1, args='--cflags --libs')

    conf.find_program('Xvfb', var='XVFB')

    # FIXME: waf throws up when assigning an empty string
    # we need a better way of configuring plugins which are enabled
    # by default anyway
    ACTIVE_PLUGINS = ' '
    # check if indicator plugin should be built
    conf.env['INDICATOR'] = not(Options.options.disable_indicator)
    if not(Options.options.disable_indicator):
        conf.check_cfg(package='appindicator3-0.1', uselib_store='APPINDICATOR', atleast_version='0.3.0',  mandatory=1, args='--cflags --libs')
        ACTIVE_PLUGINS = "'indicator'"

    # check if unity scope plugin should be built
    conf.env['UNITYSCOPE'] = Options.options.enable_unityscope
    if Options.options.enable_unityscope:
        conf.check_cfg(package='unity', uselib_store='UNITY', atleast_version='7.1.0', mandatory=1, args='--cflags --libs')

    # FIXME: conf.env and conf.define should not both be needed?
    conf.define('PACKAGE_NAME', APPNAME)
    conf.env['PACKAGE_NAME'] = APPNAME
    conf.define('ACTIVE_PLUGINS', ACTIVE_PLUGINS)
    conf.env['ACTIVE_PLUGINS'] = ACTIVE_PLUGINS
    conf.define('GETTEXT_PACKAGE', APPNAME)
    conf.env['GETTEXT_PACKAGE'] = APPNAME
    conf.define('VERSION', VERSION)
    conf.env['VERSION'] = VERSION
    conf.define('COPYRIGHT', COPYRIGHT)
    conf.define('WEBSITE', WEBSITE)
    conf.define('APPNAME', NAME)
    conf.define('BUSNAME', BUSNAME)
    conf.env['BUSNAME'] = BUSNAME
    conf.define('BUSOBJECTPATH', BUSOBJECTPATH)
    conf.env['BUSOBJECTPATH'] = BUSOBJECTPATH
    conf.define('SHAREDIR', os.path.join(conf.env['DATADIR'], APPNAME))
    conf.define('LIBDIR_DIODON', os.path.join(conf.env['LIBDIR'], APPNAME))
    conf.env['LIBDIR_DIODON'] = os.path.join(conf.env['LIBDIR'], APPNAME)
    conf.define('PLUGINS_DIR', os.path.join(conf.env['LIBDIR'], APPNAME, 'plugins'))
    conf.env['PLUGINS_DIR'] = os.path.join(conf.env['LIBDIR'], APPNAME, 'plugins')
    conf.define('PLUGINS_DATA_DIR', os.path.join(conf.env['DATADIR'], APPNAME, 'plugins'))
    conf.define('TEST_DATA_DIR', conf.path.abspath() + '/tests/data/')

    # set 'default' variant
    conf.define('DEBUG', 0)
    # honor preset CFLAGS env vars
    if not conf.env['CFLAGS']:
        conf.env['CFLAGS'] += ['-O2']
    # in any case we need to ignore warnings as C-code is generated
    conf.env['CFLAGS'] += ['-w']
    conf.env['VALAFLAGS'] = ['--disable-assert']

    # set some debug relevant config values
    if Options.options.debug:
        conf.define('DEBUG', 1)
        conf.env['CFLAGS'] += ['-O0', '-g3', '-w']
        conf.env['VALAFLAGS'] = ['-g', '-v', '--enable-checking']

    conf.write_config_header('config.h', remove=False)


def build(ctx):
    ctx.add_subdirs('po data libdiodon plugins diodon')

    if ctx.env['UNITYSCOPE']:
        ctx.add_subdirs('unity-scope-diodon')

    if not Options.options.skiptests:
        ctx.add_subdirs('tests')
        if ctx.cmd == 'build':
            ctx.add_pre_fun(setup_tests)
            ctx.add_post_fun(teardown_tests)

    if ctx.env['VALADOC']:
        ctx.add_subdirs('doc')
    ctx.add_post_fun(post)

    # to execute all tests:
    # $ waf --alltests
    # to set this behaviour permanenly:
    ctx.options.all_tests = True


def setup_tests(ctx):
    ctx.display_process = start_display(ctx)

    # only when integration tests are run does the zeitgeist service
    # need to be started
    if getattr(Options.options, 'testcmd', False):
        ctx.zeitgeist_process = start_zeitgeist_daemon(ctx)


def teardown_tests(ctx):
    stop_display(ctx)

    if ctx.zeitgeist_process:
        stop_zeitgeist_daemon(ctx.zeitgeist_process)

    # write test summary
    waf_unit_test.summary(ctx)

    # Ensure that all tests have passed, if not log errors
    lst = getattr(ctx, 'utest_results', [])
    if lst:
        tfail = len([x for x in lst if x[1]])
        if tfail:
            for (filename, returncode, stdout, stderr) in lst:
                Logs.warn(stdout)
                Logs.warn(stderr)

            ctx.fatal("Some test failed.")


def start_display(ctx):
    devnull = open("/dev/null", "w")
    display = ":%d" % random.randint(20, 100)
    display_process = Popen([ctx.env.get_flat('XVFB'), display, "-screen", "0", "1024x768x8"], stderr=devnull, stdout=devnull)
    # give the display some time to wake up
    time.sleep(1)
    err = display_process.poll()
    if err:
        raise RuntimeError("Could not start Xvfb on display %s, got err=%i" % (display, err))

    os.environ.update({"DISPLAY": display})
    return display_process


def stop_display(ctx):
    os.kill(ctx.display_process.pid, signal.SIGKILL)
    ctx.display_process.wait()


# TODO: is this really the best spot to start the zeitgeist daemon?
def start_zeitgeist_daemon(ctx):
    """
    start zeitgeist daemon writing to temporary data path
    """
    zg_env = os.environ.copy()
    datapath = tempfile.mkdtemp(prefix="zeitgeist.datapath.")
    zg_env.update({
        "ZEITGEIST_DATABASE_PATH": ":memory:",
        "ZEITGEIST_DATA_PATH": datapath,
        "XDG_CACHE_HOME": os.path.join(datapath, "cache"),
    })
    args = {'env': zg_env}
    args['stderr'] = PIPE
    args['stdout'] = PIPE
    zeitgeist_process = Popen(('zeitgeist-daemon', '--replace', '--no-datahub'), **args)

    # give the process some time to wake up
    time.sleep(1)

    # raise runtime error if process failed to start
    error = zeitgeist_process.poll()
    if error:
        error = "zeitgeist-daemon exits with error %i." % (error)
        raise RuntimeError(error)

    Logs.info("Started Zeitgeist Daemon with pid %u" % zeitgeist_process.pid)
    return zeitgeist_process


def stop_zeitgeist_daemon(zeitgeist_process):
    """
    Kill started test zeitgeist daemon
    """
    os.kill(zeitgeist_process.pid, signal.SIGKILL)
    zeitgeist_process.wait()
    Logs.info("Stopped Zeitgeist Daemon with pid %u" % zeitgeist_process.pid)


def post(ctx):
    if ctx.cmd == 'install':
        ctx.exec_command('/sbin/ldconfig')


def dist(ctx):
    # set the compression type to gzip (default is bz2)
    ctx.algo = "tar.gz"


def shutdown(self):
    if Options.options.update_po:
        os.chdir('./po')
        try:
            try:
                size_old = os.stat(APPNAME + '.pot').st_size
            except:
                size_old = 0
            subprocess.call(['intltool-update', '-p', '-g', APPNAME])
            size_new = os.stat(APPNAME + '.pot').st_size
            if size_new != size_old:
                Logs.info("Updated po template.")
                try:
                    command = 'intltool-update -r -g %s' % APPNAME
                    self.exec_command(command)
                    Logs.info("Updated translations.")
                except:
                    Logs.error("Failed to update translations.")
        except:
            traceback.print_exc(file=open("errlog.txt", "a"))
            Logs.error("Failed to generate po template.")
            Logs.errors("Make sure intltool is installed.")
        os.chdir('..')
