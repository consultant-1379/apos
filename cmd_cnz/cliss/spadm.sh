#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       spadm.sh
# Description:
#       A script to enable/disable the mitigations of security patches.
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
# - Wed Mar 20 2019 - Anjali M (xanjali)
#       First version
##

Gid=$(/usr/bin/id -g)

if [[ $Gid == 0 ||  $Gid == 1003 ]];then
    /bin/logger 'spadm execution started'
else
    echo -e "ERROR: Not authorized to execute 'spadm'"
    exit 1
fi

/usr/bin/sudo /opt/ap/apos/bin/spadm "$@"

exit $?

