#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       netdef.sh
# Description:
#       A script to wrap the invocation of netdef from the COM CLI.
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
# - Mon Oct 01 2012 - Paolo Palmieri (epaopal)
#	First version.
##

/usr/bin/sudo /opt/ap/apos/bin/netls "$@"

exit $?
