#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2023 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Name:
#       fromR1B.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
#  - Fri Oct 13 2023 - Swapnika Baradi (xswapba)
#   First version of script  
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0



# R1B -> R1C
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_18 R1C
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

