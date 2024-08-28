#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#		apos_vlanqos.sh
# Description:
#		A script to set the qos setting on vlans. This script is invoked 
#		from apos_conf.sh during MI. This script should be invoked
#		on BSP nodes only
#
#Usage : apos_vlanqos.sh
# Note:
#	None.
##
# Usage:
#	None.
##
# Output:
#	None.
##
# Changelog:
# - Mon Mar 14 2022 - Roshini Chilukoti (ZCHIROS)
#	Fix for TR HZ62238
# - Fri Jan 22 2016 - Gianluca Santoro (EGINSAN)
#       File renamed from aposcfg_vlanqos. 
# - Fri Nov 27 2015 - Antonio Buonocunto (EANBUON)
#       apos servicemgmt adaptation
# - Thurs Sep 10 2015 - Raghavendra Koduri (XKODRAG)
#	Removed PCP setting for internal APG vlans.
# - Mon May 11 2015 - Sindhuja Palla (XSINPAL)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#commands
CMD_CLUSTER_CONF="/opt/ap/apos/bin/clusterconf/clusterconf"
CLUSTER_CONF="/cluster/etc/cluster.conf"

#function setDSCP_OAM used to set DSCP for OAM vlans
function setDSCP_OAM() {
	local cluconf_DSCP=$(cat $CLUSTER_CONF | grep DSCP | awk '{print $12}')
        DEFAULT_DSCP='16'
        if [ $cluconf_DSCP != $DEFAULT_DSCP ]; then
                apos_log " DSCP value is already set with value other than $DEFAULT_DSCP"
        else
		local destination_address="0.0.0.0/0"
		$CMD_CLUSTER_CONF iptables --m_add all -t mangle -A OUTPUT -d $destination_address -j DSCP --set-dscp $DEFAULT_DSCP &> /dev/null
		if [ $? -eq $TRUE ]; then
			echo -e '16' > $(apos_create_brf_folder config)/oam_vlanDSCP
			apos_log "DSCP value successfully set for default destination for OAM Vlan"
		else
			apos_abort "Failed to set DSCP value for default destination"
		fi
	fi
 }
 
#function commitClusterConfChanges used to set cluster conf changes
function commitClusterConfChanges() {

	#Verify cluster configuration is OK after update.
	$CMD_CLUSTER_CONF mgmt --cluster --verify &> /dev/null
	if [ $? -ne $TRUE ]; then
		# Something wrong in verification. Fallback with older cluster config
		apos_log "Cluster management verification failed. Aborting..."
		$CMD_CLUSTER_CONF mgmt --cluster --abort &> /dev/null
		apos_abort "Cluster management verification failed. Aborted"
	fi
	
	# Verify seems to be OK. Reload the cluster now.
	$CMD_CLUSTER_CONF mgmt --cluster --reload --verbose &>/dev/null
	if [ $? -ne $TRUE ]; then
		# Something wrong in reload. Fallback on older cluster config
		apos_log "Cluster management reload failed. Aborting..."
		$CMD_CLUSTER_CONF mgmt --cluster --abort &> /dev/null
		apos_abort "Cluster management reload failed. Aborted"
	fi

	# Things seems to be OK so far. Commit cluster configuration now.
	$CMD_CLUSTER_CONF mgmt --cluster --commit &>/dev/null
	if [ $? -ne $TRUE ]; then
		# Commit should not fail, as it involves only removing the
		# back up file. anyway bail-out?
		apos_abort "Cluster Management commit failed"
	fi
	
	apos_log "cluster conf reload and commit success..."
	
	apos_log "restarting iptables daemon..."
	apos_servicemgmt restart lde-iptables.service &>/dev/null
	if [ $? -ne $TRUE ]; then
		# Something wrong while restarting iptables service
		apos_abort "failure while restarting iptables service"
	fi

}



function invoke() {

	# set DSCP values for oam_vlanid
	setDSCP_OAM

	# commit clusterconf changes 
	commitClusterConfChanges
	
}

# _____________________
#|    _ _   _  .  _    |
#|   | ) ) (_| | | )   |
#|_____________________|
# Here begins the "main" function...
# Set the interpreter to exit if a non-initialized variable is used.

# updating  dscp values
invoke
	
apos_outro $0
exit $TRUE

# End of file
