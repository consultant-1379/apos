#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_storage_attribute.sh
# Description:
#      This script will creates compute resource objects, if objects are
#      not created
# Note:
#
# Output:
#     None.
##
# Changelog:
#
# Wed Jun 30 2021 -Komal L (xkomala)
#       Added code to create system_type file 
# Mon Jul 1 2019 - Yeswanth Vankayala (xyesvan)
#       First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

STORAGE_PATH=$(apos_create_brf_folder config)
APT_TYPE="$STORAGE_PATH/apt_type"
SYS_TYPE="$STORAGE_PATH/system_type"
MI_PATH="/cluster/mi/installation"

apos_intro $0

value=$(immlist axeFunctionsId=1 | grep axeApplication | awk -F ' ' '{print $3}')
[ $value -eq '0' ] && apt_type=MSC
[ $value -eq '1' ] && apt_type=HLR
[ $value -eq '2' ] && apt_type=BSC
[ $value -eq '3' ] && apt_type=WIRELINE
[ $value -eq '4' ] && apt_type=TSC
[ $value -eq '5' ] && apt_type=IPSTP

echo $apt_type > $APT_TYPE


if [ ! -f $SYS_TYPE ]; then
    apos_log "$SYS_TYPE file is not present.Trying to create it"
    sys_value=$(kill_after_try 3 1 2 immlist -a systemType axeFunctionsId=1 | awk -F'=' '{print $2}')
    if [ "$sys_value" == "0" ]; then
        sys_type="SCP"
        echo $sys_type > $SYS_TYPE
        apos_log "Created $SYS_TYPE file with value SCP"
    elif [ "$sys_value" == "1" ]; then
        sys_type="MCP"
        echo $sys_type > $SYS_TYPE
        apos_log "Created $SYS_TYPE file with value MCP"
    elif [ -z "$sys_value" ]; then
        sys_type=$( cat $MI_PATH/system_type)
        if [ ! -z "$sys_type" ]; then
           echo $sys_type > $SYS_TYPE
           apos_log "Created $SYS_TYPE file with value $sys_type from $MI_PATH/system_type file"
        fi
    fi
fi

apos_outro $0

exit 0
