#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       swm_version.sh
# Description:
#       A script to create swm_version file
#
# Note:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Thu Nov 11 22018 - Yeswanth Vankayala (xyesvan)
#     Updated case condition for delete action
# - Tue Jun 26 2018 - zbhegna
#       First version.
##
# Load the apos common functions.

STORAGE_PATH_APOS="/storage/system/config/apos"
SWM_VERSION=$STORAGE_PATH_APOS/swm_version

function create_swm_version_file(){
if [ -f $SWM_VERSION ];then
  echo "swm_version exist in $STORAGE_PATH_APOS .. File Already Exists"
else
  echo -n "2" > $SWM_VERSION
  echo "swm_version does not exist in $STORAGE_PATH_APOS .. Creating file"
fi
}

function delete_swm_version_file(){
if [ -f $SWM_VERSION ];then
  echo "swm_version exist in $STORAGE_PATH_APOS .. Deleting file"
  rm -f $SWM_VERSION
else
	echo "swm_version does not exist in $STORAGE_PATH_APOS .. Skipping Removal"
fi

}

#### M A I N #####

if [ "$1" == "create" ];then
	create_swm_version_file
elif [ "$1" == "delete" ];then
	delete_swm_version_file
else
  echo "invalid argument"
fi

exit $TRUE

