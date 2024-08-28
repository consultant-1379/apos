#!/bin/bash

exit_success=0
exit_failure=1
timeout=2
TRUE=1
FALSE=0

pidof=`which pidof`

function log(){
	/bin/logger -s -t apos_ha_shutdownagent "$@"
}

function is_agent_running(){

	agent_pid=$($pidof "/opt/ap/apos/bin/apos_ha_rdeagentd")
	if [ ! -z $agent_pid ]; then
		return $TRUE
	fi
	return $FALSE
}

function get_nodeid(){

        #Check which node we are running on
        #
        node_id=`cmwea tipcaddress-get | cut -d , -f 3`

        if [ $node_id -ne 1 ] && [ $node_id -ne 2 ]; then
                log "Invalid node id"
                return $exit_failure
        fi
        echo $node_id
}

function get_matenodeid(){

	nodeid=$1
	if [ $nodeid = 1 ]; then
		mate_id=2
	elif [ $nodeid = 2 ];then
		mate_id=1
	fi
	echo $mate_id
}

function is_agent_active(){

	nodeid=`get_nodeid`
	state=$(amf-state siass | grep SU"$nodeid" -A 1 | grep saAmfSISUHAState | cut -d = -f2 | cut -d "(" -f1)
	if [[ "$state" = "ACTIVE" ]];
	then
		return $TRUE	
	fi
	return $FALSE
}

function shutdown_agent(){

	active_su_id=$1
	node=$2

	stndby_su_id=`get_matenodeid $active_su_id`
	
	if [[ "$node" = "LOCAL" ]]; then
		immadm -o 2 safSu=APG_SU"$active_su_id"_Agent,safSg=APG_2NSG_Agent,safApp=APG_Agent
		immadm -o 3 safSu=APG_SU"$active_su_id"_Agent,safSg=APG_2NSG_Agent,safApp=APG_Agent
	elif [[ "$node" = "MATE" ]]; then
		immadm -o 2 safSu=APG_SU"$stndby_su_id"_Agent,safSg=APG_2NSG_Agent,safApp=APG_Agent
		immadm -o 3 safSu=APG_SU"$stndby_su_id"_Agent,safSg=APG_2NSG_Agent,safApp=APG_Agent
	fi
}

function wait_for_shutdown(){

	node=$1
	local start=$(date +"%s")
	local now=$start
	nodeid=`get_nodeid`
	mate_id=`get_matenodeid $nodeid`

	while test $((now-start)) -le $timeout
	do
		if [[ "$node"  = "LOCAL" ]]; then
			agent_pid=$($pidof "/opt/ap/apos/bin/apos_ha_rdeagentd")
		elif [[ "$node" = "MATE" ]]; then
			agent_pid=`rsh SC-2-$mate_id pidof "/opt/ap/apos/bin/apos_ha_rdeagentd"`
		fi
		if [ -z $agent_pid ]; then
			break
		fi
		usleep 500000
		now=$(date +"%s")
	done
	
	if [ -z $agent_pid ]; then
		return $exit_success
	else
		return $exit_failure
	fi
}

#
# M A I N
#

log "RDE_Agent: Upgrade Started."
nodeid=$(get_nodeid)
is_agent_running
rCode=$?
if [[ $rCode = $FALSE ]]; then
	log "RDE_Agent: Agent not running. Exiting."
	exit $exit_success
fi

is_agent_active
rCode=$?
if [[ $rCode = $FALSE ]]; then
	log "STNDBY AGENT: Waiting for Shutdown initiation from the Active agent"
	exit $exit_success
fi

log "ACTIVE AGENT: Ordering shutdown of STANDBY Agent"
shutdown_agent $nodeid MATE
wait_for_shutdown MATE 
rCode=$?

if [[ "$rCode" = "$exit_failure" ]]; then
	log "ACTIVE AGENT: It seems STNDBY Agent is still up.Exiting..."
	exit $exit_failure
fi

log "ACTIVE AGENT: Shutting down active agent"

shutdown_agent $nodeid LOCAL
wait_for_shutdown LOCAL
rCode=$?

if [ $rCode == 0 ]; then
	log "Agent terminated successfully, Please proceed with the upgrade"
else
	log "Could not stop Agent"
fi

exit $rCode
