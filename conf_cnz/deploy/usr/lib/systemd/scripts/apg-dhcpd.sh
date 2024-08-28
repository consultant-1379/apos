#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apg-dhcpd.sh
# Description:
#       A script to start the DHCP daemon.
# Note:
#       The present script is executed during the start phase of the 
#      dhcpd.service
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Tue Aug 01 2023 - Swapnika Baradi(xswapba)
#       Fix for TR IA45804
# - Mon Dec 05 2016 - Pratapareddy Uppada(xpraupp)
#       DHCP service disabling/enabling changes.
# - Thu Jan 21 2016 - Antonio Nicoletti (eantnic) - Crescenzo Malvone (ecremal)
#       First version.
##

# Load the APOS common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

AP_TYPE=$(apos_get_ap_type)
APOS_GETINFO='/opt/ap/apos/bin/gi/apos_getinfo'

function isAP2(){
  [ "$AP_TYPE" == "$AP2" ] && return $TRUE
  return $FALSE
}

function isDHCP_ON() {
  local SET_DHCP=$FALSE
#  local DHCP_STATE=$($APOS_GETINFO properties.apg_dhcp | awk -F"=" '{print $2}')
  CMD_HWTYPE='/opt/ap/apos/conf/apos_hwtype.sh'
  HYPERVISOR=$( $CMD_HWTYPE --verbose | grep "system-manufacturer" | awk -F"=" '{print $2}' | sed -e 's@^[[:space:]]*@@g' -e 's@^"@@g' -e 's@"$@@g' )
  if [ -z "$HYPERVISOR" ];then
    apos_log "Failure while fetching hypervisor"
  fi
  if [[ "$HYPERVISOR" =~ .*vmware.* ]];then
    ### Local variables
    OVF_ENV_FILE="/mnt/config/ovf-env.xml"
    OVF_ENV_FILE_MOUNT_POINT='/mnt/config'
    OVF_ENV_FILE_DEVICE_LABEL="OVF ENV"
    DEVICE_NAME=$(blkid -t LABEL="$OVF_ENV_FILE_DEVICE_LABEL" -o device)
    if [ -z "$DEVICE_NAME" ]; then
      apos_log "OVF environment file device not found!"
    fi

    # Device correctly found: create the mount point and mount it
    mkdir -p $OVF_ENV_FILE_MOUNT_POINT
    mount $DEVICE_NAME $OVF_ENV_FILE_MOUNT_POINT
    if [ $? -ne 0 ]; then
      apos_log "Failed to mount the OVF environment file device."
    fi

    # Extract all the needed data from the OVF environment file
    DHCP_TYPE="$(grep 'oe:key="apg_dhcp' $OVF_ENV_FILE | awk -F'oe:value=' '{print $2}' | cut -d '"' -f2)"

    # Dismount the OVF environment file device
    umount $OVF_ENV_FILE_MOUNT_POINT
    if [ $? -ne 0 ]; then
      apos_log "WARNING: Failed to dismount the OVF environment device!"
    fi
    if [[ "$DHCP_TYPE" == 'ON' ]]; then
      SET_DHCP=$TRUE
    else
      SET_DHCP=$TRUE
    fi
  fi
  return $SET_DHCP
}

# check AP type
if ! isAP2; then
  # AP1 
  INTERFACE=''
  HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
  if [ ! -f /etc/cluster/nodes/this/networks/internal/primary/interface/name ]; then
    apos_abort "Interface on internal network not found"
  fi
  INTERFACE=$(</etc/cluster/nodes/this/networks/internal/primary/interface/name)

  INTERFACE2=''
  if [ -f /etc/cluster/nodes/this/networks/ipna/primary/interface/name ]; then
    INTERFACE2=$(</etc/cluster/nodes/this/networks/ipna/primary/interface/name)     
  fi
    
  INTERFACE3=''
  if [ -f /etc/cluster/nodes/this/networks/ipnb/primary/interface/name ]; then
    INTERFACE3=$(</etc/cluster/nodes/this/networks/ipnb/primary/interface/name)
  fi

  # Check if movable IPs on INTERFACE2 and INTERFACE3 are enabled (in this case
  # we are on active side)
  if ip addr show $INTERFACE2 secondary | grep -q inet && ip addr show $INTERFACE3 secondary | grep -q inet; then
    if [[ "$HW_TYPE" == 'VM' ]]; then
			# In case of VMware, DHCP on APG should be turned 'ON'
			# In case of ECS, DHCP on APG should be turned 'OFF'
      if isDHCP_ON; then
        if ! /bin/bash -c "/usr/sbin/dhcpd -q $INTERFACE $INTERFACE2 $INTERFACE3"; then
          apos_abort "Failed to start DHCP daemon"
        fi
			fi	
    elif [ $(find /dev/shm/ -name 'apos_snrinit.cache*' | wc -l) -ge 1 ]; then 
      if ! /bin/bash -c "/usr/sbin/dhcpd -q $INTERFACE2 $INTERFACE3 $INTERFACE"; then
        apos_abort "Failed to start DHCP daemon"
      fi
    else
      if ! /bin/bash -c "/usr/sbin/dhcpd -q $INTERFACE2 $INTERFACE3"; then
        apos_abort "Failed to start DHCP daemon"
      fi
    fi 						
  fi
else
	#Check if a snrinit in ongoing. If yes start the DHCP service on bond0 interface
	if [ $(find /dev/shm/ -name 'apos_snrinit.cache*' | wc -l) -ge 1 ]; then
		INTERFACE=''
		if [ -f /etc/cluster/nodes/this/networks/internal/primary/interface/name ]; then
			INTERFACE=$(</etc/cluster/nodes/this/networks/internal/primary/interface/name)
		fi
		if ! /bin/bash -c "/usr/sbin/dhcpd -q $INTERFACE"; then
			apos_abort "Failed to start DHCP daemon"
		fi
	fi
fi

apos_outro $0
exit $TRUE
