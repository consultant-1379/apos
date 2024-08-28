#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Fri 1 Apr - Rajeshwari Padavala (xcsrpad)
#        Support for Chrony feature
# Mon 14 March - ROSHINI CHILUKOTI (zchiros)
#        Fix for TR HZ62238
# Mon 14 Mar - SOWJANYA GVL (xsowgvl)
#        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"
CMD_SED="/usr/bin/sed"
ETC_ROOT="/etc"

# BEGIN: Setting DSCP Values for oamvlan and external networks
CMD_CLUSTER_CONF="/opt/ap/apos/bin/clusterconf/clusterconf"
CLUSTER_CONF="/cluster/etc/cluster.conf"
NTP_CONFIG_FILE="/usr/lib/lde/config-management/ntp-config"

if isBSP || isSMX || is_vAPG ; then
	
	# set DSCP values for oam_vlanid
	cluconf_DSCP=$(cat $CLUSTER_CONF | grep DSCP | awk '{print $12}')
	DEFAULT_DSCP='16'
	if [ $cluconf_DSCP != $DEFAULT_DSCP ]; then
		apos_log " DSCP value is already set with value other than $DEFAULT_DSCP"
	else
		destination_address="0.0.0.0/0"
		$CMD_CLUSTER_CONF iptables --m_add all -t mangle -A OUTPUT -d $destination_address -j DSCP --set-dscp $DEFAULT_DSCP &> /dev/null
		if [ $? -eq $TRUE ]; then
			echo -e '16' > $(apos_create_brf_folder config)/oam_vlanDSCP
			apos_log "DSCP value successfully set for default destination for OAM Vlan"
		else
			apos_abort "Failed to set DSCP value for default destination"
		fi
	fi

	# set DSCP values for external networks
	# DEFAULT_DSCP=16
	vlan_destinations=$(cat $CLUSTER_CONF | grep -i ^network | grep -i _gw | awk '{print $3}')
	for address in $vlan_destinations; do
		record=$($CMD_CLUSTER_CONF iptables -D | grep -w $address | grep "DSCP" | awk '{print $1}')
		if [ "$record" == "" ] ; then
			$CMD_CLUSTER_CONF iptables --m_add all -t mangle -A OUTPUT -d $address -j DSCP --set-dscp 16 &> /dev/null
			apos_log "DSCP value successfully set for vlan destination $address"
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
# END: Setting DSCP Values for oamvlan and external networks

if is_vAPG; then
  pushd $CFG_PATH &> /dev/null
  ./apos_deploy.sh --from "$SRC/etc/chrony.conf.local" --to "/etc/chrony.conf.local"

  ./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_ntp-config" --to "/usr/lib/lde/config-management/apos_ntp-config" || apos_abort "failure while deploying apos_ntp-config file"
  # reload config to update ntp-config
  TIME_SERVER_TYPE_CONFIG="$ETC_ROOT"/cluster/services/time/ntp.server-type
  if [ -s "$TIME_SERVER_TYPE_CONFIG" ] && [ "$(<"$TIME_SERVER_TYPE_CONFIG")" == "chrony" ]; then
    apos_log "Found application type as vBSC"
    if grep 'ntp.conf.local' "$NTP_CONFIG_FILE" &> /dev/null; then
      $CMD_SED -i '/includefile \/etc\/ntp\.conf\.local/d' $NTP_CONFIG_FILE
      apos_log "ntp.conf.local entry already exist, configuration changes done"
    else
      apos_log "ntp.conf.local entry already not exist, no configuration changes"
    fi
  fi 
  /usr/lib/lde/config-management/apos_ntp-config config reload
  if [ $? -ne 0 ];then
    apos_abort "Failure while executing apos_ntp-config"
  fi
  popd &> /dev/null

  # Reload the cluster configuration on the current node to trigger ntp-conig execution
  cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
fi

# R1A02 -> R1B
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_15 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
