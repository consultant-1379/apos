#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_configdrive.sh
# Description:
#       A Script to fetch all values contained in the configdrive.
#       The script will create a cache file with an intermediate format "lvalue=rvalue".
#       uuid=""
#       nic_net_mapping"list"
#       deploy_values="list"
#
##
# Usage:
#       call: apos_configdrive.sh --help
##
# Changelog:
# - Thu Oct 25 2018 - Dharma Teja (XDHATEJ)
# Changed logic in is_static_network for stack names containing OM in their name
# - Tue Sep 18 2018 - Bavana Harika (XHARBAV)/Pranshu Sinha (XPRANSI)
# Adapted for SWM2.0
# - Tue Jan 23 2018 - Rajashekar Narla (xcsrajn)
# Adapted for metadata handling
# - Wed Feb 22 2017 - Pranshu Sinha (xpransi)
# Adapted for dynamic mac address handling
# - Thu Nov 03 2016 - Antonio Buonocunto (eanbuon)
# First version


#source of common_functions
. "/opt/ap/apos/bin/gi/lib/common/common_functions"

#source of the file storing the logic names for the networks
. "/opt/ap/apos/bin/gi/lib/common/staticNetworks"
. "/opt/ap/apos/bin/gi/lib/common/dynamicNetworks"

#source of network interface names file
. "/opt/ap/apos/bin/gi/lib/common/networkInterfaces"

CONFIGDRIVE_MOUNT_FOLDER='/mnt/config_drive'

NETWORK_LOGIC_NAME=""
OPENSTACK_NETINFO_LOGICAL_NAME=""
OPENSTACK_NETINFO_INTERFACE_NAME=""
STATIC_NETWORK_LIST="/opt/ap/apos/bin/gi/lib/common/staticNetworks"
DYNAMIC_NETWORK_LIST="/opt/ap/apos/bin/gi/lib/common/dynamicNetworks"
CUSTOM_COUNTER=0
STORAGE_API='/usr/share/pso/storage-paths/config'
PSO_PATH=$(<$STORAGE_API)
APOS_PSO="$PSO_PATH/apos/"
CMD_XMLLINT='/usr/bin/xmllint'

function is_static_network() {
  local LOCAL_CONFIGDRIVE_NETWORK=$1
  local NETWORK_TYPE="$($CMD_ECHO $LOCAL_CONFIGDRIVE_NETWORK | awk -F'_' '{ print $NF }')"
  while read network; do
  
    if [[ $NETWORK_TYPE == $network ]]; then
      NETWORK_LOGIC_NAME="$(echo $network | sed 's/\-//g')"
      return $TRUE
      break;
    fi
  done < <(awk -F'=' '{ print $2 }' $STATIC_NETWORK_LIST)
  return $FALSE
  
}

function fetch_dynamic_mac() {
  while read element; do
    STATIC_NETWORK_FLAG=$FALSE
    CONFIGDRIVE_MAC="$($CMD_ECHO $element | awk -F',' '{ print $1 }' | awk -F'=' '{ print $2 }' )"
    if [ -z "$CONFIGDRIVE_MAC" ]; then
      apos_abort "Failure while fetching MAC address from configdrive"
    fi
    CONFIGDRIVE_NETWORK="$($CMD_ECHO $element | awk -F',' '{ print $2 }' | awk -F'=' '{ print $2 }')"
    if [ -z "$CONFIGDRIVE_NETWORK" ]; then
      apos_abort "Failure while fetching network name from configdrive"
    fi
    CONFIGDRIVE_vNIC="$($CMD_ECHO $element | awk -F',' '{ print $3 }' | awk -F'=' '{ print $2 }')"
    if [ -z "$CONFIGDRIVE_vNIC" ]; then
      apos_abort "Failure while fetching vNIC name from configdrive"
    fi
    if ! is_static_network $CONFIGDRIVE_NETWORK; then
      DYNAMIC_NETWORK_NAMES="$($CMD_CAT $DYNAMIC_NETWORK_LIST | awk -F'=' '{ print $2 }')"
      CUSTOM_COUNTER=$(($CUSTOM_COUNTER + 1))
      NETWORK_LOGIC_NAME=$(echo $DYNAMIC_NETWORK_NAMES | awk "{ print $"$CUSTOM_COUNTER" }")
    fi
    if [ -z "$NETWORK_LOGIC_NAME" ]; then
      apos_abort "Failure while fetching network logical name"
    fi
    eval OPENSTACK_NETINFO_LOGICAL_NAME="\$GETINFO_$NETWORK_LOGIC_NAME"
    if [ -z "$OPENSTACK_NETINFO_LOGICAL_NAME" ]; then
      apos_abort "Failure while fetching network logical name for $NETWORK_LOGIC_NAME network"
    fi
    eval OPENSTACK_NETINFO_INTERFACE_NAME="\$GETINFO_"$NETWORK_LOGIC_NAME"_INTERFACE"
    if [ -z "$OPENSTACK_NETINFO_INTERFACE_NAME" ]; then
      apos_abort "Failure while fetching interface name for "$NETWORK_LOGIC_NAME"_INTERFACE"
    fi
    OPENSTACK_NETINFO="$OPENSTACK_NETINFO_LOGICAL_NAME;$CONFIGDRIVE_NETWORK;$OPENSTACK_NETINFO_INTERFACE_NAME;$CONFIGDRIVE_MAC;$CONFIGDRIVE_vNIC"

    if [ -z "$OPENSTACK_NETINFO" ] ; then
      apos_abort "Failure while fetching NETINFO from configdrive"
    fi
    # write NETINFO to cache
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO"
  done < <(grep -P '^mac=.*,network=.*,vnic=.*' $CONFIGDRIVE_FILE_USERDATA)
}

