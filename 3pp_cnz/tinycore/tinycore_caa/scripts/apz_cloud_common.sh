#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2024 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   apz_cloud_common.sh
# Description:
#   A script to provide common function to apz_cloud scripts suite.
##
# Changelog:
# - Wed Jan 01 2024 - Rajeshwari Padavala (xcsrpad)
#     Enhancing debug logging for tiny core
# - Wed Feb 14 2018 - Maurizio Cecconi (teimcec)
#     changed log transfer removing timestamp in case CR_TYPE and 
#     UUID are already fetched. Log file name contains only
#     CR_TYPE and VM UUID, timestamp otherwise.
# - Wed Jan 31 2018 - Paolo Palmieri (epaopal)
#     Rework after code review
# - Thu Jan 23 2018 - Paolo Palmieri (epaopal)
#     CR_ROLE implementation
# - Wed Feb 22 2017 - Pranshu Sinha (xpransi)
#     New setNetInfo_withVNIC function is added
# - Thu Jan 11 2017 - Antonio Buonocunto (eanbuon)
#     First version.
##

DEBUG_ENABLED=1

### Common variables section - begin
APZ_CLOUD_SCRIPTS_FOLDER="/usr/local/tce.installed"
SYSTEM_VENDOR_ID_ROOT_PATH="/sys/devices/virtual/dmi/id"
SYSTEM_VENDOR_ID_CONF_FILE="$SYSTEM_VENDOR_ID_ROOT_PATH/sys_vendor"
APZ_SMART_IMAGE_FOLDER="/usr/local/tce.installed/si"
LOG_FILE_NAME="smartImage.log"
LOG_FILE_NAME1="smartImage1.log"
APZ_SMART_IMAGE_EXEC_FILE="apz_smart_image_exec.sh"
APZ_SMART_IMAGE_TEMPLATE="apz_smart_image_template.xml"
APZ_CLOUD_PROPERTIES_FILE="apz_cloud_properties"
APZ_CLOUD_NETINFO_FILE="apz_cloud_netinfo"
APZ_CLOUD_TFTP_SMARTIMAGE_FOLDER="./smartImage"
APZ_CLOUD_TFTP_SMARTIMAGE_CONTENT_FOLDER="$APZ_CLOUD_TFTP_SMARTIMAGE_FOLDER/si"
APZ_CLOUD_PARAMETER_FILE="apz_smart_image_parameter.cfg"
APZ_SMART_IMAGE_LIST="apz_smart_image_list.cfg"
### Common variables section - end

# First check that the file storing information about the VM vendor is available
if [ ! -r $SYSTEM_VENDOR_ID_CONF_FILE ]; then
  abort 'Vendor ID file not found.'
fi

