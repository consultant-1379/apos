#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2024 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Name:
#       fromR1D.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
#  - Fri Jan 12 2024 - Pravalika (zprapxx)
#    TR IA72765 Fix
#  - Tue Jan 02 2024 - Swapnika Baradi (xswapba)
#    First version of script
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf/'

#Calling apos_comconf.sh script
apos_log 'Calling apos_comconf.sh'
pushd $CFG_PATH &> /dev/null
  apos_check_and_call $CFG_PATH apos_comconf.sh 
popd &> /dev/null

#Modifying netcc user configuration
NETCONF_USERNAME="netcc"
/usr/bin/id $NETCONF_USERNAME
user_present=$?

if [ $user_present -eq 0 ]; then
 /opt/ap/apos/bin/usermgmt/usermgmt user modify --shell=/bin/false --uname=$NETCONF_USERNAME
 [ $? -ne 0 ] && apos_log "Failed to remove bash shell login for 'netcc' user"
fi


#TR IA72765 Fix 
#Changes to enable bash built-in cmd logging 
pushd $CFG_PATH &> /dev/null
   apos_check_and_call $CFG_PATH aposcfg_bash-bashrc-local.sh
popd &> /dev/null



# R1D -> R1E
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_18 R1E
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

