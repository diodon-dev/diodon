#!/usr/bin/env python
# encoding: utf-8
# Ali Sabil, 2007
# Radosław Szkodziński, 2010

"""
At this point, vala is still unstable, so do not expect
this tool to be too stable either (apis, etc)
"""

import os.path, shutil, re
from waflib import Context, Task, Utils, Logs, Options, Errors
from waflib.TaskGen import extension
from waflib.Configure import conf

class valac(Task.Task):
	"""
	Task to compile vala files.
	"""
	vars = ["VALAC", "VALAC_VERSION", "VALAFLAGS"]
	ext_out = ['.h']

	def run(self):
		env = self.env

		cmd = [env['VALAC'], '-C', '--quiet']
		cmd.extend(Utils.to_list(env['VALAFLAGS']))

		if self.threading:
			cmd.append('--thread')

		if self.profile:
			cmd.append('--profile=%s' % self.profile)

		if self.target_glib:
			cmd.append('--target-glib=%s' % self.target_glib)

		if self.is_lib:
			cmd.append('--library=' + self.target)
			for x in self.outputs:
				if x.name.endswith('.h'):
					cmd.append('--header=' + x.name)
			if self.gir:
				cmd.append('--gir=%s.gir' % self.gir)

		for vapi_dir in self.vapi_dirs:
			cmd.append('--vapidir=%s' % vapi_dir)

		for package in self.packages:
			cmd.append('--pkg=%s' % package)

		for package in self.packages_private:
			cmd.append('--pkg=%s' % package)

		for define in self.vala_defines:
			cmd.append('--define=%s' % define)

		cmd.extend([a.abspath() for a in self.inputs])
		ret = self.exec_command(cmd, cwd=self.outputs[0].parent.abspath())

		if ret:
			return ret

		for x in self.outputs:
			if id(x.parent) != id(self.outputs[0].parent):
				shutil.move(self.outputs[0].parent.abspath() + os.sep + x.name, x.abspath())

		if self.packages and getattr(self, 'deps_node', None):
			self.deps_node.write('\n'.join(self.packages))

		return ret

