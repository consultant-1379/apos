#!/bin/bash
#
# Copyright (C) 2020 by Ericsson AB
#
##
# Name:
#       configure_drbd1.sh
# Description:
#       A script to configure drbd1 on both nodes of vAPG.
# Note:
#       Invoked from OSCMDBIN campaign through plugin 
##
# Usage:
#       Used during vAPG maiden installation.
##
# Output:
#       None.
##
# Changelog:
# - Mon June 08 2020 -  Uppada PratapReddy(XPRAUPP)
#   First version.


PLUGIN_SCRIPTS_ROOT="$(dirname "$(readlink -f $0)")"

PLUGIN_SCRIPT="${PLUGIN_SCRIPTS_ROOT}/configure_drbd1.sh"
if [ ! -r "$PLUGIN_SCRIPT" ]; then
  echo 'configure_drbd1.sh script not found...exiting' >&2
  exit 1
fi

COMMON_FUNCTIONS="${PLUGIN_SCRIPTS_ROOT}/non_exec-common_functions"
if [ ! -r "$COMMON_FUNCTIONS" ]; then
  echo 'COMMON_FUNCTIONS not found...exiting' >&2
  exit 1
fi

export PLUGIN_SCRIPTS_ROOT
. ${COMMON_FUNCTIONS}

function log(){
   local LOG_TAG='configure_drdb1'
  /bin/logger -t "$LOG_TAG" "$*"
}

function is_vAPG() {
  local VAPG=$FALSE
  local LDE_PLUGIN_PATH='/storage/system/config/lde/csm/templates/config/initial/ldews.os'
  local FACTORY_PARAM_FILE="$LDE_PLUGIN_PATH/factoryparam.conf"
  if [ -f "$FACTORY_FILE" ];  then
    HW_TYPE=$(grep -i 'installation_hw' $FACTORY_FILE | awk -F "=" '{print $2}')
  else
    # Fetch hardware type
    HW_TYPE=$(get_hwtype)
  fi 

  if [ -n "$HW_TYPE" ]; then 
    [ "$HW_TYPE" == VM ] && VAPG=$TRUE
  fi 
  return $VAPG
}

function config_drbd1() {

  log "drbd1 configuration initiated on this node"

  # configure the drdb1 on remote node
  if [ "$THOST" == 'SC-2-1' ]; then 
    # kick-start the configure_drbd1 script on remote in separate thread
    $( /usr/bin/ssh $RHOST $PLUGIN_SCRIPT &>/dev/null)&
    peer_script_pid=$!

    # sleep for a while to check if the script is successfully spawned on peer node.
    sleep 5
    if ! kill -0 $peer_script_pid 2> /dev/null; then
      abort "Failed to start configure_drbd1 script on peer node."
    else
      log "drbd1 configuration initiated on peer node"
    fi
  fi 

  # Activate vg
  activate_vg
   
  # Udev rules
  udev_rules

  # Configue drbd1 resource
  OPTS='--part'
  OPTS1='--configure --lvm --activate --force'
  configure_drbd1 "$OPTS"
  configure_drbd1 "$OPTS1"

  if [ "$THOST" == 'SC-2-1' ]; then
    wait $peer_script_pid
    local child_exit_code=$?
    if [ $child_exit_code -ne 0 ]; then
      abort "configure_drbd1 script on peer node aborted with exit code $child_exit_code"
    else
      log "drbd1 configuration completed on peer node"
    fi
  fi 
  log "drbd1 configuration completed on this node"
}

## M A I N ##

# This configuration only applied on virtual
if is_vAPG; then 
  config_drbd1
fi 

exit $TRUE
# End of file
