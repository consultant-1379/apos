#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       rpskeymgmt.sh
# Description:
#       A script to wrap the invocation of rpskeymgmt as root
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
#     - Aug 27 2021 - Neelam Pawan Kumar (XNEELKU)
#       First version.
##

/usr/bin/sudo /opt/ap/apos/bin/rpskeymgmt "$@"

exit $?

