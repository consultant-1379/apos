#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2024 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   apz_cloud_init.sh 
# Description:
#   A script to execute all the needed configurations during 
#   the CP booting phase in virtualized environment. 
##
# Changelog:
# - Wed Jan 01 2024 - Rajeshwari Padavala (xcsrpad)
#       Enhancing debug logging for tiny core
# - Thu Mar 26 2019 - Swapnika Baradi (xswapba)
#       correcting the netconf request loops
# - Fri Mar 02 2018 - Raghavendra Koduri (xkodrag)
#       Detection of hardware for Red hat openstack platform
# - Thu Jan 23 2018 - Paolo Palmieri (epaopal)
#     CR_ROLE implementation
# - Thu Jan 12 2017 - Antonio Buonocunto (eanbuon)
#     Dynamic MAC address handling and rework
# - Fri Nov 04 2016 - Alessio Cascone (ealocae) & Maurizio Cecconi (teimcec)
#     Completely reworked to handle also CP booting in VMware environment.
# - Fri Mar 04 2016 - Claudio Elefante (xclaele)
#     First version.
##

# Sourcing common library
if [ -e /usr/local/tce.installed/apz_cloud_common.sh ]; then
  . /usr/local/tce.installed/apz_cloud_common.sh
else
  echo "ERROR: Failure while sourcing apz_cloud_common.sh"
  sudo reboot  
fi

#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|

#If vendor id is other than vmware/openstack then by default we update it as openstack.
#This requirment is to support vAPG on RedHat Openstack environment
case $VENDOR_ID in
  *vmware*)
    log "Hypervisor type $VENDOR_ID detected"
  ;;
  
  *openstack*)
    log "Hypervisor type $VENDOR_ID detected"
  ;;
  
  *)  
    log "Hypervisor type ( $VENDOR_ID ) other than openstack or vmware detected,so setting  VENDOR_ID to openstack by default"
    VENDOR_ID="openstack"
  ;;
esac

# Get parameters according to supported infrastructures
case $VENDOR_ID in
  *vmware*)
    $APZ_CLOUD_SCRIPTS_FOLDER/apz_cloud_get_parameter_vmware.sh
    [ $? -eq 0 ] || abort 'Failed to get parameters in VMware.'
  ;;
  
  *openstack*)
    $APZ_CLOUD_SCRIPTS_FOLDER/apz_cloud_get_parameter_openstack.sh
    [ $? -eq 0 ] || abort 'Failed to get parameters in OpenStack.'
  ;;
  
  *)
    abort 'Unsupported vendor ID found.'
  ;;
esac

# Fetch parameters stored in properties
UUID="$(getProperty UUID)"
CR_TYPE="$(getProperty CR_TYPE)"
CR_ROLE="$(getProperty CR_ROLE)"
NETCONF_SERVER="$(getProperty NETCONF_SERVER)"
NETCONF_PORT="$(getProperty NETCONF_PORT)"
IPNA_MAC="$(getProperty IPNA_MAC)"
IPNB_MAC="$(getProperty IPNB_MAC)"

# Sanity checks on the environment variables
if [[ -z "$UUID" ]]; then
  abort "Undefined UUID identifier."
fi
if [[ -z "$CR_TYPE" ]]; then
  abort "Undefined compute resource type."
fi
if [[ -z "$CR_ROLE" ]]; then
  log "Undefined compute resource role."
#else
#  # Remove the dash, if present
#  CR_ROLE="$(echo $CR_ROLE | sed -e 's@-@@g')"
fi
if [[ -z "$NETCONF_SERVER" ]]; then
  abort 'Undefined NETCONF server address.'
fi
if [[ -z "$NETCONF_PORT" ]]; then
  abort "Undefined NETCONF server port."
fi
if [[ -z "$IPNA_MAC" ]]; then
  abort "Undefined IPN_A MAC address."
else
  # Convert IPNA_MAC to upper case
  IPNA_MAC="$(echo $IPNA_MAC | tr [:lower:] [:upper:])"
fi
if [[ -z "$IPNB_MAC" ]]; then
  abort "Undefined IPN_B MAC address."
else
  # Convert IPNB_MAC to upper case
  IPNB_MAC="$(echo $IPNB_MAC | tr [:lower:] [:upper:])"
fi

# Wait a while all the devices are up and running 
/sbin/udevadm settle --timeout=5

# Extract the information about the NICs used for the CP-AP communication
for i in $(ls -d /sys/class/net/eth*)
do
  VNIC=$(basename $i)
  MAC=$(cat $i/address | tr [:lower:] [:upper:])

  if [[ "$MAC" == "$IPNA_MAC" ]]; then
    IPNA_NIC=$VNIC
  elif [[ "$MAC" == "$IPNB_MAC" ]]; then
    IPNB_NIC=$VNIC
  fi
done

# In case one of the NICs is not found, log and abort
if [ -z "$IPNA_NIC" ] || [ -z "$IPNB_NIC" ]; then
  abort "Could not find IPN_A and IPN_B interfaces."
fi

# Ask the DHCP server for an IP address for the APZ-A interface 
/sbin/udhcpc -b -i $IPNA_NIC -A 1
if [ $? -ne 0 ]; then
  abort "Failure during udhcpc execution for IPN_A."
fi

