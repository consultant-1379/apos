#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       cdadm.sh
# Description:
#       A script to wrap the invocation of cdadm as root
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
#     - Jun 21 2016 - Antonio Buonocunto (EANBUON)
#       First version.
##

/usr/bin/sudo /opt/ap/apos/bin/cdadm "$@"

exit $?

