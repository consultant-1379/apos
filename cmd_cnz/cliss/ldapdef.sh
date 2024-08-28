#!/bin/bash
# ------------------------------------------------------------------------
# Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      ldapconfig.sh
# Description:
#       A script to wrap the invocation of ldapdef the COM CLI.
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
# - 09/10/15 - Antonio Buonocunto (eanbuon)
#       First version.
##

/usr/bin/sudo /opt/ap/apos/bin/ldapconfig.sh "$@"

exit $?