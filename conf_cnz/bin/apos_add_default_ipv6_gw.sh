#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_add_default_ipv6_gw.sh
# Description:
#       A script to add the default gateway for IPv6 at deployment time.
# Note:
#      Only executed in IPv6 and Dual Stack scenario's during deployment time
##
# Usage:
#       None.
##
# Changelog:
# - Mon Aug 02 2020 - Rajeshwari Padavala
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#variables
CMD_CLUSTERCONF=/opt/ap/apos/bin/clusterconf/clusterconf
CMD_IP=/sbin/ip
CMD_AWK=/usr/bin/awk
CMD_GREP=/usr/bin/grep
RM_INTERACE="default_v6"

function default_gw() {
  local operation="$1"
  local ipv6_add="$2"

  if [ $operation == 'delete' ]; then
    opt='del'
  elif [ $operation == 'add' ]; then 
    opt='add'
  fi 
  
  $CMD_IP -6 route $opt default via $ipv6_add dev eth1 &>/dev/null
  if [ $? -ne 0 ] ; then
    apos_log "Failed to $operation default IPv6 gateway from route table"
  else
    apos_log "Default IPv6 gateway [$ipv6_add] ${operation}ed successfully"
  fi 
}

function update_default_ipv6_gw() {

  CLU_DEFAULT_GW_ADDRESS=$( $CMD_CLUSTERCONF route --display |$CMD_GREP $RM_INTERACE |\
                            $CMD_AWK 'BEGIN { ORS = "\n" }{if ($6~"[::]") print $6}'|sort  )
  DEFAULT_GW_ADDRESS=$($CMD_IP -6 route|$CMD_GREP "default" |$CMD_AWK '{print $3}')

  # UC1: if (default_v6 GW is present in cluster conf) and (default GW is not present in routing table) then
  # add default_v6 GW of cluster conf
  if [[ -n "$CLU_DEFAULT_GW_ADDRESS" && -z "$DEFAULT_GW_ADDRESS" ]]; then 
    #adding IPv6 default gateway
    default_gw 'add' "$CLU_DEFAULT_GW_ADDRESS"
  # UC2: if (default_v6 GW is present in cluster conf) and (default GW is present in routing table) then
  # if the GWs are not the same
  elif [[ -n "$CLU_DEFAULT_GW_ADDRESS" && -n "$DEFAULT_GW_ADDRESS" ]] ; then
    if [[ "$CLU_DEFAULT_GW_ADDRESS" != "$DEFAULT_GW_ADDRESS" ]]; then 
      default_gw 'delete' "$DEFAULT_GW_ADDRESS"
      default_gw 'add' "$CLU_DEFAULT_GW_ADDRESS"
    fi 
  # UC3: if (default_v6 GW is not present in cluster conf) and (default GW is present in routing table) then
  # delete default GW of routing table
  elif [[ -z "$CLU_DEFAULT_GW_ADDRESS" && -n "$DEFAULT_GW_ADDRESS" ]]; then 
    default_gw 'delete' "$DEFAULT_GW_ADDRESS"
  fi 

}

## M A I N ##

if is_vAPG; then
  if [[ isIPv6Stack || isDualStack ]]; then 
    update_default_ipv6_gw
  fi 
else
  apos_log 'No default gateway update is required in Native!!'

fi 

apos_outro $0

exit $TRUE
