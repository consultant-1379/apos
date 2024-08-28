#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   vmtools.sh
# Description:
#   A script to fetch all the VM configuration parameters in VMware environment.
#   The configuration parameters are retrieved performing a query towards the
#   VMware Tools daemon running on the VM.
#   The data is saved in a cache file with the following format:
#     UUID:<uuid>
#     PROPERTIES:<property_name>=<property_value>
#     ... ... ...
#     NETINFO:<internal_name>;<network_name>;<interface>;<mac_address>
#     ... ... ...
##
# Changelog:
# - Fri 11 2016 - Alessio Cascone (ealocae)
#     First version.
##

### BEGIN: Common variables
GETINFO_LIB_FOLDER='/opt/ap/apos/bin/gi/lib'
SCRIPT_NAME=$(basename $0)
TEMP_FILE=''
VMWARE_OVFENV_PARSE_SCRIPT="$GETINFO_LIB_FOLDER/fetch_method/parse_vmware_ovfenv.py"
VMWARE_TOOLS_COMMAND="/usr/bin/vmtoolsd --cmd"
VMWARE_TOOLS_QUERY="info-get guestinfo.ovfenv"
###   END: Common variables

# Source of the common_functions file to get common variables
. "$GETINFO_LIB_FOLDER/common/common_functions"
[ $? -ne 0 ] && apos_abort 'Failed to import the common_functions file!'

function cleanup() {
  # Remove the previously created temporary file
  $CMD_RM -f $TEMP_FILE
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
  # Create a temporary file to store the output provided by VMware Tools 
  apos_log 'Cache not available, retrieving all the needed data!'
  TEMP_FILE=$($CMD_MKTEMP -t ${SCRIPT_NAME}.XXXXXX)

  # Query the VMware Tools daemon to get all the needed information.
  # Save then the output in the temporary file.
  $VMWARE_TOOLS_COMMAND "$VMWARE_TOOLS_QUERY"&> $TEMP_FILE
  [ $? -ne 0 ] && apos_abort "Failed to execute the command '$VMWARE_TOOLS_COMMAND'!"

  # Check that the query towards VMware Tools daemon produced some output
  [ ! -s "$TEMP_FILE" ] && apos_abort "Empty output produced by the command '$VMWARE_TOOLS_COMMAND'!"

  # Invoke the Python script used to parse the VMware Tools query output
  PARSING_OUTPUT=$($VMWARE_OVFENV_PARSE_SCRIPT $TEMP_FILE)
  [ $? -ne 0 ] && apos_abort "Parsing failed. Error message: '$PARSING_OUTPUT'"

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

