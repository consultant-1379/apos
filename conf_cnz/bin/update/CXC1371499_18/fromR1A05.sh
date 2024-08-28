#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2023 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Name:
#       fromR1A05.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
#  - Fri Aug 25 2023 - Pravalika (zprapxx)
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

#Changes to enable bash built-in cmd logging 
pushd $CFG_PATH &> /dev/null
   apos_check_and_call $CFG_PATH aposcfg_bash-bashrc-local.sh
popd &> /dev/null



# R1A05 -> R1B
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_18 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

