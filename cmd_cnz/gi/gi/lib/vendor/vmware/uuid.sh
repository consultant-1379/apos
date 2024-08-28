#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   uuid.sh
# Description:
#   A script to fetch the VM UUID value in a VMware based deployment.
##
# Changelog:
# - Mon 14 2016 - Alessio Cascone (ealocae)
#     First version.
##

# Exit with error in case of unset variables
set -u

# Source of the common_functions file to get common variables
. "/opt/ap/apos/bin/gi/lib/common/common_functions"
[ $? -ne 0 ] && apos_abort 'Failed to import the common_functions file!'

apos_intro $0

if [ $# -ne 0 ];then
  apos_abort 'Incorrect usage.'
fi

UUID_ALLOWED_FETCH_METHODS="ovfenv vmtools"
FOUND=$FALSE
for FETCH_METHOD in $UUID_ALLOWED_FETCH_METHODS
do
  /opt/ap/apos/bin/gi/lib/fetch_method/${FETCH_METHOD}.sh | $CMD_GREP 'UUID:' | $CMD_AWK -F 'UUID:' '{print $2}'
  if [ $? -eq 0 ]; then
    FOUND=$TRUE
    break
  fi
done

[ $FOUND -eq $FALSE ] && apos_abort 'Failed to fetch UUID information.'

apos_outro $0

# End of file

