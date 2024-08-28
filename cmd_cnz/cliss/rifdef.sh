#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       rifdef.sh
# Description:
#       A script to wrap the invocation of rifdef from the COM CLI.
# Note:
#	None.
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:
#     - Wednesday 17th of July 2013 - by Torgny Wilhelmsson (xtorwil)
#       Based on script psls
#       just change psls to rifdef
#       First version.
##

umask 002
/usr/bin/sudo /opt/ap/apos/bin/rifdef "$@"

exit $?