@extension('.vala', '.gs')
def vala_file(self, node):
	"""
	Compile a vala file and bind the task to *self.valatask*. If an existing vala task is already set, add the node
	to its inputs. The typical example is::

		def build(bld):
			bld.program(
				packages      = 'gtk+-2.0',
				target        = 'vala-gtk-example',
				uselib        = 'GTK GLIB',
				source        = 'vala-gtk-example.vala foo.vala',
				vala_defines  = ['DEBUG']
				# the following arguments are for libraries
				#gir          = 'hello-1.0',
				#gir_path     = '/tmp',
				#vapi_path = '/tmp',
				#pkg_name = 'hello'
				# disable installing of gir, vapi and header
				#install_binding = False
			)


	:param node: vala file
	:type node: :py:class:`waflib.Node.Node`
	"""
	# TODO: the vala task should use self.generator.attribute instead of copying attributes from self to the task
	valatask = getattr(self, "valatask", None)
	# there is only one vala task and it compiles all vala files .. :-/
	if not valatask:
		def _get_api_version():
			api_version = '1.0'
			if hasattr(Context.g_module, 'API_VERSION'):
				version = Context.g_module.API_VERSION.split(".")
				if version[0] == "0":
					api_version = "0." + version[1]
				else:
					api_version = version[0] + ".0"
			return api_version

		valatask = self.create_task('valac')
		self.valatask = valatask # this assumes one vala task by task generator
		self.includes = Utils.to_list(getattr(self, 'includes', []))
		self.uselib = self.to_list(getattr(self, 'uselib', []))
		valatask.packages = []
		valatask.packages_private = Utils.to_list(getattr(self, 'packages_private', []))
		valatask.vapi_dirs = []
		valatask.target = self.target
		valatask.threading = False
		valatask.install_path = getattr(self, 'install_path', '')
		valatask.profile = getattr(self, 'profile', 'gobject')
		valatask.vala_defines = getattr(self, 'vala_defines', [])
		valatask.target_glib = None
		valatask.gir = getattr(self, 'gir', None)
		valatask.gir_path = getattr(self, 'gir_path', '${DATAROOTDIR}/gir-1.0')
		valatask.vapi_path = getattr(self, 'vapi_path', '${DATAROOTDIR}/vala/vapi')
		valatask.pkg_name = getattr(self, 'pkg_name', self.env['PACKAGE'])
		valatask.header_path = getattr(self, 'header_path', '${INCLUDEDIR}/%s-%s' % (valatask.pkg_name, _get_api_version()))
		valatask.install_binding = getattr(self, 'install_binding', True)

		valatask.is_lib = False
		if not 'cprogram' in self.features:
			valatask.is_lib = True

		packages = Utils.to_list(getattr(self, 'packages', []))
		vapi_dirs = Utils.to_list(getattr(self, 'vapi_dirs', []))
		includes =  []

		if hasattr(self, 'use'):
			local_packages = Utils.to_list(self.use)[:] # make sure to have a copy
			seen = []
			while len(local_packages) > 0:
				package = local_packages.pop()
				if package in seen:
					continue
				seen.append(package)

				# check if the package exists
				try:
					package_obj = self.bld.get_tgen_by_name(package)
				except Errors.WafError:
					continue
				package_name = package_obj.target
				package_node = package_obj.path
				package_dir = package_node.path_from(self.path)

				for task in package_obj.tasks:
					for output in task.outputs:
						if output.name == package_name + ".vapi":
							valatask.set_run_after(task)
							if package_name not in packages:
								packages.append(package_name)
							if package_dir not in vapi_dirs:
								vapi_dirs.append(package_dir)
							if package_dir not in includes:
								includes.append(package_dir)

				if hasattr(package_obj, 'use'):
					lst = self.to_list(package_obj.use)
					lst.reverse()
					local_packages = [pkg for pkg in lst if pkg not in seen] + local_packages

		valatask.packages = packages
		for vapi_dir in vapi_dirs:
			try:
				valatask.vapi_dirs.append(self.path.find_dir(vapi_dir).abspath())
				valatask.vapi_dirs.append(self.path.find_dir(vapi_dir).get_bld().abspath())
			except AttributeError:
				Logs.warn("Unable to locate Vala API directory: '%s'" % vapi_dir)

		self.includes.append(self.bld.srcnode.abspath())
		self.includes.append(self.bld.bldnode.abspath())
		for include in includes:
			try:
				self.includes.append(self.path.find_dir(include).abspath())
				self.includes.append(self.path.find_dir(include).get_bld().abspath())
			except AttributeError:
				Logs.warn("Unable to locate include directory: '%s'" % include)


		if valatask.profile == 'gobject':
			if hasattr(self, 'target_glib'):
				Logs.warn('target_glib on vala tasks is not supported --vala-target-glib=MAJOR.MINOR from the vala tool options')

			if getattr(Options.options, 'vala_target_glib', None):
				valatask.target_glib = Options.options.vala_target_glib

			if not 'GOBJECT' in self.uselib:
				self.uselib.append('GOBJECT')

		if hasattr(self, 'threading'):
			if valatask.profile == 'gobject':
				valatask.threading = self.threading
				if not 'GTHREAD' in self.uselib:
					self.uselib.append('GTHREAD')
			else:
				#Vala doesn't have threading support for dova nor posix
				Logs.warn("Profile %s does not have threading support" % valatask.profile)

		if valatask.is_lib:
			valatask.outputs.append(self.path.find_or_declare('%s.h' % self.target))
			valatask.outputs.append(self.path.find_or_declare('%s.vapi' % self.target))

			if valatask.gir:
				valatask.outputs.append(self.path.find_or_declare('%s.gir' % self.gir))

			if valatask.packages:
				d = self.path.find_or_declare('%s.deps' % self.target)
				valatask.outputs.append(d)
				valatask.deps_node = d

	valatask.inputs.append(node)
	c_node = node.change_ext('.c')

	valatask.outputs.append(c_node)
	self.source.append(c_node)

	if valatask.is_lib and valatask.install_binding:
		headers_list = [o for o in valatask.outputs if o.suffix() == ".h"]
		try:
			self.install_vheader.source = headers_list
		except AttributeError:
			self.install_vheader = self.bld.install_files(valatask.header_path, headers_list, self.env)

		vapi_list = [o for o in valatask.outputs if (o.suffix() in (".vapi", ".deps"))]
		try:
			self.install_vapi.source = vapi_list
		except AttributeError:
			self.install_vapi = self.bld.install_files(valatask.vapi_path, vapi_list, self.env)

		gir_list = [o for o in valatask.outputs if o.suffix() == ".gir"]
		try:
			self.install_gir.source = gir_list
		except AttributeError:
			self.install_gir = self.bld.install_files(valatask.gir_path, gir_list, self.env)

