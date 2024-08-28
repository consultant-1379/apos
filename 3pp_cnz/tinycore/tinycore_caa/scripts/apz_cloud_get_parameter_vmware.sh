#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2024 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   apz_cloud_get_parameter_vmware.sh_
# Description:
#   A script to extract all the needed configuration data from OVF 
#   environment file during CP booting phase in VMware environment.
##
# Changelog:
# - Wed Jan 01 2024 - Rajeshwari Padavala (xcsrpad)
#       Flexible naming convention for internal networks												   
# - Wed Jan 31 2018 - Paolo Palmieri (epaopal)
#     Rework after code review
# - Thu Jan 23 2018 - Paolo Palmieri (epaopal)
#     CR_ROLE implementation
# - Fri Dec 29 2017 - Anjali M (xanjali)
#     vCD Adaptations
# - Thu Mar 23 2017 - Yeswanth Vankayala (xyesvan)
#     Adaptations for BC VMs
# - Thu Jan 12 2017 - Antonio Buonocunto (eanbuon)
#     Dynamic MAC address handling and rework
# - Fri Nov 04 2016 - Alessio Cascone (ealocae) & Maurizio Cecconi (teimcec)
#     First version.
##

# Sourcing common library
if [ -e /usr/local/tce.installed/apz_cloud_common.sh ]; then
  . /usr/local/tce.installed/apz_cloud_common.sh
else
  echo "ERROR: Failure while sourcing apz_cloud_common.sh"
  sudo reboot  
fi

### Local variables
OVF_ENV_FILE_MOUNT_POINT='/mnt/config'
OVF_ENV_FILE_NAME='ovf-env.xml'
OVF_ENV_FILE_PATH="$OVF_ENV_FILE_MOUNT_POINT/$OVF_ENV_FILE_NAME"
OVF_ENV_FILE_DEVICE_LABEL="OVF ENV"
OVF_ENV_FILE_APZA_NIC_NAME='APZ-A'
OVF_ENV_FILE_APZB_NIC_NAME='APZ-B'
PORTGRPA="PORTGROUP_APZ-A"
PORTGRPB="PORTGROUP_APZ-B"
PORTGRP='PORTGROUP_APZ-A|PORTGROUP_APZ-B|PORTGROUP_UPD|PORTGROUP_UPD2|PORTGROUP_AXE-DEF|PORTGROUP_INT-SIG'

# Extract the name of the device in which the OVF environment file ISO is available
DEVICE_NAME=$(blkid -t LABEL="$OVF_ENV_FILE_DEVICE_LABEL" -o device)
if [ -z "$DEVICE_NAME" ]; then
  log "OVF environment file device not found!"
  exit 1
fi

# Device correctly found: create the mount point and mount it
mkdir -p $OVF_ENV_FILE_MOUNT_POINT
mount $DEVICE_NAME $OVF_ENV_FILE_MOUNT_POINT
if [ $? -ne 0 ]; then
  log "Failed to mount the OVF environment file device."
  exit 1
fi

# Create a temporary file to store the data extracted from the OVF environment file
TEMP_FILE=$(mktemp -t vmware.XXXXXX)
cat $OVF_ENV_FILE_PATH | sed -n -e '/<\/PlatformSection>/,/<\/ve:EthernetAdapterSection>/p' | sort -ru  > $TEMP_FILE
test="$(cat $OVF_ENV_FILE_PATH)"
log_suc " $test"

