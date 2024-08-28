#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       traceroute6.sh
# Description:
#       A script to wrap the invocation of traceroute6 from the COM CLI.
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
# - Tue Apr 21 2020 - Bipin Polabathina (xbippol)
#	First version.	
##

/usr/bin/sudo /opt/ap/apos/bin/traceroute6 "$@"

exit $?
