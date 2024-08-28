#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_copy_remove_rpms_script.sh
# Description:
#       A script to copy remove_rpms.sh script in old rpm.
# Note:
#       Invoked by apos_ext plugin on both the Nodes of APG.
##
# Usage:
#       Used during APG Upgrade.
# Output:
#       None.
##
# Changelog:
# - Thu Jul 9 2020 - Swapnika Baradi (XSWAPBA)
#   First version.

# If APG43L4.0 is used as base for further Upgrade paths, then this script has to be removed.
. /opt/ap/apos/conf/apos_common.sh
apos_intro $0

old_path=$(cmw-repository-list | grep -i osext | grep -w Used | awk '{ print $1 }')
new_path=$(cmw-repository-list | grep -i osext | grep -w NotUsed | awk '{ print $1 }')
OLD_PATH_FILE="/storage/system/software/coremw/repository/$old_path/old_path_file"
NEW_PATH_FILE="/storage/system/software/coremw/repository/$old_path/new_path_file"

if [ ! -z "$old_path" ] && [ ! -z "$new_path" ]
then
  NEW_REMOVE_SCRIPT="/storage/system/software/coremw/repository/$new_path/remove_rpms.sh"
  OLD_REMOVE_SCRIPT="/storage/system/software/coremw/repository/$old_path/remove_rpms.sh"
  OLD_REMOVE_SCRIPT_BKP="/storage/system/software/coremw/repository/$old_path/remove_rpms.sh_bkp"
fi

# _____________________
#|    _ _   _  .  _    |
#|   | ) ) (_| | | )   |
#|_____________________|
# Here begins the "main" function...

case "$1" in
  set)
        # Copying the new remove_rpms.sh script to old one
        /bin/mv $OLD_REMOVE_SCRIPT $OLD_REMOVE_SCRIPT_BKP
        /bin/cp $NEW_REMOVE_SCRIPT $OLD_REMOVE_SCRIPT       
        apos_log "Replacing the new remove_rpms.sh script done successfully"
   ;;

  reset)
        # Reverting the reomvie_rpms.sh to old one
       /bin/mv $OLD_REMOVE_SCRIPT_BKP $OLD_REMOVE_SCRIPT 
       apos_log "Replacing the original remove_rpms.sh script done successfully"
       [ -e $OLD_PATH_FILE ] && rm $OLD_PATH_FILE
       [ -e $NEW_PATH_FILE ] && rm $NEW_PATH_FILE
   ;;

   *)
     exit $FALSE
   ;;
esac

apos_outro $0
exit $TRUE