# Extract all the needed data from the OVF environment file
UUID="$(cat /sys/devices/virtual/dmi/id/product_uuid | tr [:upper:] [:lower:])"
CR_TYPE="$(grep 'oe:key="cr_type' $TEMP_FILE | awk -F'oe:value=' '{print $2}' | cut -d '"' -f2)"
CR_ROLE="$(grep 'oe:key="cr_role' $TEMP_FILE | awk -F'oe:value=' '{print $2}' | cut -d '"' -f2)"
NETCONF_SERVER="$(grep 'oe:key="netconf_server' $TEMP_FILE | awk -F'oe:value=' '{print $2}' | cut -d '"' -f2)"
NETCONF_PORT="$(grep 'oe:key="netconf_port' $TEMP_FILE | awk -F'oe:value=' '{print $2}' | cut -d '"' -f2)"
PORTGRPA_PRES=$(grep -w $PORTGRPA $TEMP_FILE | awk  '/oe:value/ {print}'|cut -d '"' -f4)
PORTGRPB_PRES=$(grep -w $PORTGRPB $TEMP_FILE | awk  '/oe:value/ {print}'|cut -d '"' -f4)
##Fetching macaddress using value of portgroup
if [[ -n "${PORTGRPA_PRES// /}" ]] || [[ -n "${PORTGRPB_PRES// /}" ]] ; then
count=0
declare -a myArray
myArray=(`(cat $TEMP_FILE |awk  '/ve:network/ {print}'|cut -d '"' -f4 | awk '{ print length(), $0 | "sort -nr"  }' | awk -F ' ' '{print $2}' )`)
arrcount=${#myArray[*]}
   for prop in $(cat  $TEMP_FILE  |grep "<Property" |  grep -E "PORTGROUP_*" |awk -F'oe:value=' '{print $2}' | cut -d '"' -f2 |  awk '{ print length(), $0 | "sort -nr" }'| awk -F ' ' '{print $2}'); do		
		for (( q=0; q < arrcount; q++)); do
		    PATTERN_MATCH=$(echo ${myArray[q]} | grep -F "$prop")
		    if    [ -n "$PATTERN_MATCH" ]; then
			    mac=$(grep -F ve:network=\"$PATTERN_MATCH\" $TEMP_FILE |awk  '/ve:mac/ {print}' |  cut -d '"' -f2)
                line_num=$(grep -Fn  oe:value=\"$prop\"  $TEMP_FILE | cut -d : -f 1)
                net=$(sed -n "${line_num}p"    $TEMP_FILE |  cut -d '"' -f2)
                sed -i "/$PATTERN_MATCH/d" $TEMP_FILE 2>/dev/null
			    unset myArray[$q]
		    if [[ "$net" == "PORTGROUP_APZ-A"  ]]; then
			    IPNA_MAC=$mac
			    count=$((count+1))
				break;
		    fi
		    if [[ "$net" == "PORTGROUP_APZ-B"  ]]; then
			    IPNB_MAC=$mac
			    count=$((count+1))
				break;
		    fi		    
		    fi
       done
	   if [ $count -eq 2 ]; then
            break;
       fi
done
else
IPNA_MAC="$(grep ".*${OVF_ENV_FILE_APZA_NIC_NAME}.*" $TEMP_FILE | awk -F've:mac=' '{print $2}' | cut -d '"' -f2)"
IPNB_MAC="$(grep ".*${OVF_ENV_FILE_APZB_NIC_NAME}.*" $TEMP_FILE | awk -F've:mac=' '{print $2}' | cut -d '"' -f2)"
fi
# In vmware the cr_role is mandatory for CP and IPLB VMs!
if [[ "$CR_TYPE" == "IPLB_TYPE" || "$CR_TYPE" == "CP_TYPE" ]]; then
  [ -z "$CR_ROLE" ] && abort "Failure while fetching CR Role"
fi

# Set Properties
setProperty "UUID" "$UUID"
setProperty "CR_TYPE" "$CR_TYPE"
if [ "$CR_ROLE" ]; then
  setProperty "CR_ROLE" "$CR_ROLE"
fi
setProperty "NETCONF_SERVER" "$NETCONF_SERVER"
setProperty "NETCONF_PORT" "$NETCONF_PORT"
setProperty "IPNA_MAC" "$IPNA_MAC"
setProperty "IPNB_MAC" "$IPNB_MAC"

# Remove the previously created temporary file
rm -f $TEMP_FILE
# Dismount the OVF environment file device
umount $OVF_ENV_FILE_MOUNT_POINT
if [ $? -ne 0 ]; then
  log "WARNING: Failed to dismount the OVF environment device!"
fi

# End of file
