#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   apz_cloud_get_parameter_openstack.sh 
# Description:
#   A script to extract all the needed configuration data from config drive
#   during CP booting phase in OpenStack environment.
##
# Changelog:
# - Wed Nov 3 2021 - P S SOUMYA (zpsxsou)
#     Improvements in fetching CR_Type, CR_Role & UUID to be future proof
# - Wed Jan 31 2018 - Paolo Palmieri (epaopal)
#     Rework after code review
# - Thu Jan 23 2018 - Paolo Palmieri (epaopal)
#     CR_ROLE implementation
# - Thu Jan 12 2017 - Antonio Buonocunto (eanbuon)
#     Rework
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
CONFIG_DRIVE_PATH="/mnt/config"
OPENSTACK_INFO="$CONFIG_DRIVE_PATH/openstack/latest/meta_data.json"
OPENSTACK_USER_DATA="$CONFIG_DRIVE_PATH/openstack/latest/user_data"
PRODUCT_UUID="/sys/devices/virtual/dmi/id/product_uuid"
# Extract the name of the device in which config drive ISO is available
CONFIG_DRIVE_DEVICE=$(blkid -t LABEL="config-2" -odevice)
if [ ! -z "$CONFIG_DRIVE_DEVICE" ]; then
  # Device found: create the mount point and mount it
  mkdir -p $CONFIG_DRIVE_PATH

  # Mount config drive
  mount $CONFIG_DRIVE_DEVICE $CONFIG_DRIVE_PATH
  if [ $? -ne 0 ]; then
    log "Failed to mount the config drive!"
	exit 1
  fi
else
  # Device not found
  log "Config drive device not found!"
  exit 1
fi

# Extract all the needed data from the files into the config drive

UUID="$(cat $PRODUCT_UUID | tr [:upper:] [:lower:])"
CR_TYPE=$(cat $OPENSTACK_INFO | awk -F'"cr_type":' '{print $2}'| awk -F',' '{print $1}' | sed -e 's@^[[:space:]]*@@g' -e 's@^{@@g' -e 's@[[:space:]]*$@@g' -e 's@}$@@g' -e 's@^"@@g' -e 's@"$@@g')
if [ -z "$CR_TYPE" ]; then
  log "Fetching cr_type from user_data"
  CR_TYPE=$(cat $OPENSTACK_USER_DATA | awk -F'cr_type=' '{print $2}' | xargs)

fi
CR_ROLE=$(cat $OPENSTACK_INFO | awk -F'"cr_role":' '{print $2}'| awk -F',' '{print $1}' | sed -e 's@^[[:space:]]*@@g' -e 's@^{@@g' -e 's@[[:space:]]*$@@g' -e 's@}$@@g' -e 's@^"@@g' -e 's@"$@@g')
if [ -z "$CR_ROLE" ]; then
   log "Entered into cr_role"
   CR_ROLE=$(cat $OPENSTACK_USER_DATA | awk -F'cr_role=' '{print $2}' | xargs)

fi

NETCONF_SERVER=$(cat $OPENSTACK_USER_DATA | awk -F'netconf_server=' '{print $2}' | xargs)
NETCONF_PORT=$(cat $OPENSTACK_USER_DATA | awk -F'netconf_port=' '{print $2}' | xargs)
IPNA_MAC=$(cat $OPENSTACK_USER_DATA | awk -F'ipna_mac=' '{print $2}' | awk '{print toupper($0)}' | xargs)
IPNB_MAC=$(cat $OPENSTACK_USER_DATA | awk -F'ipnb_mac=' '{print $2}' | awk '{print toupper($0)}' | xargs)

# Set properties
setProperty "UUID" "$UUID"
setProperty "CR_TYPE" "$CR_TYPE"
if [ "$CR_ROLE" ]; then
  setProperty "CR_ROLE" "$CR_ROLE"
fi
setProperty "NETCONF_SERVER" "$NETCONF_SERVER"
setProperty "NETCONF_PORT" "$NETCONF_PORT"
setProperty "IPNA_MAC" "$IPNA_MAC"
setProperty "IPNB_MAC" "$IPNB_MAC"

# Dismount config drive
umount $CONFIG_DRIVE_PATH
if [ $? -ne 0 ]; then
  log "WARNING: Failed to dismount the config drive!"
fi

# End of file
