#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2023 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Name:
#       fromR1A03.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Thu July 20 2023 - Pravalika (zprapxx)
#   CISCAT Improvements feature: Improvements 
# - Tue Jul 25 2023 - Naveen Kumar G (zgxxnav)
#   First version of script  
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf/'
SRC='/opt/ap/apos/etc/deploy'

#As part of CISCAT Improvements feature adding bash shell cmd  audit events in security_audit file
apos_log 'Adding bash shell cmd audit events in security_audit file'
/usr/lib/lde/config-management/apos_syslog-config config init
if [ $? -ne 0 ];then
apos_abort "Failure while executing apos_syslog-config"
fi
#Avoiding rsyslog restart due to TR IA51135 issue, restart added in campaign 

# BEGIN: Deployment of sudoers
STORAGE_TYPE=$(get_storage_type)

pushd $CFG_PATH &> /dev/null

if [ "$STORAGE_TYPE" == "MD" ] ; then
    ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup"
else
    ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
fi

popd &> /dev/null
# END: Deployment of sudoers
##


# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null
# END: com configuration handling


# R1A03 -> R1A04
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_18 R1A04
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

