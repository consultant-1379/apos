#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1B.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1B.
# Note:
#	None.
##
# Changelog:
# - Wed Oct 07 2015 - Pratap Reddy Uppada(XPRAUPP)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
SRC='/opt/ap/apos/etc/deploy'
CFG_PATH='/opt/ap/apos/conf'
AP_TYPE=$(apos_get_ap_type)
CORE_DUMP_DIR="/var/log/core"

#------------------------------------------------------------------------------#

# R1B --> R1C
#------------------------------------------------------------------------------#
##
# BEGIN: New group creation for LAPH0
# Create the new CpRole groups 
pushd $CFG_PATH &> /dev/null
apos_check_and_call $CFG_PATH aposcfg_group.sh
popd &> /dev/null
# END: Groups creation
##

##
# BEGIN: Change permissions on APG coredump folder 
[ ! -d $CORE_DUMP_DIR ] && apos_abort "$CORE_DUMP_DIR not found"
chmod 777 $CORE_DUMP_DIR
# END: Change permission
##

##
#BEGIN Remove of PCP setting for Internal and External APG Vlans
STORAGE_API='/usr/share/pso/storage-paths/config'
STORAGE_PATH=$(cat $STORAGE_API)
STORAGE_PATH_APOS="$STORAGE_PATH/apos"
RHOST=$(</etc/cluster/nodes/peer/hostname)
PEER_NODE_UP=$FALSE
VLAN_MAPING_CONF="/cluster/etc/ap/apos/vlan_adapter_maping.conf"

SHELF_ARCH=$(get_shelf_architecture)
[ -z "$SHELF_ARCH" ] && apos_abort "shelf architecture found NULL"

if [ "$SHELF_ARCH" == "DMX" ]; then
  # EGEM2, GEP5, EVO and BSP configuration: oam_vlanid is mandatory.
  # check if the remote node is up
  /bin/ping -c 1 -W 1 $RHOST &>/dev/null
  [ $? -eq 0 ] && PEER_NODE_UP=$TRUE
  # Removing  PCP value for tipc_vlan, network_10g_vlantag and
  # oam_vlanid. setting default value 0
  OAM_VLANTAG=$( cat $STORAGE_PATH_APOS/oam_vlanid)
  TIPC_VLANTAG=$( cat $STORAGE_PATH_APOS/tipc_vlantag)
  NW10G_VLANTAG=$( cat $STORAGE_PATH_APOS/network_10g_vlantag)
  INTERNAL_VLAN_TAGS="$TIPC_VLANTAG $NW10G_VLANTAG $OAM_VLANTAG"

  for vlan in $INTERNAL_VLAN_TAGS; do
    for INTERFACE in $( /opt/ap/apos/bin/clusterconf/clusterconf interface  -D | grep -w vlan | grep ".$vlan" | awk -F' ' '{print $4}'); do
      /sbin/vconfig  set_egress_map $INTERFACE 0 0  &>/dev/null
      [ $? -ne 0 ] && apos_abort "Error removing PCP, no changes done"
      if [ $PEER_NODE_UP -eq $TRUE ]; then
        /usr/bin/rsh $RHOST /sbin/vconfig set_egress_map $INTERFACE 0 0  &>/dev/null
        [ $? -ne 0 ] && apos_abort "ERROR: Error removing PCP, no changes done"
      fi
      apos_log "PCP value successfully removed on vlan $INTERFACE"
    done
  done

  #Remove  files to store PCP values for internal APG vlans
  rm -f $STORAGE_PATH_APOS/tipc_vlan_pcp
  rm -f $STORAGE_PATH_APOS/oam_vlan_pcp
  rm -f $STORAGE_PATH_APOS/network_10G_pcp

  # Remove PCP values for external vlans
  CNT=0
  for l_VLAN_NAME in $( cat $VLAN_MAPING_CONF | awk '{print $1}');
  do
    l_PCP=$(echo $(cat $VLAN_MAPING_CONF | grep -w "$l_VLAN_NAME" | awk '{print $3}'))
    l_INTERFACE=$(echo $(cat $VLAN_MAPING_CONF | grep -w "$l_VLAN_NAME" | awk '{print $2}'))
    /sbin/vconfig  set_egress_map $l_INTERFACE 0 0  &>/dev/null
    [ $? -ne 0 ] && apos_abort "Error removing PCP, no changes done"
    if [ $PEER_NODE_UP -eq $TRUE ]; then
      /usr/bin/rsh $RHOST /sbin/vconfig set_egress_map $l_INTERFACE 0 0  &>/dev/null
      [ $? -ne 0 ] && apos_abort "ERROR: Error removing PCP, no changes done"
    fi
    # Remove PCP values from VLAN_MAPPING_CONF file for external vlans
    ((CNT=CNT + 1))
    SUBS_STR="\t$l_PCP"
    sed -i "$CNT"s/$SUBS_STR$/$NULL_STR/ $VLAN_MAPING_CONF
    apos_log "PCP value successfully removed on vlan $l_INTERFACE"
  done
fi
##
#END Remove of PCP setting for Internal and External APG Vlans

##
# BEGIN: arp_ip_target fix for BSP
function log(){
    /bin/logger -t $(basename $0) -- "$*"
}

function abort(){
    log "ABORT: $*"
    cleanup
    exit $FALSE
}

function cleanup(){
    rm $ORIG_CLUSTERCONF &>/dev/null
}

