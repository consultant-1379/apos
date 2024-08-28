#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_configdrive.sh
# Description:
#	A Script to fetch all values contained in the configdrive.
#	The script will create a cache file with an intermediate format "lvalue=rvalue".
#	uuid=""
#	nic_net_mapping"list"
#	deploy_values="list"
#
##
# Usage:
#       call: apos_configdrive.sh --help
##
# Changelog:
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

OPENSTACK_NETINFO_OM_1_MAC="C6:CF:A1:00:A0:01"
OPENSTACK_NETINFO_APZA_1_MAC="C6:CF:A1:00:A0:03"
OPENSTACK_NETINFO_APZB_1_MAC="C6:CF:A1:00:A0:04"
OPENSTACK_NETINFO_LDE_1_MAC="C6:CF:A1:00:A0:05"
OPENSTACK_NETINFO_DRBD_1_MAC="C6:CF:A1:00:A0:06"
OPENSTACK_NETINFO_CUST1_1_MAC="C6:CF:A1:00:A0:07"
OPENSTACK_NETINFO_CUST2_1_MAC="C6:CF:A1:00:A0:08"
OPENSTACK_NETINFO_OM_2_MAC="C6:CF:A1:00:A1:01"
OPENSTACK_NETINFO_APZA_2_MAC="C6:CF:A1:00:A1:03"
OPENSTACK_NETINFO_APZB_2_MAC="C6:CF:A1:00:A1:04"
OPENSTACK_NETINFO_LDE_2_MAC="C6:CF:A1:00:A1:05"
OPENSTACK_NETINFO_DRBD_2_MAC="C6:CF:A1:00:A1:06"
OPENSTACK_NETINFO_CUST1_2_MAC="C6:CF:A1:00:A1:07"
OPENSTACK_NETINFO_CUST2_2_MAC="C6:CF:A1:00:A1:08"

OPENSTACK_NETINFO_OM_1="$GETINFO_OM;;$GETINFO_OM_INTERFACE;$OPENSTACK_NETINFO_OM_1_MAC"
OPENSTACK_NETINFO_APZA_1="$GETINFO_APZA;;$GETINFO_APZA_INTERFACE;$OPENSTACK_NETINFO_APZA_1_MAC"
OPENSTACK_NETINFO_APZB_1="$GETINFO_APZB;;$GETINFO_APZB_INTERFACE;$OPENSTACK_NETINFO_APZB_1_MAC"
OPENSTACK_NETINFO_LDE_1="$GETINFO_LDE;;$GETINFO_LDE_INTERFACE;$OPENSTACK_NETINFO_LDE_1_MAC"
OPENSTACK_NETINFO_DRBD_1="$GETINFO_DRBD;;$GETINFO_DRBD_INTERFACE;$OPENSTACK_NETINFO_DRBD_1_MAC"
OPENSTACK_NETINFO_CUST1_1="$GETINFO_CUST1;;$GETINFO_CUST1_INTERFACE;$OPENSTACK_NETINFO_CUST1_1_MAC"
OPENSTACK_NETINFO_CUST2_1="$GETINFO_CUST2;;$GETINFO_CUST2_INTERFACE;$OPENSTACK_NETINFO_CUST2_1_MAC"
OPENSTACK_NETINFO_OM_2="$GETINFO_OM;;$GETINFO_OM_INTERFACE;$OPENSTACK_NETINFO_OM_2_MAC"
OPENSTACK_NETINFO_APZA_2="$GETINFO_APZA;;$GETINFO_APZA_INTERFACE;$OPENSTACK_NETINFO_APZA_2_MAC"
OPENSTACK_NETINFO_APZB_2="$GETINFO_APZB;;$GETINFO_APZB_INTERFACE;$OPENSTACK_NETINFO_APZB_2_MAC"
OPENSTACK_NETINFO_LDE_2="$GETINFO_LDE;;$GETINFO_LDE_INTERFACE;$OPENSTACK_NETINFO_LDE_2_MAC"
OPENSTACK_NETINFO_DRBD_2="$GETINFO_DRBD;;$GETINFO_DRBD_INTERFACE;$OPENSTACK_NETINFO_DRBD_2_MAC"
OPENSTACK_NETINFO_CUST1_2="$GETINFO_CUST1;;$GETINFO_CUST1_INTERFACE;$OPENSTACK_NETINFO_CUST1_2_MAC"
OPENSTACK_NETINFO_CUST2_2="$GETINFO_CUST2;;$GETINFO_CUST2_INTERFACE;$OPENSTACK_NETINFO_CUST2_2_MAC"


#MAIN
validate_cache_file
if [ -s "$GETINFO_CACHE_FILE" ];then
  $CMD_CAT $GETINFO_CACHE_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failure while reading information from cache file"
  fi
