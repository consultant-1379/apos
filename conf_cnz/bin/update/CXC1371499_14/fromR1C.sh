# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1C.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Tue 04 Jan - P S SOUMYA (zpsxsou)
#        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'

# BEGIN: Fix for HZ53240

pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_certgrp.sh
popd &>/dev/null
# END: Fix for HZ53240



# R1B -> R1C
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_14 R1D
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
