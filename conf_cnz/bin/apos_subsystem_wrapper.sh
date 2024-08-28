#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_subsystem_wrapper.sh
# Description:
#       A script to launch cliss or simucliss based on the ldap connection.
# Note:
#       Executed only when a ssh connection is established towards ecli.
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Mon Feb 13 2017 - Avinash Gundlapally (xavigun)
#       First version.


source /etc/profile.local

if [ $USER_IS_CACHED -eq $TRUE ]; then
  exec /opt/ap/apos/bin/simucliss
else
  exec /opt/com/bin/cliss
fi

