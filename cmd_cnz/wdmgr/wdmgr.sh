#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       wgmgr.sh
# Description:
#       A script to wrap the invocation of wdmgr from the COM CLI.
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
# - MAR 30 2020 - Sravanthi (xsravan)
#       First version.
##

umask 002
/usr/bin/sudo /opt/ap/apos/bin/wdmgr $@

exit $?

