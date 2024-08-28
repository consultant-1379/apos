#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2014 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       unzipc.sh
# Description:
#       A script to wrap the invocation of unzipc from the COM CLI.
# Note:
#	None.
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:#    
#     - Tuesday 29th of July 2014 - by Gianluigi Crispino (xgiacri)
#       Second version.
#     - Tuesday 15th of July 2014 - by Torgny Wilhelmsson (xtorwil)
#       First version.
##

umask 002
/usr/bin/sudo /opt/ap/apos/bin/unzip "$@"

exit $?

