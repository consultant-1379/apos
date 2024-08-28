#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   user_data.sh
# Description:
#   A script to fetch all the VM configuration parameters in Openstack environment.
#   The configuration parameters are retrieved using the CD-ROM device available.
#   Such CD-ROM will contain a file named 'user_data' with all the needed info.
#   The data is saved in a cache file with the following format:
#     UUID:<uuid>
#     PROPERTIES:<property_name>=<property_value>
#     ... ... ...
#     NETINFO:<internal_name>;<network_name>;<interface>;<mac_address>
#     ... ... ...
##
# Changelog:
# - Tue 18 2018 - Bavana Harika(XHARBAV)/Pranshu Sinha (XPRANSI)
#     First version.
##

### BEGIN: Common variables
GETINFO_LIB_FOLDER='/opt/ap/apos/bin/gi/lib'
OPENSTACK_USERDATA_FILE=''
OPENSTACK_USERDATA_UPDATED_FILE=''
OPENSTACK_USERDATA_PARSE_SCRIPT="$GETINFO_LIB_FOLDER/fetch_method/parse_openstack_userdata.py"
PARSING_FAILURE_PATH='/boot'
PARSING_FAILURE_LOG_FILE='parser_failure_log'
FILE_PERMISSIONS="644"

# Source of the common_functions file to get common variables
. "$GETINFO_LIB_FOLDER/common/common_functions"
[ $? -ne 0 ] && apos_abort 'Failed to import the common_functions file!'

function create_user_data_updated_file(){
  local OPENSTACK_USERDATA_UPDATED_FILE="$1"
  if [ -e "$OPENSTACK_USERDATA_UPDATED_FILE" ];then
    $CMD_RM -f "$OPENSTACK_USERDATA_UPDATED_FILE"
    if [ $? -ne 0 ];then
      apos_abort "Failure while removing cache file $OPENSTACK_USERDATA_UPDATED_FILE"
    fi
  fi
  $CMD_TOUCH $OPENSTACK_USERDATA_UPDATED_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failure while creating cache file $OPENSTACK_USERDATA_UPDATED_FILE"
  fi
  $CMD_CHMOD $FILE_PERMISSIONS $OPENSTACK_USERDATA_UPDATED_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failure while changing permission to cache file $OPENSTACK_USERDATA_UPDATED_FILE"
  fi
}

function write_item_to_user_data_updated_file(){
  local KEY="$1"
  local OPENSTACK_USERDATA_UPDATED_FILE="$2"
  if [ -z $KEY ];then
    apos_abort "Invalid usage of function write_item_to_userdata_file"
  fi
  $CMD_ECHO "$KEY" >> $OPENSTACK_USERDATA_UPDATED_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failure while writing to $OPENSTACK_USERDATA_UPDATED_FILE"
  fi
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

# Invoke the Python script used to parse the user_data file content
OPENSTACK_USERDATA_FILE="$1"
STORAGE_API='/usr/share/pso/storage-paths/config'
PSO_PATH=$(<$STORAGE_API)
APOS_PSO="$PSO_PATH/apos/"
NODE_ID=$($CMD_CAT /etc/cluster/nodes/this/id)

OPENSTACK_USERDATA_UPDATED_FILE="$APOS_PSO"'user_data_updated_'"$NODE_ID"
PARSING_OUTPUT=$($OPENSTACK_USERDATA_PARSE_SCRIPT $OPENSTACK_USERDATA_FILE)
if [ $? -ne 0 ];then
  echo "Parsing failed. Error message: '$PARSING_OUTPUT'" > $PARSING_FAILURE_PATH/$PARSING_FAILURE_LOG_FILE
  apos_abort "Parsing failed. Error message: '$PARSING_OUTPUT'"
fi

# In case no error was found, the parsing output stores the list of items to be added 
# into the user_data_updated_<1/2> file under apos PSO path. First, create the updated file and then add each item to the file.
create_user_data_updated_file $OPENSTACK_USERDATA_UPDATED_FILE
for ITEM in $PARSING_OUTPUT
do
  write_item_to_user_data_updated_file $ITEM $OPENSTACK_USERDATA_UPDATED_FILE
done

$CMD_CAT $OPENSTACK_USERDATA_UPDATED_FILE
  
if [ $? -ne 0 ];then
  apos_abort "Failure while reading information from updated user data file"
fi
apos_outro $0

# End of file

