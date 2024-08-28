#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      optimized_lde_brf_backup_folder.sh
# Description:
#       This script is to create folder used by optimaized lde-brf backup functionality
#       during Upgrade 
#
##
# Changelog:
# - Wed 07 July 2021 - Sowjanya GVL (xsowgvl)
#      Creating folder /var/log/lde-backup to be used by  optimized lde-brf backup functionality
#       First version.

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh 

OPTIMIZED_BACKUP_FOLDER='/var/log/lde-backup'
if  [ ! -d $OPTIMIZED_BACKUP_FOLDER ];  then
  apos_log 'lde-backup folder not present .. creating it'
  mkdir $OPTIMIZED_BACKUP_FOLDER &>/dev/null || apos_abort "lde-backup folder creation failed!!"
else
  apos_log 'lde-backup folder exists!!'
fi

exit $TRUE


