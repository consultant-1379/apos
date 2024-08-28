#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apg-adm.sh
# Description:
#       A script to invocation of  apg-adm python script from CLI.
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
# - Tue Sep 25 2018 - Paolo
#       First version.
##

python /opt/ap/apos/bin/apg-adm.py "$@"

exit $?

