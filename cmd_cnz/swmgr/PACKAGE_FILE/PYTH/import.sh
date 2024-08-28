#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      import.sh
# Description:
#       A script to perform the import activities before applying the patch.
# Note:
# None.
##
# Changelog:
# - Tue Apr 16 2018 - Malangsha Shaik (XMALSHA)
# First version.

log(){
  /bin/logger -t swmgr.import "$@"  
}

function main()
{
  log 'import activities in progress!!'

  # do required activities
  sleep 1

  log 'import activities completed!!'
}

# _____________________ _____________________
#|    _ _   _  .  _    |    _ _   _  .  _    |
#|   | ) ) (_| | | )   |   | ) ) (_| | | )   |
#|_____________________|_____________________|
# Here begins the "main" function...

main

exit 0