# Ask the DHCP server for an IP address for the APZ-B interface 
/sbin/udhcpc -b -i $IPNB_NIC -A 1
if [ $? -ne 0 ]; then
  abort "Failure during udhcpc execution for IPN_B."
fi

# Extract the assigned IP addresses for APZ-A and APZ-B interfaces
IPNA_IP="$(/sbin/ifconfig $IPNA_NIC | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' | xargs )"
IPNB_IP="$(/sbin/ifconfig $IPNB_NIC | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' | xargs )"

# Sanity checks on the environment variables
if [ -z $IPNA_IP ]; then
  abort "Failure while fetching IPN_A IP address."
fi
if [ -z $IPNB_IP ]; then
  abort "Failure while fetching IPN_B IP address."
fi

# Set properties
setProperty "IPNA_IP" "$IPNA_IP"
setProperty "IPNB_IP" "$IPNB_IP"

# Create a folder to extract NETCONF_TRANSACTION_BUILDER_NAME
mkdir -p "$APZ_SMART_IMAGE_FOLDER"
if [ $? -ne 0 ]; then
  abort "Failure while creating folder for NETCONF transaction builder."
fi

# Fetch the managed element ID
MEID="$(sudo $APZ_CLOUD_SCRIPTS_FOLDER/sinetcc -s $NETCONF_SERVER -p $NETCONF_PORT -m -d 1)"
if [ $? -ne 0 ]; then
  abort "Failure while executing sinetcc in order to fetch managed element ID."
fi

# Extract the managed element ID
MEID="$(echo $MEID | awk -F':' '{print $2}')"

# Set MEID property
setProperty "MEID" "$MEID"

# Download the files required for the creation of the NETCONF transaction from the APG TFTP area
tftp -l $APZ_SMART_IMAGE_FOLDER/$APZ_CLOUD_PARAMETER_FILE -r $APZ_CLOUD_TFTP_SMARTIMAGE_FOLDER/$APZ_CLOUD_PARAMETER_FILE -g $NETCONF_SERVER
if [ $? -ne 0 ]; then
  abort "Download of $APZ_CLOUD_PARAMETER_FILE failed."
fi

# Download the files required for the creation of the NETCONF transaction from the APG TFTP area
tftp -l $APZ_SMART_IMAGE_FOLDER/$APZ_SMART_IMAGE_LIST -r $APZ_CLOUD_TFTP_SMARTIMAGE_CONTENT_FOLDER/$APZ_SMART_IMAGE_LIST -g $NETCONF_SERVER
if [ $? -ne 0 ]; then
  abort "Download of $APZ_SMART_IMAGE_LIST failed."
fi

# Download the files required for the creation of the NETCONF transaction from the APG TFTP area
tftp -l $APZ_SMART_IMAGE_FOLDER/$APZ_SMART_IMAGE_EXEC_FILE -r $APZ_CLOUD_TFTP_SMARTIMAGE_CONTENT_FOLDER/$APZ_SMART_IMAGE_EXEC_FILE -g $NETCONF_SERVER
if [ $? -ne 0 ]; then
  abort "Download of $APZ_SMART_IMAGE_EXEC_FILE failed."
fi
chmod +x $APZ_SMART_IMAGE_FOLDER/$APZ_SMART_IMAGE_EXEC_FILE
if [ $? -ne 0 ]; then
  log "Failure while changing permission on $APZ_SMART_IMAGE_EXEC_FILE file."
fi

# Download file specified in APZ_SMART_IMAGE_LIST
downloadFilesInList "$APZ_SMART_IMAGE_FOLDER/$APZ_SMART_IMAGE_LIST"

# Execute APZ SMART IMAGE EXEC script
$APZ_SMART_IMAGE_FOLDER/$APZ_SMART_IMAGE_EXEC_FILE
if [ $? -ne 0 ]; then
  abort "Execution of $APZ_SMART_IMAGE_EXEC_FILE failed."
fi

# Create on the APG, under CrMgmt the MO with the extracted information  
sudo $APZ_CLOUD_SCRIPTS_FOLDER/sinetcc -s $NETCONF_SERVER -p $NETCONF_PORT -f $APZ_SMART_IMAGE_FOLDER/$APZ_SMART_IMAGE_TEMPLATE -d 1
NETCONF_RESULT=$?

if [ "$CR_TYPE" == "IPLB_TYPE" ]; then
   while [ $NETCONF_RESULT -ne 0 ]
   do
	sleep 10
	#APG will return NOT-OK to netconf requests when CR_TYPE is IPLB_TYPE and default IPLB SW is not loaded. 
	#Instead of rebooting vIPLB VM, retry netconf query until it receives OK response i.e. IPLB SW is loaded
	sudo $APZ_CLOUD_SCRIPTS_FOLDER/sinetcc -s $NETCONF_SERVER -p $NETCONF_PORT -f $APZ_SMART_IMAGE_FOLDER/$APZ_SMART_IMAGE_TEMPLATE -d 1
	NETCONF_RESULT=$?
   done
fi

if [ $NETCONF_RESULT -ne 0 ]; then
  abort "Failure while executing sinetcc in order to send info about new internal compute resource object."
fi
log_transfer1
# After a successful NETCONF operation execution, order a reboot
sudo reboot
exit 0

# End of file