valac = Task.update_outputs(valac) # no decorators for python2 classes

@conf
def find_valac(self, valac_name, min_version):
	"""
	Find the valac program, and execute it to store the version
	number in *conf.env.VALAC_VERSION*

	:param valac_name: program name
	:type valac_name: string or list of string
	:param min_version: minimum version acceptable
	:type min_version: tuple of int
	"""
	valac = self.find_program(valac_name, var='VALAC')
	try:
		output = self.cmd_and_log(valac + ' --version')
	except Exception:
		valac_version = None
	else:
		ver = re.search(r'\d+.\d+.\d+', output).group(0).split('.')
		valac_version = tuple([int(x) for x in ver])

	self.msg('Checking for %s version >= %r' % (valac_name, min_version),
	         valac_version, valac_version and valac_version >= min_version)
	if valac and valac_version < min_version:
		self.fatal("%s version %r is too old, need >= %r" % (valac_name, valac_version, min_version))

	self.env['VALAC_VERSION'] = valac_version
	return valac

@conf
def check_vala(self, min_version=(0,8,0), branch=None):
	"""
	Check if vala compiler from a given branch exists of at least a given
	version.

	:param min_version: minimum version acceptable (0.8.0)
	:type min_version: tuple
	:param branch: first part of the version number, in case a snapshot is used (0, 8)
	:type branch: tuple of int
	"""
	if not branch:
		branch = min_version[:2]
	try:
		find_valac(self, 'valac-%d.%d' % (branch[0], branch[1]), min_version)
	except self.errors.ConfigurationError:
		find_valac(self, 'valac', min_version)

@conf
def check_vala_deps(self):
	"""
	Load the gobject and gthread packages if they are missing.
	"""
	if not self.env['HAVE_GOBJECT']:
		pkg_args = {'package':      'gobject-2.0',
		            'uselib_store': 'GOBJECT',
		            'args':         '--cflags --libs'}
		if getattr(Options.options, 'vala_target_glib', None):
			pkg_args['atleast_version'] = Options.options.vala_target_glib
		self.check_cfg(**pkg_args)

	if not self.env['HAVE_GTHREAD']:
		pkg_args = {'package':      'gthread-2.0',
		            'uselib_store': 'GTHREAD',
		            'args':         '--cflags --libs'}
		if getattr(Options.options, 'vala_target_glib', None):
			pkg_args['atleast_version'] = Options.options.vala_target_glib
		self.check_cfg(**pkg_args)

def configure(self):
	"""
	Use the following to enforce minimum vala version::

		def configure(conf):
			conf.load('vala', funs='')
			conf.check_vala(min_version=(0,10,0))
	"""
	self.load('gnu_dirs')
	self.check_vala_deps()
	self.check_vala()

def options(opt):
	"""
	Load the :py:mod:`waflib.Tools.gnu_dirs` tool and add the ``--vala-target-glib`` command-line option
	"""
	opt.load('gnu_dirs')
	valaopts = opt.add_option_group('Vala Compiler Options')
	valaopts.add_option ('--vala-target-glib', default=None,
		dest='vala_target_glib', metavar='MAJOR.MINOR',
		help='Target version of glib for Vala GObject code generation')

