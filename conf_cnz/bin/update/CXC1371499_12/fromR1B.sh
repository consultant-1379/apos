#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1B.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Thu 11 Sep - Dharma Theja (xdhatej)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH="/opt/ap/apos/conf"

# BEGIN: Profile local handling
# /etc/profile.local file set up

AP_TYPE=$(apos_get_ap_type)
pushd $CFG_PATH &> /dev/null
if [ "AP1" == "$AP_TYPE" ]; then
  apos_check_and_call $CFG_PATH aposcfg_profile-local.sh
fi
popd &> /dev/null

# END: Profile local handling

# R1A13 -> R1A14
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_12 R1C
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

