#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_crmconf.sh
#
# Description:
#       A script to create APG ComputeResource objects.
#
##
# Usage:
#       ./apos_crmconf.sh
##
# Changelog:
# - Thu Jan 04 2017 - Antonio Buonocunto (EANBUON)
#   First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Variables
CMD_GETINFO="/opt/ap/apos/bin/gi/apos_getinfo"
node_id=$(get_node_id)

#-------------------------------------------------------------------------------
function get_base_directory() {
  local network=$1
  local base_dir=''
  for dir in $( find /etc/cluster/nodes/this/ip/*/network); do
    if readlink -f $dir | grep -q "$network" &>/dev/null; then
      base_dir=$(/usr/bin/dirname $dir)
    fi
  done
  if [ -z "$base_dir" ]; then
    apos_abort 1 "base directory not found for ipna and ipnb"
  fi

  echo "$base_dir"
}

#-------------------------------------------------------------------------------
function get_ipn_values() {

  local IPNA_BASE=$(get_base_directory ipna)
  local IPNB_BASE=$(get_base_directory ipnb)

  IPNA_ADDRESS=$(cat $IPNA_BASE/address)
  [ -z "$IPNA_ADDRESS" ] && apos_abort 1 "ipna ip address found NULL"

  IPNA_MAC_ADDRESS=$( cat $IPNA_BASE/interface/address)
  [ -z "$IPNA_MAC_ADDRESS" ] && apos_abort 1 "ipna MAC address found NULL"

  IPNB_ADDRESS=$(cat $IPNB_BASE/address)
  [ -z "$IPNB_ADDRESS" ] && apos_abort 1 "ipnb ip address found NULL"

  IPNB_MAC_ADDRESS=$( cat $IPNB_BASE/interface/address)
  [ -z "$IPNB_MAC_ADDRESS" ] && apos_abort 1 "ipnb MAC address found NULL"

}

#-------------------------------------------------------------------------------
function get_instance_uuid() {

  # Fetch the user data related information
  instance_uuid=$($CMD_GETINFO uuid)
  [ -z "$instance_uuid" ] && apos_abort 1 "Instance UUID found NULL"
}

#-------------------------------------------------------------------------------
function is_compute_resource_class_exist() {
  local CMD_RESULT=$( kill_after_try 3 3 4 /usr/bin/immfind crMgmtId=1,AxeEquipmentequipmentMId=1 2>/dev/null)
  if [ -n "$CMD_RESULT" ]; then
    return $TRUE
  fi
  return $FALSE
}

#-------------------------------------------------------------------------------
function createAxeEquipmentNetworkObjects() {
  local NETWORK_INDEX="$1"
  [ -z "$NETWORK_INDEX" ] && apos_abort 1 "Network index not found"
  local NETWORK_NETNAME="$2"
  [ -z "$NETWORK_NETNAME" ] && apos_abort 1 "Network netName index not found"
  local NETWORK_NIC="$3"
  local NETWORK_MAC="$4"
  [ -z "$NETWORK_MAC" ] && apos_abort 1 "Network MAC address not found"
  local NETWORK_COMPUTE_UUID="$5"
  [ -z "$NETWORK_COMPUTE_UUID" ] && apos_abort 1 "Compute UUID not found"
  
  kill_after_try 5 5 6 "/usr/bin/immcfg -c AxeEquipmentNetwork -a nicName="$NETWORK_NIC" -a netName="$NETWORK_NETNAME" -a macAddress="$NETWORK_MAC" id=network_$NETWORK_INDEX,computeResourceId=$NETWORK_COMPUTE_UUID,crMgmtId=1,AxeEquipmentequipmentMId=1" || \
      apos_abort 1 'Failure while creating AxeEquipmentNetwork objects $NETWORK_NETNAME'
  
  apos_log "AxeEquipmentNetwork $NETWORK_NETNAME successfully created"
}

#                __    __   _______   _   __    _
#               |  \  /  | |  ___  | | | |  \  | |
#               |   \/   | | |___| | | | |   \ | |
#               | |\  /| | |  ___  | | | | |\ \| |
#               | | \/ | | | |   | | | | | | \   |
#               |_|    |_| |_|   |_| |_| |_|  \__|
#

# Fetch ip and mac addresses of ipna and ipnb
get_ipn_values
# Fetch Instance uuid information from the config drive
get_instance_uuid
# Here roleId for Node1 and Node2 are fixed
roleId='20011'
if [ $node_id -eq 2 ]; then
    roleId='20012'
fi

#Fetch ME name
CRM_ME_NAME="$($CMD_GETINFO  properties.me_name | awk -F'=' '{print $2}')"
if [ -z "$CRM_ME_NAME" ]; then
  apos_abort "Failure while fetching me name for compute resource creation"
fi

#Network Name filter
NETNAME_FILTER="$CRM_ME_NAME"_""
apos_log "DEBUG: NetName Filter: $NETNAME_FILTER"

#Create "computeResourceId" on both instances
if is_compute_resource_class_exist; then
  CMD2_RESULT=$( kill_after_try 3 3 4 /usr/bin/immfind -c AxeEquipmentComputeResource computeResourceId="$instance_uuid",crMgmtId=1,AxeEquipmentequipmentMId=1 2>/dev/null)
  if [ "$CMD2_RESULT" != "computeResourceId="$instance_uuid",crMgmtId=1,AxeEquipmentequipmentMId=1" ]; then
    kill_after_try 5 5 6 "/usr/bin/immcfg -c AxeEquipmentComputeResource -a uuid="$instance_uuid" -a macAddressEthB="$IPNB_MAC_ADDRESS" \
       -a macAddressEthA="$IPNA_MAC_ADDRESS" -a ipAddressEthB="$IPNB_ADDRESS" -a ipAddressEthA="$IPNA_ADDRESS" \
       -a crType=2000 -a crRoleId="$roleId" computeResourceId="$instance_uuid",crMgmtId=1,AxeEquipmentequipmentMId=1 -u" || \
      apos_abort 1 'Failure while creating compute resource objects in IMM!'

    #Wait for CS updating the object before creating and adding networks to it
    apos_log "DEBUG: Synchronizing with CS for compute resource objects $instance_uuid"
    ROLE_LABEL="/usr/bin/immlist -a crRoleLabel computeResourceId=$instance_uuid,crMgmtId=1,AxeEquipmentequipmentMId=1"
    i=0; while true; do
      RESULT=$( kill_after_try 3 3 4 "$ROLE_LABEL 2>/dev/null" )
      if [[ $RESULT == "crRoleLabel=AP"* ]]; then
        apos_log "DEBUG: Role label is attached"; break
      fi
      let i+=1; if [ $i -eq 18 ]; then
        apos_log "DEBUG: Role label not attached, proceeding anyway!"; break
      else
        apos_log "DEBUG: Synchronization ongoing, retry #"$i; sleep 10
      fi
    done
    apos_log "DEBUG: Synchronized with CS!"

    NETWORKS_IMM_TRANSACTION="/usr/bin/immcfg "
    NETINFO_LIST="$($CMD_GETINFO netinfo)"
    [ -z "$NETINFO_LIST" ] && apos_abort 1 "Failure while fetching network information"
    NETINFO_INDEX="0"
    for NETINFO_ITEM in $NETINFO_LIST;do
      NETINFO_NET_INTERNAL_NAME="$(echo $NETINFO_ITEM | awk -F';' '{print $1}')"
      NETINFO_NIC="$(echo $NETINFO_ITEM | awk -F';' '{ print $5 }' | sed 's@^.*_@@g')"	
      NETINFO_NETNAME="$(echo $NETINFO_ITEM | awk -F';' '{print $2}' | sed "s@^${NETNAME_FILTER}@@g")"	
      NETINFO_MAC="$(echo $NETINFO_ITEM | awk -F';' '{print $4}')"
      createAxeEquipmentNetworkObjects "$NETINFO_INDEX" "$NETINFO_NETNAME" "$NETINFO_NIC" "$NETINFO_MAC" "$instance_uuid"
      NETWORKS_IMM_TRANSACTION="$NETWORKS_IMM_TRANSACTION -a network=\"id=network_$NETINFO_INDEX,computeResourceId=$instance_uuid,crMgmtId=1,AxeEquipmentequipmentMId=1\" "
      NETINFO_INDEX=$(($NETINFO_INDEX + 1))
    done
    NETWORKS_IMM_TRANSACTION="$NETWORKS_IMM_TRANSACTION computeResourceId="$instance_uuid",crMgmtId=1,AxeEquipmentequipmentMId=1 -u"
    apos_log "DEBUG: Execute Network IMM transaction: $NETWORKS_IMM_TRANSACTION"
    kill_after_try 5 5 6 "$NETWORKS_IMM_TRANSACTION" || apos_abort 1 'Failure while adding networks to compute resource objects $instance_uuid'
    apos_log "DEBUG: Network IMM transaction completed"
    #DEBUG SECTION: START
    DEBUG_IMM_TRANSACTION="/usr/bin/immlist -a network computeResourceId=$instance_uuid,crMgmtId=1,AxeEquipmentequipmentMId=1"
    DEBUG_IMM_TRANS_RESULT="$($DEBUG_IMM_TRANSACTION)"
    DEBUG_IMM_TRANS_RET_CODE=$?
    apos_log "DEBUG: RET_CODE=$DEBUG_IMM_TRANS_RET_CODE value of network attribute of computeResourceId=$instance_uuid,crMgmtId=1,AxeEquipmentequipmentMId=1 object: $DEBUG_IMM_TRANS_RESULT"
    #DEBUG SECTION: END
  else
    apos_log "Compute resource $instance_uuid already existing, skipping the creation"
  fi
else
  apos_abort 1 'MOC [crMgmtId=1,AxeEquipmentequipmentMId=1] not Found'
fi

apos_outro $0
exit $TRUE