# Convert vendor ID to lower case
VENDOR_ID=$(cat $SYSTEM_VENDOR_ID_CONF_FILE | tr [[:upper:]] [[:lower:]])
UUID="$(cat /sys/devices/virtual/dmi/id/product_uuid | tr [:upper:] [:lower:])"
# Function to log the provided error message into the log file and to the screen
# Usage: log <message_to_log>
function log() {
  local MSG="$*"
  local TIMESTAMP="$(date +%Y%m%d%H%M%S)"
  echo "$TIMESTAMP: $MSG" >> $APZ_CLOUD_SCRIPTS_FOLDER/$LOG_FILE_NAME
  echo "$TIMESTAMP: $MSG"
}
# Function to log the provided debug enabled error message into the log file and to the screen
# Usage: log_suc <message_to_log>
function log_suc() {
echo ""
if [ $DEBUG_ENABLED -eq 1 ]; then
  local MSG="$*"
  local TIMESTAMP="$(date +%Y%m%d%H%M%S)"
  echo "$TIMESTAMP: $MSG" >> $APZ_CLOUD_SCRIPTS_FOLDER/$LOG_FILE_NAME1
  echo "$TIMESTAMP: $MSG"
fi
}
# Function to transfer log on APG via trivial ftp
# Usage: log_transfer
function log_transfer() {
local CR_ROLE="$(getProperty CR_ROLE)"
  local TIMESTAMP="$(date +%Y%m%d%H%M%S)"
  CR_TYPE="$(getProperty CR_TYPE)"
  local UUID="$(getProperty UUID)"
  local CR_TYPE="$(getProperty CR_TYPE)"
  [ -z $NETCONF_SERVER ] && NETCONF_SERVER="$(getProperty NETCONF_SERVER)"
  if [ -n "$CR_ROLE" ]; then
   tftp -l "$APZ_CLOUD_SCRIPTS_FOLDER/$LOG_FILE_NAME1" -r "$APZ_CLOUD_TFTP_SMARTIMAGE_FOLDER/$LOG_FILE_NAME-$CR_ROLE" -p $NETCONF_SERVER
 else
   tftp -l "$APZ_CLOUD_SCRIPTS_FOLDER/$LOG_FILE_NAME1" -r "$APZ_CLOUD_TFTP_SMARTIMAGE_FOLDER/$LOG_FILE_NAME" -p $NETCONF_SERVER
 fi
}
# Function to transfer Debug enabled logs on APG via trivial ftp
# Usage: log_transfer1
function log_transfer1() {
echo ""
if [ $DEBUG_ENABLED -eq 1 ]; then
local CR_ROLE="$(getProperty CR_ROLE)"
  local TIMESTAMP="$(date +%Y%m%d%H%M%S)"
 NETCONF_SERVER="192.168.169.33"
 if [ -n "$CR_ROLE" ]; then
   tftp -l "$APZ_CLOUD_SCRIPTS_FOLDER/$LOG_FILE_NAME1" -r "$APZ_CLOUD_TFTP_SMARTIMAGE_FOLDER/$LOG_FILE_NAME1-$CR_ROLE" -p $NETCONF_SERVER
 else
   tftp -l "$APZ_CLOUD_SCRIPTS_FOLDER/$LOG_FILE_NAME1" -r "$APZ_CLOUD_TFTP_SMARTIMAGE_FOLDER/$LOG_FILE_NAME1" -p $NETCONF_SERVER
 fi
fi
}
# Function to print the provided error message and to order a reboot
# Usage: abort <message_to_log>
function abort() {
  log "$*"
  log_suc "$*"
  sleep 10
  log_transfer
  log_transfer1
  sudo reboot
  exit 1
}

# Function to save in a file the properties specified at deployment time
# Usage: setProperty <name> <value>
function setProperty() {
  local propertyName="$1"
  local propertyValue="$2"
   log_suc "set property $1=$2"
  # Sanity checks
  if [ -z "$propertyName" ] || [ -z "$propertyValue" ]; then
    abort "Invalid setProperty usage."
  fi

  local propertyCheck="$(getProperty $propertyName)"
  
  if [ -z "$propertyCheck" ]; then   
  echo "$propertyName=$propertyValue" >> $APZ_CLOUD_SCRIPTS_FOLDER/$APZ_CLOUD_PROPERTIES_FILE
  chmod 777 $APZ_CLOUD_SCRIPTS_FOLDER/$APZ_CLOUD_PROPERTIES_FILE
  fi
  
}

# Function to get a property specified at deployment time
# Usage: getProperty <name>
function getProperty() {
  local propertyName="$1"

  # Sanity checks
  if [ -z "$propertyName" ]; then
    abort "Invalid getProperty usage."
  fi

  local propertyValue="$(cat $APZ_CLOUD_SCRIPTS_FOLDER/$APZ_CLOUD_PROPERTIES_FILE | grep -E "^$propertyName=" | awk -F'=' '{print $2}')"
  
  echo $propertyValue
}

