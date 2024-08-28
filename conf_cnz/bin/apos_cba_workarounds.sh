#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_cba_workarounds.sh
# Description:
#       Applying workarounds provided by CBA
# Note:
#       None.
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Wed Nov 21 2018 - Nazeema Begum (xnazbeg)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Variables
FILE="/etc/sysconfig/nfs"
SYSTEMCTL_CMD="/usr/bin/systemctl"
CMD_SSH="/usr/bin/ssh"
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
peer_hostname=$(cat /etc/cluster/nodes/peer/hostname)
this_hostname=$(cat /etc/cluster/nodes/this/hostname)
AP_TYPE=$(apos_get_ap_type)

function sanity_checks(){
        #check hardware type
        [ -z "$HW_TYPE" ] && apos_abort 1 'HW_TYPE not found'
        if [ "$HW_TYPE" == "GEP1" ]; then
		apos_log "The script apos_cba_workarounds.sh is executing on $HW_TYPE configuration ..."
                [[ -f "$FILE" ]] || apos_abort 1 "file \"$FILE\" not found"
                apos_modify_GEP1_perfparm
                #apos_tipc_flickering
        elif [ "$HW_TYPE" == "GEP2" ];then
                apos_log "The script apos_cba_workarounds.sh is executing on $HW_TYPE configuration ..."
                #apos_tipc_flickering
        else
                apos_log "The script apos_cba_workarounds.sh is not applicable to $HW_TYPE configuration ..."
                exit $TRUE
        fi
}
function apos_modify_GEP1_perfparm()
{

        sed -i "s/USE_KERNEL_NFSD_NUMBER.*/USE_KERNEL_NFSD_NUMBER=4/g" $FILE || apos_abort "failure while editing the $FILE file"
        ${CMD_SSH} ${peer_hostname} sed -i "s/USE_KERNEL_NFSD_NUMBER.*/USE_KERNEL_NFSD_NUMBER=4/g" $FILE || apos_abort "failure while editing the $FILE file"

        #Restart nfs-server only on active
        status=$(${SYSTEMCTL_CMD} is-active nfs-server)

        if [ "$status" == "active" ]; then
                 apos_servicemgmt restart nfs-server.service &>/dev/null || apos_abort 'failure while restarting nfs service'
        else
                apos_log "NFS service restart was not performed..."
        fi

}
function apos_tipc_flickering()
{
        #Disable RPS for both SC1 and SC2
        for e in $(echo "eth3 eth4"); do for x in $(ls /sys/class/net/$e/queues/rx-*/rps_cpus); do echo "0" > $x; done; done
	
	if [ "$AP_TYPE" == "AP1" ];then
        #Increase TIPC tolerance to 25000ms(Default is 1500ms)
		tipc bear set tolerance 25000 media eth dev eth4.33 &>/dev/null || apos_abort 'failure while setting the tipc tolerance on this node'
		tipc bear set tolerance 25000 media eth dev eth3.33 &>/dev/null || apos_abort 'failure while setting the tipc tolerance on this node'
	elif [ "$AP_TYPE" == "AP2" ];then
		tipc bear set tolerance 25000 media eth dev eth4.34 &>/dev/null || apos_abort 'failure while setting the tipc tolerance on this node'
        	tipc bear set tolerance 25000 media eth dev eth3.34 &>/dev/null || apos_abort 'failure while setting the tipc tolerance on this node'
	else
		apos_log "Unknown AP_TYPE determined..."
	fi
}


########## Main ###############
sanity_checks
apos_outro $0
exit $TRUE
# End of file
