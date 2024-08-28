#!/bin/bash
# ------------------------------------------------------------------------------
# Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------------
##
# Name:
#      fqdndef.sh
# Description:
#       A script to wrap the invocation of the fqdndef command in the ECLI.
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
# - 01/08/21 - Paolo Palmieri (epaopal)
#       First version.
##

/usr/bin/sudo /opt/ap/apos/bin/fqdnconfdef.sh "$@"

exit $?
