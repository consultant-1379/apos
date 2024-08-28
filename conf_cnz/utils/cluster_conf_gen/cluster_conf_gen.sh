#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# cluster_conf_gen.sh
# A script to automatically generate cluster.conf file(s).
##
# Usage:
# cluster_conf_gen.sh <-s|--stage> <1|2>
##
# Changelog:
# - Tue Mar 15 2011 - Francesco Rainone (efrarai)
#	Changed the template file path from /cluster/etc/ to the current working directory.
# - Mon Feb 21 2011 - Francesco Rainone (efrarai)
#	First version.
##

# Only declared variables allowed.
set -u

# Variables
TEMPLATE_FILE="./cluster.template.conf"
CLUSTER_CONF="/cluster/etc/cluster.conf"

# Functions

function abort(){
	echo "Aborting: $2" >&2
	exit $1
}

function usage(){
	echo "Usage: cluster_conf_gen.sh -s <1|2>"
	echo
	echo "options: -s, --stage <1|2>"
	exit 1
}

function sanity_checks(){
	if [ ! -f $TEMPLATE_FILE ]; then
		abort 1 "$TEMPLATE_FILE not found!"
	fi
}

function perform_substitutions(){
	cat $TEMPLATE_FILE | grep -v "^#stage2#" | sed "s@^#stage1#@@g" | sed "s@<DATE>@$DATE@g" | sed "s@<NET_PUBLIC>@$NET_PUBLIC@g" | sed "s@<NET_PUBLIC_MASK>@$NET_PUBLIC_MASK@g" | sed "s@<NET_GATEWAY>@$NET_GATEWAY@g" | sed "s@<IP_PUBLIC_CLUSTER>@$IP_PUBLIC_CLUSTER@g" | sed "s@<HOSTNAME1>@$HOSTNAME1@g" | sed "s@<IPNA_MAC_NODE1>@$IPNA_MAC_NODE1@g" | sed "s@<IPNB_MAC_NODE1>@$IPNB_MAC_NODE1@g" | sed "s@<DEBUG_MAC_NODE1>@$DEBUG_MAC_NODE1@g" | sed "s@<FP1_MAC_NODE1>@$FP1_MAC_NODE1@g" | sed "s@<FP2_MAC_NODE1>@$FP2_MAC_NODE1@g" | sed "s@<IP_PUBLIC_NODE1>@$IP_PUBLIC_NODE1@g" | sed "s@<HOSTNAME2>@$HOSTNAME2@g" | sed "s@<IPNA_MAC_NODE2>@$IPNA_MAC_NODE2@g" | sed "s@<IPNB_MAC_NODE2>@$IPNB_MAC_NODE2@g" | sed "s@<DEBUG_MAC_NODE2>@$DEBUG_MAC_NODE2@g" | sed "s@<FP1_MAC_NODE2>@$FP1_MAC_NODE2@g" | sed "s@<FP2_MAC_NODE2>@$FP2_MAC_NODE2@g" | sed "s@<IP_PUBLIC_NODE2>@$IP_PUBLIC_NODE2@g" > "/cluster/etc/cluster.stage1.conf"
	cat $TEMPLATE_FILE | grep -v "^#stage1#" | sed "s@^#stage2#@@g" | sed "s@<DATE>@$DATE@g" | sed "s@<NET_PUBLIC>@$NET_PUBLIC@g" | sed "s@<NET_PUBLIC_MASK>@$NET_PUBLIC_MASK@g" | sed "s@<NET_GATEWAY>@$NET_GATEWAY@g" | sed "s@<IP_PUBLIC_CLUSTER>@$IP_PUBLIC_CLUSTER@g" | sed "s@<HOSTNAME1>@$HOSTNAME1@g" | sed "s@<IPNA_MAC_NODE1>@$IPNA_MAC_NODE1@g" | sed "s@<IPNB_MAC_NODE1>@$IPNB_MAC_NODE1@g" | sed "s@<DEBUG_MAC_NODE1>@$DEBUG_MAC_NODE1@g" | sed "s@<FP1_MAC_NODE1>@$FP1_MAC_NODE1@g" | sed "s@<FP2_MAC_NODE1>@$FP2_MAC_NODE1@g" | sed "s@<IP_PUBLIC_NODE1>@$IP_PUBLIC_NODE1@g" | sed "s@<HOSTNAME2>@$HOSTNAME2@g" | sed "s@<IPNA_MAC_NODE2>@$IPNA_MAC_NODE2@g" | sed "s@<IPNB_MAC_NODE2>@$IPNB_MAC_NODE2@g" | sed "s@<DEBUG_MAC_NODE2>@$DEBUG_MAC_NODE2@g" | sed "s@<FP1_MAC_NODE2>@$FP1_MAC_NODE2@g" | sed "s@<FP2_MAC_NODE2>@$FP2_MAC_NODE2@g" | sed "s@<IP_PUBLIC_NODE2>@$IP_PUBLIC_NODE2@g" > "/cluster/etc/cluster.stage2.conf"
}

