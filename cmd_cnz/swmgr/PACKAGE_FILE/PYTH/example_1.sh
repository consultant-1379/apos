#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      acs_lct_swmfix.sh
# Description:
#       A script to create symbolic links during the upgrade.
# Note:
# None.
##
# Changelog:
# - Tue Feb 13 2018 - Yeswanth Vankayala (XYESVAN)
# First version.

CHOWN="/usr/bin/chown"
CMD_LN="/usr/bin/ln"
CHMOD="/usr/bin/chmod"

log(){
  /bin/logger -t swmgr.activate "$@"  
}

function create_swm_softlink(){
  local NAME="$1"
  local NBI_ROOT='/data/opt/ap/internal_root'
  local STORAGE_SOFTWARE_MGMT='/storage/no-backup/coremw/SoftwareManagement'
  local NBI_SOFTWARE_MGMT="$NBI_ROOT/$NAME"
  local USER_GROUP=$( echo $NBI_SOFTWARE_MGMT | awk -F ';' '{print $2}')
  local NBI_SOFTWARE_MGMT_FOLDER

  if [ -z "$USER_GROUP" ]; then
    NBI_SOFTWARE_MGMT_FOLDER=${NBI_SOFTWARE_MGMT%/*}
  else
    NBI_SOFTWARE_MGMT=$( echo $NBI_SOFTWARE_MGMT | awk -F ';' '{print $1}')
    NBI_SOFTWARE_MGMT_FOLDER=${NBI_SOFTWARE_MGMT%/*}
  fi

  if [ ! -d $NBI_SOFTWARE_MGMT_FOLDER ]; then
    log "creating folder: [$NBI_SOFTWARE_MGMT_FOLDER]"
    mkdir -p $NBI_SOFTWARE_MGMT_FOLDER

    if [[ "$NBI_SOFTWARE_MGMT_FOLDER" == "$NBI_ROOT" ]]; then
      ${CHMOD} 777 $NBI_SOFTWARE_MGMT_FOLDER
    elif [[ "$NBI_SOFTWARE_MGMT_FOLDER" =~ "$NBI_ROOT/sw_package" ]]; then
      ${CHMOD} 2775 $NBI_SOFTWARE_MGMT_FOLDER
      [ ! -z "$USER_GROUP" ] && ${CHOWN} -h "$USER_GROUP" $NBI_SOFTWARE_MGMT_FOLDER
    fi
  fi

  if [ ! -L $NBI_SOFTWARE_MGMT ];then
    if [ -d $NBI_SOFTWARE_MGMT ]; then
      log "$NBI_SOFTWARE_MGMT folder found.. skipping symbolic creation"
    else
      local PRINTOUT="creating symbolic link: $NBI_SOFTWARE_MGMT -> $STORAGE_SOFTWARE_MGMT..."
      log "$PRINTOUT"
      $CMD_LN -s $STORAGE_SOFTWARE_MGMT $NBI_SOFTWARE_MGMT &>/dev/null
      if [ $? -ne 0 ]; then
        log "$PRINTOUT failed"
      else
        log "$PRINTOUT success"
        if [ ! -z "$USER_GROUP" ]; then
          ${CHOWN} -h  "$USER_GROUP" $NBI_SOFTWARE_MGMT
        fi
      fi
    fi
  fi
}

function main(){
  local CONFIGAP_A='/tmp/configap_a'
  [ -f $CONFIGAP_A ] && rm -f $CONFIGAP_A
	
	# create nbi_root/softwaremanagement softlink if not exist
  create_swm_softlink 'SoftwareManagement;cmw-swm:cmw-swm'
 
  # create nbi_root/sw_package/APG softlink if not exist
  create_swm_softlink 'sw_package/APG;root:SWPKGGRP'
}

# _____________________ _____________________
#|    _ _   _  .  _    |    _ _   _  .  _    |
#|   | ) ) (_| | | )   |   | ) ) (_| | | )   |
#|_____________________|_____________________|
# Here begins the "main" function...

main

sleep 1

exit 0
