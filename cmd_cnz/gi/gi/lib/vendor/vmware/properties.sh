#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   netinfo.sh
# Description:
#   A script to fetch the VM deployment properties in a VMware based deployment.
##
# Changelog:
# - Mon 14 2016 - Alessio Cascone (ealocae)
#     First version.
##

# Exit with error in case of unset variables
set -u

# Source of the common_functions file to get common variables
SCRIPT_NAME=$(basename $0)
. "/opt/ap/apos/bin/gi/lib/common/common_functions"
[ $? -ne 0 ] && apos_abort 'Failed to import the common_functions file!'

apos_intro $0

SUBCOMMAND=''
GREP_EXPRESSION="PROPERTIES:"
if [ $# -eq 1 ];then
  SUBCOMMAND=$1
  GREP_EXPRESSION="PROPERTIES:$SUBCOMMAND="
elif [ $# -ne 0 ]; then
  apos_abort 'Incorrect usage.'
fi

PROPERTIES_ALLOWED_FETCH_METHODS="ovfenv vmtools"
TEMP_FILE=$($CMD_MKTEMP -t ${SCRIPT_NAME}.XXXXXX)
for FETCH_METHOD in $PROPERTIES_ALLOWED_FETCH_METHODS
do
  /opt/ap/apos/bin/gi/lib/fetch_method/${FETCH_METHOD}.sh | $CMD_GREP 'PROPERTIES:' | $CMD_GREP "$GREP_EXPRESSION" | $CMD_AWK -F 'PROPERTIES:' '{print $2}' > $TEMP_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failed to fetch VM deployment properties information."
  fi
  if [ -s "$TEMP_FILE" ]; then
    break
  fi
done

$CMD_CAT $TEMP_FILE
$CMD_RM -f $TEMP_FILE

apos_outro $0

# End of file

