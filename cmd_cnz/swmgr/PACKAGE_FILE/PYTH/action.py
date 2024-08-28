#!/usr/bin/env python
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   action.py
# Description:
#   A python script to invoke all import, activate and cleanup actioins for
#   applying the patch software.
#
##
# Changelog:
# - Mon Apr 16 2018 - Malangsha Shaik (XMALSHA)
#     First version.
##

import subprocess
import os
import sys

def Cmd():
  received_action = sys.argv[1]
  currdir = os.getcwd()
  Cmd  = currdir + '/' + received_action + '.sh'
  return Cmd

def LogFile():
  received_action = sys.argv[1]
  currdir = os.getcwd()
  filename  = currdir + '/../LOG/' + received_action + '.log'
  return filename

def log(message):
  filename = LogFile()
  if os.path.exists(filename):
      os.remove(filename)

  try:
    with open(filename, 'w') as f:
      f.write(message)
      f.close()

  except IOError as err:
      sys.stderr.write('NOT OK {0}\n'.format(err))
      return 1
  return 0

def main():
  """
  A template implementation for launching the shell script.
  """

  if len(sys.argv) != 2 :
    sys.stderr.write('NOT OK: Expected Args: 1, Recived: {0}\n'.format(sys.argv[1:]))
    return 1

  supported_actions = ('activate', 'import', 'erase')
  received_action = sys.argv[1]
  if received_action not in supported_actions:
    sys.stderr.write('NOT OK [ Expected: \'{0}\'; Received: \'{1}\']\n'.format(supported_actions, sys.argv[1]))
    return 1

  launchCmd = Cmd()
  process = subprocess.Popen([launchCmd], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  process.wait()

  if process.returncode is 0:
    log(received_action + ' success!!\n')
  else:
    log(received_action + ' failed!!\n')
    return 1

  return 0

if __name__ == '__main__':
  sys.exit(main())

