#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_update_rp_ssh_key.sh
# Description:
#       A script to update the default ssh keys for RP-VM.
#       This script is applicable only for vBSC.
# Note:
#       None.
##
# Usage:
#       apos_update_rp_ssh_key.sh
##
# Output:
#       None.
##
# Changelog:
# - Fri Jul 16 2021 - Anjali M  (xanjali)
#       First version.
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

# Common variables
CMD_CP='/usr/bin/cp'
CMD_MKDIR='/usr/bin/mkdir'
DEFAULT_PRIVATE_SSH_KEY_PSO='/storage/system/config/apos/ssh_keys'
KEYS_SRC_DIR='/opt/ap/apos/etc/deploy/default_rp_key'
KEYS_FILE='ssh_key_rp'
DST_FILE_NAME='id_rsa'
TS_USER_HOME_PATH='/var/home/ts_users/.ssh'

function handle_ssh_keys() {

  # Copy default RP-VM keys to default folder in PSO path
  # i.e., /storage/system/config/apos/default_private_ssh_key
  # In installation scenario, id_rsa file is copied from 
  # /opt/ap/apos/etc/deploy/default_rp_key folder to $DEFAULT_PRIVATE_SSH_KEY_PSO
  # In Restore scenario, if id_rsa, id_rsa.pub files are supposed to present
  # on node, In their absence, /opt/ap/apos/etc/deploy/default_rp_key/id_rsa is copied
  # to $DEFAULT_PRIVATE_SSH_KEY_PSO folder

  if [[ -f $DEFAULT_PRIVATE_SSH_KEY_PSO/id_rsa && -f $DEFAULT_PRIVATE_SSH_KEY_PSO/id_rsa.pub ]];then
     # Restore scenario
     apos_log "Nothing to do, as id_rsa file already exists in $TS_USER_HOME_PATH"
  else
     # Installation scenario
     if [ ! -d $DEFAULT_PRIVATE_SSH_KEY_PSO ];then
        $CMD_MKDIR -p $DEFAULT_PRIVATE_SSH_KEY_PSO
        [ $? -ne 0 ] && apos_abort "Failed to create the directory $DEFAULT_PRIVATE_SSH_KEY_PSO"
     fi

     install -m 640 -D $KEYS_SRC_DIR/$KEYS_FILE $DEFAULT_PRIVATE_SSH_KEY_PSO/$DST_FILE_NAME
     [ $? -ne 0 ] && apos_log " Copy of default ssh keys to $DEFAULT_PRIVATE_SSH_KEY_PSO failed"
     apos_log "INFO: Copied the default ssh keys to $DEFAULT_PRIVATE_SSH_KEY_PSO folder"
  fi

}


# _____________________
#|    _ _   _  .  _    |
#|   | ) ) (_| | | )   |
#|_____________________|
# Here begins the "main" function...

apos_intro $0
  
# copy the keys to ts_users and PSO path
handle_ssh_keys

apos_outro $0

exit $TRUE

# END