function roll_back_and_abort(){
    if [ -s $ORIG_CLUSTERCONF ]; then
        cp $ORIG_CLUSTERCONF $CLUSTERCONF &>/dev/null || log "failure while copying $ORIG_CLUSTERCONF to $CLUSTERCONF"
        cluster config --reload --all &>/dev/null || log "failure while reloading cluster configuration"
    else
        log "$ORIG_CLUSTERCONF not existing or empty"
    fi
    abort "$*"
}

function isCableless(){
    local OAM_ACCESS=$(< $(</usr/share/pso/storage-paths/config)/apos/apg_oam_access)
    if [ -z "$OAM_ACCESS" ]; then
        log "empty or non-existing apg_oam_access file" >&2
        exit $FALSE
    else
        log "found \"$OAM_ACCESS\" in apg_oam_access"
    fi
    
    if [ "$OAM_ACCESS" == 'NOCABLE' ]; then
        return $TRUE
    fi
    return $FALSE
}

function manipulate_cluster_conf(){
    local NODE_B_IP='169\.254\.213\.2'
    local NODE_A_IP='169\.254\.213\.1'
    local LEGACY_ROW_1="^[[:space:]]*bonding[[:space:]]+1[[:space:]]+bond1[[:space:]]+arp_ip_target[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+${NODE_B_IP}"
    local LEGACY_ROW_2="^[[:space:]]*bonding[[:space:]]+2[[:space:]]+bond1[[:space:]]+arp_ip_target[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+${NODE_A_IP}"
    local GATEWAY_IP=$(</etc/cluster/nodes/this/routes/0/gateway)
    [ -z "$GATEWAY_IP" ] && abort "no default gateway found"
    local NEW_ROW="bonding control bond1 arp_ip_target ${GATEWAY_IP}"
    for LEGACY_ROW in $LEGACY_ROW_1 $LEGACY_ROW_2; do
        if grep -Pq "$LEGACY_ROW" $CLUSTERCONF; then
            sed -r -i "/$LEGACY_ROW/ d" $CLUSTERCONF \
                || roll_back_and_abort "failure while deleting legacy arp_ip_target entry from cluster.conf"
        else
            roll_back_and_abort "Expected bonding row not found!"
        fi
    done
    sed -r -i "/^#[[:space:]]*arp target/ a ${NEW_ROW}" $CLUSTERCONF \
        || roll_back_and_abort "failure while inserting new arp_ip_target entry in cluster.conf"
}

function old_rows_are_present(){
    COUNT=$(grep -P '^[[:space:]]*bonding[[:space:]]+[12][[:space:]]+bond1[[:space:]]+arp_ip_target[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)' $CLUSTERCONF | wc -l)
    if [ $COUNT -eq 2 ]; then
        return $TRUE
    fi
    return $FALSE
}

function new_row_is_present(){
    local GATEWAY_IP=$(</etc/cluster/nodes/this/routes/0/gateway)
    [ -z "$GATEWAY_IP" ] && abort "no default gateway found"
    local NEW_ROW="bonding control bond1 arp_ip_target ${GATEWAY_IP}"
    COUNT=$(grep -P "^[[:space:]]*${NEW_ROW}" $CLUSTERCONF | wc -l)
    if [ $COUNT -eq 1 ]; then
        return $TRUE
    fi
    return $FALSE
}

function verify_settings(){
    if ! old_rows_are_present && new_row_is_present; then
        log "new settings successfully verified"
    else
        roll_back_and_abort "failure while verifying settings"
    fi
}

function reload_cluster_conf(){
    cluster config --validate &>/dev/null || roll_back_and_abort "failure while validating new cluster.conf"
    cluster config --reload --all &>/dev/null || roll_back_and_abort "failure while reloading cluster.conf"
}

function apply_configuration(){
    local PEER_NODE_ADDRESS=$(</etc/cluster/nodes/peer/ip/169.254.213.?/address)
    if grep -q "$PEER_NODE_ADDRESS" /sys/class/net/bond1/bonding/arp_ip_target; then
        echo -$PEER_NODE_ADDRESS > /sys/class/net/bond1/bonding/arp_ip_target
    else
        log "$PEER_NODE_ADDRESS not present in arp_ip_target. Skipping configuration"
    fi
}


#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|
#
TRUE=$(true; echo $?)
FALSE=$(false; echo $?)
CLUSTERCONF='/cluster/etc/cluster.conf'
ORIG_CLUSTERCONF=$(mktemp --tmpdir cluster.conf.XXX)

trap "roll_back_and_abort 'signal received. Rolling-back and cleaning up...'" SIGINT SIGTERM SIGHUP

log "entering the script..."

if isCableless; then
    log "Cable-less (NOCABLE) configuration found. Applying arp_ip_target modifications..."
    if old_rows_are_present; then
        cp $CLUSTERCONF $ORIG_CLUSTERCONF || abort "failure while backing-up original cluster.conf."
        manipulate_cluster_conf
        verify_settings
        reload_cluster_conf
        apply_configuration
        log "arp_ip_target modifications done"
        cleanup
    elif new_row_is_present; then
        log "Configuration already present in cluster.conf. Skipping configuration."
    else
        abort "Unexpected cluster.conf configuration found."
    fi
else
    log "FRONTCABLE configuration found. Skipping arp_ip_target modifications."
fi

log "script successfully completed."
# END: arp_ip_target fix for BSP
##

#------------------------------------------------------------------------------#

# R1B -> R1C
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R1C
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1C"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
