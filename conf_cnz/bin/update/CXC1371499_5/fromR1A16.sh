#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A16.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Mon Sep 05 2016 - Alessio Cascone (ealocae)
#	Update to deploy apos_drbd-config files to fix HV21955.
# - Wed Aug 31 2016 - Yeswanth Vankayala (xyesvan)
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
# BEGIN: Deployment of apos_logrotd-config and auditd configuration files (according to system configuration)

  pushd $CFG_PATH &> /dev/null  

  # Insert the support to the file /var/log/wtmp in the logrotd configuration file
  [ ! -x ./apos_deploy.sh ] && apos_abort 1 "$CFG_PATH/apos_deploy.sh not found or not executable"
  ./apos_deploy.sh --from "$SRC/$LDE_CONFIG_MGMT/apos_logrotd-config" --to "/$LDE_CONFIG_MGMT/apos_logrotd-config"

  # Remove the old auditd rule and insert the new one
  sed -i 's/.*execve.*/-a exit,always -F arch=b64 -S execve -F auid>500 -F auid<1000/g' /etc/audit/audit.rules &> /dev/null || apos_abort "failure while reloading auditd rules"

  # Change the max_log_file parameter into auditd.conf file from 50MB to 250MB
  ./aposcfg_auditd.sh || apos_abort "failure while reloading auditd rules"

  popd &> /dev/null

  # auditd restart to make the new rules effective
  apos_servicemgmt restart auditd.service &>/dev/null || apos_abort "failure while reloading auditd rules"

  # Reload the cluster configuration on the current node to trigger apos_logrotd-config execution
  cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'

# END  : Deployment of apos_logrotd-config and auditd configuration files (according to system configuration)
##


#
# BEGIN: Deployment of apos_drbd-config file (according to system configuration)
if ! isMD; then
  # The apos_drbd-config file(s) must be deployed only in case of DRBD replication for data disk
  pushd $CFG_PATH &> /dev/null  
  [ ! -x ./apos_deploy.sh ] && apos_abort 1 "$CFG_PATH/apos_deploy.sh not found or not executable"
  ./apos_deploy.sh --from "$SRC/$LDE_CONFIG_MGMT/apos_drbd-config" --to "/$LDE_CONFIG_MGMT/apos_drbd-config"

  # In case the system is in 10G configuration, deploy the apos_drbd-config_10g file
  is10G && ./apos_deploy.sh --from "$SRC/$LDE_CONFIG_MGMT/apos_drbd-config_10g" --to "/$LDE_CONFIG_MGMT/apos_drbd-config"

  # In case of vAPG system, deploy the apos_drbd-config_VM file
  is_vAPG && ./apos_deploy.sh --from "$SRC/$LDE_CONFIG_MGMT/apos_drbd-config_VM" --to "/$LDE_CONFIG_MGMT/apos_drbd-config"
  popd &> /dev/null

  # Reload the cluster configuration on the current node to trigger apos_drbd-config execution
  cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'

  # Instruct drbd to use the new configuration
  /sbin/drbdadm adjust drbd1 || apos_abort 'Failure while notifying DRBD about new configuration'
fi
# END  : Deployment of apos_drbd-config file (according to system configuration)
##
#------------------------------------------------------------------------------#


# R1A16 -> R1B
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
