#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1C.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Mon Dec 12 2016 - Furquan Ullah (xfurull)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
CFG_PATH="/opt/ap/apos/conf"
SRC='/opt/ap/apos/etc/deploy'
LDE_CONFIG_MGMT='usr/lib/lde/config-management'

function isMD() {
  [ "$(get_storage_type)" == "MD" ] && return $TRUE
  return $FALSE
}

function is10G(){
  local NETWORK_BW=''
  NETWORK_BW=$( $CMD_PARMTOOL get --item-list drbd_network_capacity 2>/dev/null | \
  awk -F'=' '{print $2}')
  [ -z "$NETWORK_BW" ] && NETWORK_BW='1G'

  [ "$NETWORK_BW" == '10G' ] && return $TRUE
  return $FALSE
}

# Main

# R1A15 -> R1A16
#------------------------------------------------------------------------------#
##
#BEGIN Deployment of post-installation hooks
pushd $CFG_PATH &> /dev/null
[ ! -x /opt/ap/apos/conf/apos_deploy.sh ] && apos_abort 1 '/opt/ap/apos/conf/apos_deploy.sh not found or not executable'
./apos_deploy.sh --from "$SRC/cluster/hooks/post-installation.tar.gz" --to "/cluster/hooks/post-installation.tar.gz" --exlo
popd &>/dev/null

#END Deployment of post-installation hooks
##

#
# BEGIN: Deployment of apos_drbd-config file (according to system configuration)
if ! isMD; then
  # The apos_drbd-config file(s) must be deployed only in case of DRBD replication for data disk
  if ! is10G; then   
    if ! is_vAPG; then
      pushd $CFG_PATH &> /dev/null
      [ ! -x ./apos_deploy.sh ] && apos_abort 1 "$CFG_PATH/apos_deploy.sh not found or not executable"
      ./apos_deploy.sh --from "$SRC/$LDE_CONFIG_MGMT/apos_drbd-config" --to "/$LDE_CONFIG_MGMT/apos_drbd-config"
    fi	
  fi
  # Reload the cluster configuration on the current node to trigger apos_drbd-config execution
  cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'

  # Instruct drbd to use the new configuration
  /sbin/drbdadm adjust drbd1 || apos_abort 'Failure while notifying DRBD about new configuration'
fi
# END  : Deployment of apos_drbd-config file (according to system configuration)
##
#------------------------------------------------------------------------------#


# R1C -> R1D
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1D
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
