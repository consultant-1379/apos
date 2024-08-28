#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1E.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version 
# Note:
#       None.
##
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh


apos_intro $0

#Common variables
CFG_PATH="/opt/ap/apos/conf"

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling


# R1D -> R1E
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_11 R1A01
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
