#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A03.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
## Fri 9 Sep - Swapnika (xswapba)
##         First Version

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh
apos_intro $0

# R1A03 -> R1A04
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_16 R1A04
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

