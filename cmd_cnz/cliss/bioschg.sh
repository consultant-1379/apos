#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       bioschg.sh
# Description:
#       A script to wrap the invocation of bioschg from the COM CLI.
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
# - Mon Apr 08 2013 - Francesco Rainone (efrarai)
#	Update to follow command renaming to bioschg.
# - Tue Mar 12 2013 - Pratap Reddy (xpraupp)
#	First version.
##

/usr/bin/sudo /opt/ap/apos/bin/bioschg "$@"

exit $?
