#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2024 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
##
# Friday 03th May - Surya Mahit (zsurjon)
# #        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null
# END: com configuration handling


# R1A02 -> R1B
#------------------------------------------------------------------------------#
#pushd /opt/ap/apos/conf &>/dev/null
#./apos_update.sh CXC1371499_19 R1B
#popd &>/dev/null
#------------------------------------------------------------------------------#
apos_outro $0
exit $TRUE