# The function increases the MAC address passed as parameter
# Parameters: 
#  $1 = the MAC address to be increased;
#  $2 = the increase amount;
# Return:
#  0 in case of success (and the variable $MACPP will contain the result of the
#  increment. 1 in case of failure.
# No values are returned but, after the execution of the function,
#  the variable $MACPP will contain the result of the increment.
function increment_mac(){
	MACPP=""
	if [ $# -eq 2 ]; then
		MAC=$1
		AMOUNT=$2	
		MAC_VALUE=`echo 0x$MAC | tr -d :`		
		MACPP_VALUE=$(( $MAC_VALUE + $AMOUNT ))
		MACPP_VALUE=`printf '%012x' $MACPP_VALUE`		
		MACPP=${MACPP_VALUE:0:2}:${MACPP_VALUE:2:2}:${MACPP_VALUE:4:2}:${MACPP_VALUE:6:2}:${MACPP_VALUE:8:2}:${MACPP_VALUE:10:2}		
		return 0
	else
		return 1
	fi
}

function mac_calculator(){
	increment_mac $IPNA_MAC_NODE1 1
	if [ $? -ne 0 ]; then abort 1 "Mac conversion failed"; fi
	IPNB_MAC_NODE1=$MACPP
	increment_mac $IPNA_MAC_NODE1 2
	if [ $? -ne 0 ]; then abort 1 "Mac conversion failed"; fi
	DEBUG_MAC_NODE1=$MACPP
	increment_mac $IPNA_MAC_NODE1 4
	if [ $? -ne 0 ]; then abort 1 "Mac conversion failed"; fi
	FP1_MAC_NODE1=$MACPP
	increment_mac $IPNA_MAC_NODE1 5
	if [ $? -ne 0 ]; then abort 1 "Mac conversion failed"; fi
	FP2_MAC_NODE1=$MACPP
	
	increment_mac $IPNA_MAC_NODE2 1
	if [ $? -ne 0 ]; then abort 1 "Mac conversion failed"; fi
	IPNB_MAC_NODE2=$MACPP
	increment_mac $IPNA_MAC_NODE2 2
	if [ $? -ne 0 ]; then abort 1 "Mac conversion failed"; fi
	DEBUG_MAC_NODE2=$MACPP
	increment_mac $IPNA_MAC_NODE2 4
	if [ $? -ne 0 ]; then abort 1 "Mac conversion failed"; fi
	FP1_MAC_NODE2=$MACPP
	increment_mac $IPNA_MAC_NODE2 5
	if [ $? -ne 0 ]; then abort 1 "Mac conversion failed"; fi
	FP2_MAC_NODE2=$MACPP
}

# the function takes an IP address as a parameter.
# It returns 0 in case of a correctly formatted address, 1 otherwise.
function ip_is_valid()
{
	local VALID=0
	local NOT_VALID=1
	
	if [ $# -eq 0 ]; then return $NOT_VALID; fi
    local IP=$1	
	
    if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IP=`echo $IP | sed 's@\.@ @g'`		
		if [[ `echo $IP | wc -w` -ne 4 ]]; then
			return $NOT_VALID
		fi
        IP=($IP)
		for (( I=0; $I < 4; I++ )); do			
			if [[ ${IP[$I]} -gt 255 || ${IP[$I]} -lt 0 ]]; then
				return $NOT_VALID
			fi
		done 
	else
		return $NOT_VALID
    fi
    return $VALID
}

# the function takes a NET-MASK (in decimal format) as a parameter.
# It returns 0 in case of a correctly formatted mask, 1 otherwise.
function mask_is_valid(){
	local VALID=0
	local NOT_VALID=1
	if [ $# -eq 0 ]; then return $NOT_VALID; fi
	local MASK=$1
	
	if [[ ! $MASK =~ ^[0-9]{1,2}$ ]]; then
		return $NOT_VALID
	fi
	
	if [[ $MASK -gt 31 || $MASK -lt 0 ]]; then
		return $NOT_VALID
	fi
	
	return $VALID
}

# the function takes a MAC address as a parameter.
# It returns 0 in case of a correctly formatted address, 1 otherwise.
function mac_is_valid(){
	local VALID=0
	local NOT_VALID=1
	
	if [ $# -eq 0 ]; then return $NOT_VALID; fi
    local MAC=$1	
	
    if [[ $MAC =~ ^[0-9a-f]{1,2}:[0-9a-f]{1,2}:[0-9a-f]{1,2}:[0-9a-f]{1,2}:[0-9a-f]{1,2}:[0-9a-f]{1,2}$ ]]; then
        MAC=`echo $MAC | sed 's@:@ @g'`		
		if [[ `echo $MAC | wc -w` -ne 6 ]]; then
			return $NOT_VALID
		fi
        MAC=($MAC)
		for (( I=0; $I < 6; I++ )); do			
			local MAC_D=$(( 0x${MAC[$I]} ))			
			if [[ $MAC_D -gt 255 || $MAC_D -lt 0 ]]; then
				return $NOT_VALID
			fi
		done 
	else
		return $NOT_VALID
    fi
    return $VALID
}

function ask_and_create(){
	# Common values
	DATE="`date --utc`"	
	NET_PUBLIC=""
	NET_PUBLIC_MASK=""
	NET_GATEWAY=""
	IP_PUBLIC_CLUSTER=""
	
	# Node1-specific values
	HOSTNAME1=""	
	IPNA_MAC_NODE1=""
	IPNB_MAC_NODE1=""
	DEBUG_MAC_NODE1=""
	FP1_MAC_NODE1=""
	FP2_MAC_NODE1=""
	IP_PUBLIC_NODE1=""
	
	# Node2-specific values
	HOSTNAME2=""
	IPNA_MAC_NODE2=""
	IPNB_MAC_NODE2=""
	DEBUG_MAC_NODE2=""
	FP1_MAC_NODE2=""
	FP2_MAC_NODE2=""
	IP_PUBLIC_NODE2=""
	
	echo
	echo "---------- Common configuration ----------"
	echo
	
	until ip_is_valid $NET_PUBLIC; do
		echo "Insert public network ip address (ex: 10.246.15.0):"
		read NET_PUBLIC
	done
		
	until mask_is_valid $NET_PUBLIC_MASK; do
		echo "Insert public network mask in decimal format (ex: 24):"
		read NET_PUBLIC_MASK
	done
	
	until ip_is_valid $NET_GATEWAY; do
		echo "Insert public network gateway (ex: 10.246.15.1):"
		read NET_GATEWAY
	done
	
	until ip_is_valid $IP_PUBLIC_CLUSTER; do
		echo "Insert public network cluster ip address (ex: 10.246.15.33):"
		read IP_PUBLIC_CLUSTER
	done
	
	echo
	echo "---------- Node 1 configuration ----------"
	echo
	
	echo "Insert the hostname (ex: AP1): "
	read HOSTNAME1
	if [ -z $HOSTNAME1 ]; then
		abort 1 "Wrong or empy public network ip address for node 1."
	fi
	
	until mac_is_valid $IPNA_MAC_NODE1; do
		echo "Insert the MAC address for IPNA interface aka eth3 (ex: 00:50:56:01:5a:1a):"
		read IPNA_MAC_NODE1
		IPNA_MAC_NODE1=`echo $IPNA_MAC_NODE1 | tr A-F a-f`
	done
	
	until ip_is_valid $IP_PUBLIC_NODE1; do
		echo "Insert the public ip address (ex: 10.246.15.30):"
		read IP_PUBLIC_NODE1
	done
	
	echo
	echo "---------- Node 2 configuration ----------"
	echo
	
	echo "Insert the hostname (ex: AP2): "
	read HOSTNAME2
	if [ -z $HOSTNAME2 ]; then
		abort 1 "Wrong or empy public network ip address for node 2."
	fi
	
	until mac_is_valid $IPNA_MAC_NODE2; do
		echo "Insert the MAC address for IPNA interface aka eth3 (ex: 00:50:56:02:5a:1a):"
		read IPNA_MAC_NODE2
		IPNA_MAC_NODE2=`echo $IPNA_MAC_NODE2 | tr A-F a-f`
	done
	
	until ip_is_valid $IP_PUBLIC_NODE2; do
		echo "Insert the public ip address (ex: 10.246.15.31):"
		read IP_PUBLIC_NODE2
	done
	
	mac_calculator
	
	echo
	echo "---------- Common configuration ----------"
	echo "DATE=$DATE"
	echo "NET_PUBLIC=$NET_PUBLIC"
	echo "NET_PUBLIC_MASK=$NET_PUBLIC_MASK"
	echo "NET_GATEWAY=$NET_GATEWAY"
	echo "IP_PUBLIC_CLUSTER=$IP_PUBLIC_CLUSTER"
	echo
	echo "---------- Node 1 configuration ----------"
	echo "HOSTNAME1=$HOSTNAME1"
	echo "IPNA_MAC_NODE1=$IPNA_MAC_NODE1"
	echo "IPNB_MAC_NODE1=$IPNB_MAC_NODE1"
	echo "DEBUG_MAC_NODE1=$DEBUG_MAC_NODE1"
	echo "FP1_MAC_NODE1=$FP1_MAC_NODE1"
	echo "FP2_MAC_NODE1=$FP2_MAC_NODE1"
	echo "IP_PUBLIC_NODE1=$IP_PUBLIC_NODE1"
	echo
	echo "---------- Node 2 configuration ----------"
	echo "HOSTNAME2=$HOSTNAME2"
	echo "IPNA_MAC_NODE2=$IPNA_MAC_NODE2"
	echo "IPNB_MAC_NODE2=$IPNB_MAC_NODE2"
	echo "DEBUG_MAC_NODE2=$DEBUG_MAC_NODE2"
	echo "FP1_MAC_NODE2=$FP1_MAC_NODE2"
	echo "FP2_MAC_NODE2=$FP2_MAC_NODE2"
	echo "IP_PUBLIC_NODE2=$IP_PUBLIC_NODE2"
	echo
	
	perform_substitutions
}

function run(){
	if [ ! -f "/cluster/etc/cluster.stage$STAGE.conf" ]; then
		ask_and_create
	else
		echo "Configurating according to the file \"/cluster/etc/cluster.stage$STAGE.conf\""
		echo
	fi
	
	mv "$CLUSTER_CONF" "$CLUSTER_CONF.backup"
	cp "/cluster/etc/cluster.stage$STAGE.conf" $CLUSTER_CONF
	
	echo "Applying the stage $STAGE configuration on the local node..."
	cluster config --validate > /dev/null
	if [ $? -ne 0 ]; then
		# rollback
		mv "$CLUSTER_CONF.backup" "$CLUSTER_CONF"
		abort 1 "unable to validate the file \"/cluster/etc/cluster.stage$STAGE.conf\"!"
	fi
	cluster config --reload	> /dev/null
	if [ $? -ne 0 ]; then
		# rollback
		mv "$CLUSTER_CONF.backup" "$CLUSTER_CONF"
		abort 1 "unable to reload the file \"/cluster/etc/cluster.stage$STAGE.conf\"!"
	fi
	echo "done"
	
	echo "Applying the stage $STAGE configuration on the remote node..."
	rsh `cat /etc/cluster/nodes/peer/hostname` 'cluster config --validate > /dev/null; echo $?' > /tmp/cluster_conf_gen.tmp
	if [[ $? -ne 0 || "`tail -n -1 /tmp/cluster_conf_gen.tmp`" -ne 0 ]]; then
		# rollback
		mv "$CLUSTER_CONF.backup" "$CLUSTER_CONF"
		abort 1 "unable to remotely validate the file \"/cluster/etc/cluster.stage$STAGE.conf\"!"
	fi
	rsh `cat /etc/cluster/nodes/peer/hostname` 'cluster config --reload > /dev/null; echo $?' > /tmp/cluster_conf_gen.tmp
	if [[ $? -ne 0 || "`tail -n -1 /tmp/cluster_conf_gen.tmp`" -ne 0 ]]; then
		# rollback
		mv "$CLUSTER_CONF.backup" "$CLUSTER_CONF"
		abort 1 "unable to remotely reload the file \"/cluster/etc/cluster.stage$STAGE.conf\"!"
	fi
	echo "done"	
}

function params_check(){
	if [ $# -lt 1 ]; then		
		usage
	fi
	case $@ in
	"-s 1" | "--stage 1" )
		STAGE=1
		run
	;;
	"-s 2" | "--stage 2" )
		STAGE=2
		run
	;;
	* )
		usage
	;;
	esac
}

sanity_checks 
params_check $@

exit 0
