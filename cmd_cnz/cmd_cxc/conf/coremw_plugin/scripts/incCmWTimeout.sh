#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       incCbaTimeout.sh
# Description:
#       A script to perform post installation activities on node SC-2-1.
# Note:
#       This script is executed as a post activity during the 
#       installation of COM with Automatic Installation Tool (AIT).
##
# Usage:
#       Used during vAPG maiden installation.
##
# Output:
#       None.
##
# Changelog:
# - Wed Sep 02 2020 - Pratap Reddy (XPRAUPP)
#   Setting timeout value to MAX value(i.e. 60 mins) 
# - Fri Apr 12 2019 - Swapnika Baradi (XSWAPBA)
#   First version.


function abort(){
  local ERROR_STRING=""

  if [ "$1" ]; then
    ERROR_STRING="ERROR: $1"
    echo "$ERROR_STRING"
  fi
  echo "ABORTING..."
  echo ""
  exit 1
}


# common variables
CMD_ECHO='/bin/echo'

$CMD_ECHO "$0"

### M A I N ###
main() {
  $CMD_ECHO "--- main() begin"
  
  #Increase the CMW timeout value for script execution from 10 mins to 60 mins
  cmw-utility immcfg -a smfCliTimeout=3600000000000 smfConfig=1,safApp=safSmfService
  if [ $? -ne 0 ]; then
    abort "Failed to increase timeout to 60 mins"
  fi 

  $CMD_ECHO "--- main() end"
}


$CMD_ECHO "##Increase timeout value to 60 mins done succesfull#"

main "@"

exit 0
