#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       raidmgr_md.sh
# Description:
#       A script to wrap the invocation of raidmgr from the COM CLI.
# Note:
#       None.
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Tue Jul 24 2012 - Francesco Rainone (efrarai)
#       First version.
##

umask 002
/usr/bin/sudo /opt/ap/apos/bin/raidmgr "$@"

exit $?
