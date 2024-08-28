#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   ovfenv.sh
# Description:
#   A script to fetch all the VM configuration parameters in VMware environment.
#   The configuration parameters are retrieved using the CD-ROM device available.
#   Such CD-ROM will contain a file named 'ovf-env.xml' with all the needed info.
#   The data is saved in a cache file with the following format:
#     UUID:<uuid>
#     PROPERTIES:<property_name>=<property_value>
#     ... ... ...
#     NETINFO:<internal_name>;<network_name>;<interface>;<mac_address>
#     ... ... ...
##
# Changelog:
# - Thu Mar 1 2018 - Anjali (xanjali)
#     Updated the script to redirect failure messages
#     to a file in boot folder while parsing ovf-env.xml 
# - Fri 11 2016 - Alessio Cascone (ealocae)
#     First version.
##

### BEGIN: Common variables
GETINFO_LIB_FOLDER='/opt/ap/apos/bin/gi/lib'
SCRIPT_NAME=$(basename $0)
TEMP_FILE=''
VMWARE_OVFENV_FILE='ovf-env.xml'
VMWARE_OVFENV_MOUNT_FOLDER='/mnt/ovf-env'
VMWARE_OVFENV_PARSE_SCRIPT="$GETINFO_LIB_FOLDER/fetch_method/parse_vmware_ovfenv.py"
PARSING_FAILURE_PATH='/boot'
PARSING_FAILURE_LOG_FILE='parser_failure_log'
###   END: Common variables

# Source of the common_functions file to get common variables
. "$GETINFO_LIB_FOLDER/common/common_functions"
[ $? -ne 0 ] && apos_abort 'Failed to import the common_functions file!'

function cleanup() {
  # Remove the previously created temporary file
  $CMD_RM -f $TEMP_FILE
}

function copy_data_from_cdrom_to_temp_file() {
  # First, mount the CD-ROM storing the needed data
  mount_cdrom_by_content $VMWARE_OVFENV_MOUNT_FOLDER $VMWARE_OVFENV_FILE

  # Copy the data from the ovf-env.xml file to the temporary file
  $CMD_CP $VMWARE_OVFENV_MOUNT_FOLDER/$VMWARE_OVFENV_FILE $TEMP_FILE
  [ ! -s "$TEMP_FILE" ] && apos_abort 'No content available into temporary file!'
  
  # After extracting all the needed data, umount the CD-ROM
  umount_cdrom $VMWARE_OVFENV_MOUNT_FOLDER
}

#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|

apos_intro $0

# Exit with error in case of unset variables
set -u

# Register an handler for the cleanup operations
trap cleanup EXIT

# Validate the cache file and check if it is available.
# In case it is available, return its data.
validate_cache_file
if [ -s "$GETINFO_CACHE_FILE" ];then
  $CMD_CAT $GETINFO_CACHE_FILE
  [ $? -ne 0 ] && apos_abort 'Failure while reading information from cache file'
else
  # Create a temporary file to store the ovf-env.xml file content
  apos_log 'Cache not available, retrieving all the needed data!'
  TEMP_FILE=$($CMD_MKTEMP -t ${SCRIPT_NAME}.XXXXXX)

  # Extract all the needed information from the CD-ROM device, copying it to the temp file.
  copy_data_from_cdrom_to_temp_file

  # Invoke the Python script used to parse the ovf-env.xml file content
  PARSING_OUTPUT=$($VMWARE_OVFENV_PARSE_SCRIPT $TEMP_FILE)
  if [ $? -ne 0 ];then
     echo "Parsing failed. Error message: '$PARSING_OUTPUT'" > $PARSING_FAILURE_PATH/$PARSING_FAILURE_LOG_FILE
     apos_abort "Parsing failed. Error message: '$PARSING_OUTPUT'"
  fi

  # In case no error was found, the parsing output stores the list of items to be added 
  # into the cache. First, create the cache file and then add each item to the cache file.
  create_cache_file
  for ITEM in $PARSING_OUTPUT
  do
    ITEM_TYPE=$($CMD_ECHO $ITEM | $CMD_CUT -d':' -f1)
    ITEM_VALUE=$($CMD_ECHO $ITEM | $CMD_CUT -d':' -f2-)
    write_item_to_cache_file $ITEM_TYPE $ITEM_VALUE
  done

  $CMD_CAT $GETINFO_CACHE_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failure while reading information from cache file"
  fi
fi

apos_outro $0

# End of file

