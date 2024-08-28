#!/bin/bash
#
# Copyright (C) 2015 by Ericsson AB
#
##
# Name:
#       postinstall
# Description:
#       A script to perform APG configurations.
# Note:
#       Invoked by AIT_TA after LDE and CoreMW installation on both the Nodes of vAPG.
##
# Usage:
#       Used during vAPG maiden installation.
##
# Output:
#       None.
##
# Changelog:
# - Mon Nov 30 2015 - Nikhila Sattala (XNIKSAT)
#   First version.

PLUGIN_SCRIPTS_ROOT="$(dirname "$(readlink -f $0)")"
if [ ! -d "${PLUGIN_SCRIPTS_ROOT}" ]; then
  echo "${PLUGIN_SCRIPTS_ROOT} not found...exiting" >&2
  exit 1
fi

COMMON_FUNCTIONS="${PLUGIN_SCRIPTS_ROOT}/non_exec-common_functions"
if [ ! -r "$COMMON_FUNCTIONS" ]; then
  echo 'COMMON_FUNCTIONS not found...exiting' >&2
  exit 1
fi

export PLUGIN_SCRIPTS_ROOT
. ${COMMON_FUNCTIONS}

# global variables
CMD_ECHO="/bin/echo"
HW_TYPE=''

$CMD_ECHO "$0"

#### M A I N ####
main(){
  $CMD_ECHO "--- main() begin"
  FACTORY_FILE='/cluster/storage/system/config/lde/csm/templates/config/initial/ldews.os/factoryparam.conf'
  CMD_GREP='/usr/bin/grep'
  CMD_AWK='/usr/bin/awk'
  if [ -f $FACTORY_FILE ];  then
    is_vm=$(cat $FACTORY_FILE | $CMD_GREP -i installation_hw | $CMD_AWK -F "=" '{print $2}')
    if [ "$is_vm" == "VM" ];  then

      local POSTINSTALL_PLUGIN_PATH="${PLUGIN_SCRIPTS_ROOT}/postinstall"
      [ $THIS_ID -ne 2 ] && abort "This script shall be invoked only on SC-2-2."
  
      # Fetch hardware type
      HW_TYPE=$(get_hwtype)
      [ -z "$HW_TYPE" ] && abort "HW_TYPE found NULL!!"
 
      pushd ${POSTINSTALL_PLUGIN_PATH} >/dev/null 2>&1

      if [ ! -x ./node${THIS_ID}_${HW_TYPE}_postinstall ]; then 
        abort "node${THIS_ID}_${HW_TYPE}_postinstall: no execute permissions"
      fi

      ./node${THIS_ID}_${HW_TYPE}_postinstall 2>&1
      if [ $? -ne 0 ]; then 
        abort "failure while executing node${THIS_ID}_${HW_TYPE}_postinstall"
      fi
      popd >/dev/null 2>&1

      local CMD="${POSTINSTALL_PLUGIN_PATH}/node${PEER_ID}_${HW_TYPE}_postinstall"
      $CMD_SSH $RHOST $CMD 2>&1
      if [ $? -ne 0 ]; then 
        abort "failure while executing node${PEER_ID}_${HW_TYPE}_postinstall"
      fi
    fi
  fi

  $CMD_ECHO "--- main() end"
}
 
main "@"

exit $TRUE

# End of file
