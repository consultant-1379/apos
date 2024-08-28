#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      erase.sh
# Description:
#       A script to cleanup the node after applying the patch software
# Note:
# None.
##
# Changelog:
# - Tue Apr 16 2018 - Malangsha Shaik(XMALSHA)
# First version.

log(){
  /bin/logger -t swmgr.erase "$@"  
}

function main()
{
  log 'erase activities in progress!!'

  # do required activities
  sleep 1

  log 'erase activities completed!!'
}

# _____________________ _____________________
#|    _ _   _  .  _    |    _ _   _  .  _    |
#|   | ) ) (_| | | )   |   | ) ) (_| | | )   |
#|_____________________|_____________________|
# Here begins the "main" function...

main

exit 0
