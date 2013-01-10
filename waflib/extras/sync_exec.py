#! /usr/bin/env python
# encoding: utf-8

"""
Force the execution output to be synchronized
May deadlock with a lot of output (subprocess limitation)
"""

import sys
from waflib.Build import BuildContext
from waflib import Utils, Logs

def exec_command(self, cmd, **kw):
	subprocess = Utils.subprocess
	kw['shell'] = isinstance(cmd, str)
	Logs.debug('runner: %r' % cmd)
	Logs.debug('runner_env: kw=%s' % kw)
	try:
		kw['stdout'] = kw['stderr'] = subprocess.PIPE
		p = subprocess.Popen(cmd, **kw)
		(out, err) = p.communicate()
		if out:
			sys.stdout.write(out.decode(sys.stdout.encoding or 'iso8859-1'))
		if err:
			sys.stdout.write(err.decode(sys.stdout.encoding or 'iso8859-1'))
		return p.returncode
	except OSError:
		return -1

BuildContext.exec_command = exec_command

