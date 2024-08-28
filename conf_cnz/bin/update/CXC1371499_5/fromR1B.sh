#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1B.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Mon Dec 05 2016 - Baratam Swetha (xswebar)
#       Update to deploy apos_drbd-config in case of GEP5 to fix HV39005.
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

#BEGIN: adding new service apos-recovery-conf for virtual environment------------------------#
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
if [[ "$HW_TYPE" == 'VM' ]]; then

  SERV_PATH='/opt/ap/apos/etc/deploy/usr/lib/systemd/system'
  SCRIPT_PATH='/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts'

  SCRIPT_FILE="$SCRIPT_PATH/apos-recovery-conf.sh"
  [ ! -f "$SCRIPT_FILE" ] && apos_abort 1 "\"$SCRIPT_FILE\" file not found"
  chmod 755 $SCRIPT_FILE
  BASE_FILE=$(/usr/bin/basename $SCRIPT_FILE)
  $CFG_PATH/apos_deploy.sh --from $SCRIPT_FILE --to /usr/lib/systemd/scripts/$BASE_FILE
  [ $? -ne $TRUE ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"

  SERV_FILE="$SERV_PATH/apos-recovery-conf.service"
  [ ! -f "$SERV_FILE" ] && apos_abort 1 "\"$SERV_FILE\" file not found"
  chmod 644 $SERV_FILE
  BASE_FILE=$(/usr/bin/basename $SERV_FILE)
  $CFG_PATH/apos_deploy.sh --from $SERV_FILE --to /usr/lib/systemd/system/$BASE_FILE
  [ $? -ne $TRUE ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"

  apos_servicemgmt enable "$BASE_FILE" &>/dev/null
  [ $? -ne $TRUE ] && apos_abort 1 "Failure while enabling \"$BASE_FILE\""
  
fi
#END  : adding new service apos-recovery-conf --------------------------------------------#

# BEGIN: Setting DSCP Values for oamvlan and external networkd for SMX
CMD_CLUSTER_CONF="/opt/ap/apos/bin/clusterconf/clusterconf"

if isSMX; then

  # set DSCP values for oam_vlanid
  destination_address="0.0.0.0/0"
  $CMD_CLUSTER_CONF iptables --m_add all -t mangle -A OUTPUT -d $destination_address -j DSCP --set-dscp 16 &> /dev/null
  if [ $? -eq 0 ]; then
    apos_log "DSCP value successfully set for default destination for OAM Vlan"
  else
    apos_abort "Failed to set DSCP value for default destination"
    rCode=1
  fi

  # set DSCP values for external networks
  # DEFAULT_DSCP=16
  vlan_destinations=$(cat /cluster/etc/cluster.conf | grep -i ^network | grep -i _gw | awk '{print $3}')
  for address in $vlan_destinations; do
    record=$($CMD_CLUSTER_CONF iptables -D | grep -w $address | grep "DSCP" | awk '{print $1}')
    if [ "$record" == "" ] ; then
      $CMD_CLUSTER_CONF iptables --m_add all -t mangle -A OUTPUT -d $address -j DSCP --set-dscp 16 &> /dev/null
      apos_log "cluster conf reload and commit success..."
    fi
  done
  # commit clusterconf changes
  rCode=0
  #Verify cluster configuration is OK after update.
  $CMD_CLUSTER_CONF mgmt --cluster --verify &> /dev/null || rCode=1
  if [ $rCode -eq 1 ]; then
    # Something wrong. Fallback with older cluster config
    $(${CMD_CLUSTER_CONF} mgmt --cluster --abort) && apos_abort "Cluster management verification failed"
  fi

  # Verify seems to be OK. Reload the cluster now.
  $CMD_CLUSTER_CONF mgmt --cluster --reload --verbose &>/dev/null || rCode=1
  if [ $rCode -eq 1 ]; then
    # Something wrong in reload. Fallback on older cluster config
    $(${CMD_CLUSTER_CONF} mgmt --cluster --abort) && apos_abort "Cluster management reload failed"
  fi

  # Things seems to be OK so-far. Commit cluster configuration now.
  $CMD_CLUSTER_CONF mgmt --cluster --commit &>/dev/null || rCode=1
  if [ $rCode -eq 1 ]; then
    # Commit should not fail, as it involves only removing the
    # back up file. anyway bail-out?
    apos_abort "Cluster Management commit failed"
  fi

  apos_log "cluster conf reload and commit success..."

  apos_log "restarting iptables daemon..."
  apos_servicemgmt restart lde-iptables.service &>/dev/null || apos_abort "failure while restarting iptables service"

fi
# END: Setting DSCP Values for oamvlan and external networkd for SMX

#deploying apos-drbd.sh files
DD_REPLICATION_TYPE=$(get_storage_type)
if [ "$DD_REPLICATION_TYPE" == "DRBD" ]; then
pushd $CFG_PATH &> /dev/null
[ ! -x $CFG_PATH/apos_deploy.sh ] && apos_abort 1 '/opt/ap/apos/conf/apos_deploy.sh not found or not executable'
./apos_deploy.sh --from "$SRC/usr/lib/systemd/scripts/apos-drbd.sh --to /usr/lib/systemd/scripts/apos-drbd.sh"
popd &>/dev/null
fi

#BEGIN: adding apos-ntp-config for virtual environment------------------------#
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
if [[ "$HW_TYPE" == 'VM' ]]; then
  pushd $CFG_PATH &> /dev/null
  ./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_ntp-config" --to "/usr/lib/lde/config-management/apos_ntp-config" || apos_abort "failure while deploying apos_ntp-config file"
  # reload config to update ntp-config
  /usr/lib/lde/config-management/apos_ntp-config config reload
  if [ $? -ne 0 ];then
    apos_abort "Failure while executing apos_ntp-config"
  fi
  popd &> /dev/null

  # Reload the cluster configuration on the current node to trigger ntp-conig execution
  cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
fi

# END: deploying apos_ntp-config file
#------------------------------------------------------------------------------#

# R1B -> R1C
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1C
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