#MAIN
validate_cache_file
if [ -s "$GETINFO_CACHE_FILE" ];then
  $CMD_CAT $GETINFO_CACHE_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failure while reading information from cache file"
  fi
else
  mount_cdrom_by_label 'config-2' $CONFIGDRIVE_MOUNT_FOLDER
  CONFIGDRIVE_FILE_USERDATA="$(find "$CONFIGDRIVE_MOUNT_FOLDER/openstack/latest" -maxdepth 1 -type f -name "user_data")"
  CONFIGDRIVE_FILE_METADATA="$(find "$CONFIGDRIVE_MOUNT_FOLDER/openstack/latest" -maxdepth 1 -type f -name "meta_data.json")"
  [ -z "$CONFIGDRIVE_FILE_USERDATA" ] && apos_abort 1 "user_data file not found"
  [ -z "$CONFIGDRIVE_FILE_METADATA" ] && apos_abort 1 "meta_data.json file not found"
  $CMD_XMLLINT --format $CONFIGDRIVE_FILE_USERDATA 2>/dev/null
  if [ $? -eq 0 ]; then
    if [ -x "/opt/ap/apos/bin/gi/lib/fetch_method/user_data.sh" ]; then
      /opt/ap/apos/bin/gi/lib/fetch_method/user_data.sh $CONFIGDRIVE_FILE_USERDATA &>/dev/null || apos_abort 1 "failure while executing user_data.sh"
    else
      apos_abort 1 "file \"user_data.sh\" not found or not executable"
    fi
    NODE_ID=$($CMD_CAT /etc/cluster/nodes/this/id)
    CONFIGDRIVE_FILE_USERDATA="$APOS_PSO"'user_data_updated_'"$NODE_ID"
  fi
  create_cache_file
  # write user data values in the cache file
  for CONFIGDRIVE_USERDATA_ITEM in $($CMD_CAT $CONFIGDRIVE_FILE_USERDATA); do
    write_item_to_cache_file 'PROPERTIES' "$CONFIGDRIVE_USERDATA_ITEM"
  done
  # write uuid to cache file
  CONFIGDRIVE_UUID="$($CMD_CAT $CONFIGDRIVE_FILE_METADATA | $CMD_PYTHON -c "import sys, json; print json.load(sys.stdin)['uuid']")"
  if [ -z "$CONFIGDRIVE_UUID" ];then
    apos_abort "Failure while fetching UUID from configdrive"
  fi
  write_item_to_cache_file 'UUID' "$CONFIGDRIVE_UUID"

  # write metadata to cache file
  CONFIGDRIVE_META="$($CMD_CAT $CONFIGDRIVE_FILE_METADATA | $CMD_PYTHON -c "import sys, json; print json.dumps(json.load(sys.stdin)['meta'])" 2>/dev/null)"
  # TR Fix for HW72572:
  # Deployment should continue even though meta-data is not 
  # provided in HOT template.
  if [ -z "$CONFIGDRIVE_META" ]; then 
    apos_log "WARNING: metadata section found NULL, Skipping metadata update to cache file." 
  else
    write_item_to_cache_file 'METADATA' "$CONFIGDRIVE_META"
  fi

  # Fetch dynamic MAC address from config drive
  fetch_dynamic_mac

  $CMD_CAT $GETINFO_CACHE_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failure while reading information from cache file"
  fi
  umount_cdrom $CONFIGDRIVE_MOUNT_FOLDER
fi


