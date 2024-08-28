#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2023 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Name:
#       fromR1C.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
#  - Mon Oct 09 2023 - Pravalika (zprapxx)
#   First version of script, To remove the bash built-in cmd logging changes   
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf/'
SRC='/opt/ap/apos/etc/deploy'

#Removing bash built-in cmd logging changes
apos_log 'Calling aposcfg_bash-bashrc-local.sh to remove the bash built-in cmd logging changes'
pushd $CFG_PATH &> /dev/null
  apos_check_and_call $CFG_PATH aposcfg_bash-bashrc-local.sh 
popd &> /dev/null



# R1C -> R1A01
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_18 R1D
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

