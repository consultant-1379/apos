#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       ver.sh
# Description:
#       A script to wrap the invocation of ver from the COM CLI.
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
# - Tue Jul 24 2012 - Francesco Rainone (efrarai)
#	First version.
##

/usr/bin/sudo /opt/ap/apos/bin/ver "$@"

exit $?
