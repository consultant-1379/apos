#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       preinstall
# Description:
#       A script to perform APG configurations.
# Note:
#       Invoked by apos_cmd plugin after LDE and CoreMW installation 
#       on both the Nodes of vAPG.
##
# Usage:
#       Used during vAPG maiden installation.
##
# Output:
#       None.
##
# Changelog:
# - Thu Jun 14 2018 - Pranshu Sinha (XPRANSI)
#   First version.

PLUGIN_SCRIPTS_ROOT="$(dirname "$(readlink -f $0)")"

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

#------------------------------------------------------------------------
function lde_sdp_import(){
  $CMD_ECHO "--- lde_sdp_import() begin"

  local CMD_SDP_IMPORT='/opt/coremw/bin/cmw-sdp-import'
	local LM_PATH='/home/ait/repo/unpack/lm'
  local LDE_PACKAGE=$(find ${LM_PATH}/LINUX_RUNTIME-* -name "ERIC-LINUX_CONTROL-*.sdp" -type f 2>/dev/null)
  if [ -z "$LDE_PACKAGE" ]; then 
    LDE_PACKAGE=$(find ${LM_PATH}/ldews-*runtime* -name "ERIC-LINUX_CONTROL-*.sdp" -type f)
  fi
  $CMD_SDP_IMPORT $LDE_PACKAGE
  [ $? -ne 0 ] && abort "Failure while importing LINUX_RUNTIME-*.sdp"

  $CMD_ECHO "--- lde_sdp_import() end"
}


#### M A I N ####
main(){
  $CMD_ECHO "--- main() begin"
  FACTORY_FILE='/cluster/storage/system/config/lde/csm/templates/config/initial/ldews.os/factoryparam.conf'
  CMD_GREP='/usr/bin/grep'
  CMD_AWK='/usr/bin/awk'
  if [ -f $FACTORY_FILE ];  then
    is_vm=$(cat $FACTORY_FILE | $CMD_GREP -i installation_hw | $CMD_AWK -F "=" '{print $2}')
    if [ "$is_vm" == "VM" ];  then
  
      local PREINSTALL_PLUGIN_PATH="${PLUGIN_SCRIPTS_ROOT}/preinstall"
      [ "$THIS_ID" -ne 2 ] && abort "This script shall be invoked only on SC-2-2"
  
      # Fetch hardware type
      HW_TYPE=$(get_hwtype)
      [ -z "$HW_TYPE" ] && abort "HW_TYPE found NULL!!"
  
      # LDE bundle import 
      # lde_sdp_import

      pushd $PREINSTALL_PLUGIN_PATH >/dev/null 2>&1

      if [ ! -x ./node${THIS_ID}_${HW_TYPE}_preinstall ]; then
        abort "node${THIS_ID}_${HW_TYPE}_preinstall: no execute permissions"
      fi
      ./node${THIS_ID}_${HW_TYPE}_preinstall 1>${PREINSTALL_PLUGIN_PATH}/node2_preinstall_log_1 2>${PREINSTALL_PLUGIN_PATH}/node2_preinstall_log_2
      if [ $? -ne 0 ]; then
        abort "Failure while executing node${THIS_ID}_${HW_TYPE}_preinstall"
      fi

      popd >/dev/null 2>&1

      local CMD="$PREINSTALL_PLUGIN_PATH/node${PEER_ID}_${HW_TYPE}_preinstall $PLUGIN_SCRIPTS_ROOT" 
      $CMD_SSH ${RHOST} $CMD 1>${PREINSTALL_PLUGIN_PATH}/node1_preinstall_log_1 2>${PREINSTALL_PLUGIN_PATH}/node1_preinstall_log_2
      if [ $? -ne 0 ]; then
        abort "Failure while executing node${PEER_ID}_${HW_TYPE}_preinstall"
      fi
    fi
  fi
  $CMD_ECHO "--- main() end"
}

main "@"

exit $TRUE
# End of file

