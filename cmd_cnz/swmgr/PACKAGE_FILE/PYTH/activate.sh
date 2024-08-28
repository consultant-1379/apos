#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      activate.sh
# Description:
#       A driver script to invoke all the patch software provided. 
# Note:
# None.
##
# Changelog:
# - Mon Apr 23 2018 - Malangsha Shaik (XMALSHA)
#   First version.

log(){
  /bin/logger -t 'swmgr.activate.driver' "$@"  
}

SCRIPTS_DIR=$( pwd)
SCRIPTS_ARRAY=(
                "example_1.sh"
                "example_2.sh"
                "example_3.sh"
               )

function main(){
  # place holder to invoke multiple scripts from here
  pushd "$SCRIPTS_DIR" >/dev/null

  local rCode=0 
  log "activate started."
  local MESSAGE=''

  for SCRIPT in ${SCRIPTS_ARRAY[@]}
  do
    MESSAGE="Executing $SCRIPT..."
    log "$MESSAGE"
    ./$SCRIPT &>/dev/null
    rCode=$?
    if [ $rCode -ne 0 ]; then
      log "$MESSAGE failed, error code:[$rCode]"
      return $rCode
    fi
    log "$MESSAGE success"

    # uncomment the sleep if any background activities 
    # of the script are still in progress, and require 
    # to be waited before launching the next script.
    # sleep 3
  done 

  log "activate completed."
  popd >/dev/null

  return $rCode
}

# _____________________ _____________________
#|    _ _   _  .  _    |    _ _   _  .  _    |
#|   | ) ) (_| | | )   |   | ) ) (_| | | )   |
#|_____________________|_____________________|
# Here begins the "main" function...

main

exit $?