# Function to save in a file the network information
# Usage: setNetInfo <network_name> <MAC>
function setNetInfo() {
  local netInfoName="$1"
  local netInfoMAC="$2"

  # Sanity checks
  if [ -z "$netInfoName" ] || [ -z "$netInfoMAC" ]; then
    abort "Invalid usage of setNetInfo function."
  fi

  local netInfoCheck="$(getNetInfo $netInfoName)"
  if [ -z "$netInfoCheck" ]; then  
log_suc "set Netinfo $1=$2"
  echo "$netInfoName;$netInfoMAC" >> $APZ_CLOUD_SCRIPTS_FOLDER/$APZ_CLOUD_NETINFO_FILE
  chmod 777 $APZ_CLOUD_SCRIPTS_FOLDER/$APZ_CLOUD_NETINFO_FILE
  
  fi
}

# Function to save in a file the network information in case vendor is openstack
# Usage: setNetInfo_withVNIC <network_name> <MAC> <VNIC>
function setNetInfo_withVNIC() {
  local netInfoName="$1"
  local netInfoMAC="$2"
  local netInfoVNIC="$3"

  # Sanity checks
  if [ -z "$netInfoName" ] || [ -z "$netInfoMAC" ] || [ -z "$netInfoVNIC" ]; then
    abort "Invalid usage of setNetInfo_withVNIC function."
  fi

  local netInfoCheck="$(getNetInfo $netInfoName)"
  if [ -z "$netInfoCheck" ]; then
    
  echo "$netInfoName;$netInfoMAC;$netInfoVNIC" >> $APZ_CLOUD_SCRIPTS_FOLDER/$APZ_CLOUD_NETINFO_FILE
  chmod 777 $APZ_CLOUD_SCRIPTS_FOLDER/$APZ_CLOUD_NETINFO_FILE
  log_suc "set Netinfowith nic $1=$2=$3"
  fi
}

# Function to get information about a specific network
# Usage: getNetInfo <network_name>
function getNetInfo() {
  local netInfoName="$1"

  # Sanity checks
  if [ -z "$netInfoName" ]; then
    abort "Invalid getNetInfo usage."
  fi
  
  local netInfoResult="$(cat $APZ_CLOUD_SCRIPTS_FOLDER/$APZ_CLOUD_NETINFO_FILE | grep -E "^$netInfoName;")"
  echo $netInfoResult
}

# Function to get all network information
# Usage: getNetInfoAll
function getNetInfoAll() {
  cat $APZ_CLOUD_SCRIPTS_FOLDER/$APZ_CLOUD_NETINFO_FILE
}

# Function to download from APG all files reported in the file passed as input
# Usage: downloadFilesInList <listing_file>
function downloadFilesInList() {
  local fileList="$1"

  # Sanity checks
  if [ ! -e "$fileList" ]; then
    abort "Failure while accessing to download list file: $fileList"
  fi

  while read downloadItem; do
	downloadItemFileName="$(basename $downloadItem)"
    tftp -l $APZ_SMART_IMAGE_FOLDER/$downloadItemFileName -r $downloadItem -g $NETCONF_SERVER
	if [ $? -ne 0 ]; then
		abort "Download of $downloadItem failed."
	fi
	# Change permission of downloaded file
	chmod +x $APZ_SMART_IMAGE_FOLDER/$downloadItemFileName
	if [ $? -ne 0 ]; then
		abort "Failure while changing permission on $downloadItem"
	fi	
  done < $fileList
}

# Function to get a parameter passed by APG
# Usage: getParameter <parameter_name>
function getParameter() {
  local parameterName="$1"

  # Sanity checks
  if [ -z "$parameterName" ]; then
    abort "Invalid usage of getParameter function."
  fi

  local parameterValue="$(cat $APZ_SMART_IMAGE_FOLDER/$APZ_CLOUD_PARAMETER_FILE | grep -E "^$parameterName=" | awk -F'=' '{print $2}')"
  echo $parameterValue
}

# End of file
