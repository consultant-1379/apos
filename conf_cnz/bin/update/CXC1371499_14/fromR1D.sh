# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1D.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Fri 11 Feb - Dharma Teja (xdhatej)
#        Fix for HZ60448
# Mon 24 Jan - Roshini Chilukoti(ZCHIROS)
#	-Fix for TR HY87206
# Wed 12 Jan - SOWJANYA GVL (xsowgvl)
#        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"
CLU_HOOKS_PATH='/cluster/hooks/'
#end

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling

# BEGIN: rsyslog configuration changes
apos_log 'Configuring Syslog Changes _14/fromR1D .....'
SYSLOG_CONFIG_FILE='usr/lib/lde/config-management/apos_syslog-config'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${SYSLOG_CONFIG_FILE}" --to "/${SYSLOG_CONFIG_FILE}" || \
  apos_abort "failure while deploying syslog configuration file"
  "/${SYSLOG_CONFIG_FILE}" config reload &>/dev/null || \
  apos_abort 'Failure while reloading syslog configuration file'
popd &>/dev/null
apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'
# END: rsyslog configuration changes


#BEGIN: Delete telnet and mts objects in IMM
/usr/bin/cmw-utility immcfg -d asecConfigdataId="TELNET",acsSecurityMId=1
if [ $? -ne 0 ]; then
  apos_log "Telnet object is not deleted in IMM or does not exist"
fi
/usr/bin/cmw-utility immcfg -d asecConfigdataId="MTS",acsSecurityMId=1
if [ $? -ne 0 ]; then
  apos_log "MTS object is not deleted in IMM or does not exist"
fi
#END: Delete telnet and mts objects in IMM

# BEGIN: updating DNR hooks
pushd $CFG_PATH &>/dev/null
    ./apos_deploy.sh --from "$SRC/$CLU_HOOKS_PATH/after-booting-from-disk.tar.gz" --to "$CLU_HOOKS_PATH/after-booting-from-disk.tar.gz"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying after-booting-from-disk.tar.gz file"
    fi

        ./apos_deploy.sh --from "$SRC/$CLU_HOOKS_PATH/post-installation.tar.gz" --to "$CLU_HOOKS_PATH/post-installation.tar.gz"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying post-installation.tar.gz file"
    fi

    ./apos_deploy.sh --from "$SRC/$CLU_HOOKS_PATH/pre-installation.tar.gz" --to "$CLU_HOOKS_PATH/pre-installation.tar.gz"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying pre-installation.tar.gz file"
    fi
popd &>/dev/null
# END: DNR hooks deploy

# BEGIN: Setting DSCP Values for oamvlan and external networkd for vAPG
CMD_CLUSTER_CONF="/opt/ap/apos/bin/clusterconf/clusterconf"

if is_vAPG; then

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
# END: Setting DSCP Values for oamvlan and external networkd for vAPG

# R1C -> R1D
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_14 R1E
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
