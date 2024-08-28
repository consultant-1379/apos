#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2014 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       httpmgr.sh
# Description:
#       A script to wrap the invocation of httpmgr as root
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
#     - Sep 19 2014 - Fabrizio Paglia (XFABPAG)
#       First version.
##

/usr/bin/sudo /opt/ap/apos/bin/httpmgr "$@"

exit $?