else
  NODE_ID=$($CMD_CAT /etc/cluster/nodes/this/id)
  if [ "$NODE_ID" != "1" ] && [ "$NODE_ID" != "2" ];then
    apos_abort "Failure while fetching node id"
  fi
  mount_cdrom_by_label 'config-2' $CONFIGDRIVE_MOUNT_FOLDER
  CONFIGDRIVE_FILE_USERDATA="$(find "$CONFIGDRIVE_MOUNT_FOLDER/openstack/latest" -maxdepth 1 -type f -name "user_data")"
  CONFIGDRIVE_FILE_METADATA="$(find "$CONFIGDRIVE_MOUNT_FOLDER/openstack/latest" -maxdepth 1 -type f -name "meta_data.json")"
  [ ! -f "$CONFIGDRIVE_FILE_USERDATA" ] && apos_abort 1 "user_data file not found"
  [ ! -f "$CONFIGDRIVE_FILE_METADATA" ] && apos_abort 1 "meta_data file not found"
  # Find OM MAC
  for CONFIGDRIVE_MAC_ITEM in $($CMD_FIND  /sys/class/net -name "eth[0-9]");do
    CONFIGDRIVE_LOCAL_MAC="$($CMD_CAT $CONFIGDRIVE_MAC_ITEM/address)"
    CONFIGDRIVE_LOCAL_MAC="$($CMD_ECHO $CONFIGDRIVE_LOCAL_MAC | $CMD_AWK '{print toupper($0)}')"
    if [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_APZA_1_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_APZB_1_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_LDE_1_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_DRBD_1_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_CUST1_1_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_CUST2_1_MAC" ];then
      OPENSTACK_NETINFO_OM_1_MAC="$CONFIGDRIVE_LOCAL_MAC"
      OPENSTACK_NETINFO_OM_1="$GETINFO_OM;;$GETINFO_OM_INTERFACE;$OPENSTACK_NETINFO_OM_1_MAC"
    fi
  done
  if [ -z "$OPENSTACK_NETINFO_OM_1_MAC" ];then
    apos_abort "Failure while fetching OM MAC"
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
  # write NETINFO to cache
  if [ "$NODE_ID" = "1" ];then
    # Find OM MAC
    for CONFIGDRIVE_MAC_ITEM in $($CMD_FIND  /sys/class/net -name "eth[0-9]");do
      CONFIGDRIVE_LOCAL_MAC="$($CMD_CAT $CONFIGDRIVE_MAC_ITEM/address)"
      CONFIGDRIVE_LOCAL_MAC="$($CMD_ECHO $CONFIGDRIVE_LOCAL_MAC | $CMD_AWK '{print toupper($0)}')"
      if [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_APZA_1_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_APZB_1_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_LDE_1_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_DRBD_1_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_CUST1_1_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_CUST2_1_MAC" ];then
        OPENSTACK_NETINFO_OM_1_MAC="$CONFIGDRIVE_LOCAL_MAC"
        OPENSTACK_NETINFO_OM_1="$GETINFO_OM;;$GETINFO_OM_INTERFACE;$OPENSTACK_NETINFO_OM_1_MAC"
      fi
    done
    if [ -z "$OPENSTACK_NETINFO_OM_1_MAC" ];then
      apos_abort "Failure while fetching OM MAC"
    fi
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_OM_1"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_APZA_1"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_APZB_1"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_LDE_1"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_DRBD_1"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_CUST1_1"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_CUST2_1"
  elif [ "$NODE_ID" = "2" ];then
    # Find OM MAC
    for CONFIGDRIVE_MAC_ITEM in $($CMD_FIND  /sys/class/net -name "eth[0-9]");do
      CONFIGDRIVE_LOCAL_MAC="$($CMD_CAT $CONFIGDRIVE_MAC_ITEM/address)"
      CONFIGDRIVE_LOCAL_MAC="$($CMD_ECHO $CONFIGDRIVE_LOCAL_MAC | $CMD_AWK '{print toupper($0)}')"
      if [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_APZA_2_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_APZB_2_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_LDE_2_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_DRBD_2_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_CUST1_2_MAC" ] && [ "$CONFIGDRIVE_LOCAL_MAC" != "$OPENSTACK_NETINFO_CUST2_2_MAC" ];then
        OPENSTACK_NETINFO_OM_2_MAC="$CONFIGDRIVE_LOCAL_MAC"
        OPENSTACK_NETINFO_OM_2="$GETINFO_OM;;$GETINFO_OM_INTERFACE;$OPENSTACK_NETINFO_OM_2_MAC"
      fi
    done
    if [ -z "$OPENSTACK_NETINFO_OM_2_MAC" ];then
      apos_abort "Failure while fetching OM MAC"
    fi
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_OM_2"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_APZA_2"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_APZB_2"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_LDE_2"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_DRBD_2"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_CUST1_2"
    write_item_to_cache_file 'NETINFO' "$OPENSTACK_NETINFO_CUST2_2"
  fi
  $CMD_CAT $GETINFO_CACHE_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failure while reading information from cache file"
  fi
  umount_cdrom $CONFIGDRIVE_MOUNT_FOLDER
fi

