#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1D.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue APR 24 2018 - Furquan Ullah (xfurull)
#     First version.
#
# - Fri 11 May 2018 - Pratap Reddy Uppada (xpraupp)
#     SEC configuration file related changes
#
# - Fri 22 May 2018 - Crescenzo Malvone (ecremal)
#     LDE GID checker fix    
#
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH="/opt/ap/apos/conf"
SRC='/opt/ap/apos/etc/deploy'
HW_TYPE='/opt/ap/apos/conf/apos_hwtype.sh'
DD_REPLICATION_TYPE=$(get_storage_type)
LDE_CONFIG_MGMT='usr/lib/lde/config-management'
CMD_DRBDADM='/sbin/drbdadm'


##
# BEGIN: Update of ldap_aa.conf for SEC 2.7
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_sec-ldapconf.sh
popd &> /dev/null
# END: Update of ldap_aa.conf for SEC 2.7
##

function isMD() {
  [ "$DD_REPLICATION_TYPE" == "MD" ] && return $TRUE
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

#BEGIN Deployment of hooks
pushd $CFG_PATH &> /dev/null
[ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/cluster/hooks/post-installation.tar.gz" --to "/cluster/hooks/post-installation.tar.gz" --exlo
popd &>/dev/null
#END Deployment of hooks
# BEGIN: Deployment of apos_drbd-config file (according to system configuration)
if ! isMD; then
  if ! is10G; then
    if ! is_vAPG; then
      pushd $CFG_PATH &> /dev/null
      [ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"
      ./apos_deploy.sh --from "$SRC/$LDE_CONFIG_MGMT/apos_drbd-config" --to "/$LDE_CONFIG_MGMT/apos_drbd-config"
    fi
  fi
  # Trigger apos_drbd-config execution
/usr/lib/lde/config-management/apos_drbd-config config init
if [ $? -ne 0 ];then
apos_abort "Failure while executing apos_drbd-config"
fi
  # Instruct drbd to use the new configuration
  $CMD_DRBDADM adjust drbd1 || apos_abort 'Failure while notifying DRBD about new configuration'
fi
# END  : Deployment of apos_drbd-config file (according to system configuration)
##

# BEGIN: LDE GID checker fix
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from $SRC/usr/lib/systemd/system/apg-gid_checker.service --to /usr/lib/systemd/system/apg-gid_checker.service
./apos_deploy.sh --from $SRC/usr/lib/systemd/scripts/apg-gid_checker.sh --to /usr/lib/systemd/scripts/apg-gid_checker.sh
[ ! $? = 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
apos_servicemgmt enable apg-gid_checker.service &>/dev/null || apos_abort 'failure while configuring gid_checker startup'
apos_servicemgmt restart apg-gid_checker.service &>/dev/null || apos_abort 'failure while restarting gid_checker service'
popd &> /dev/null
# END: LDE GID checker fix



#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_8 R1A11
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
