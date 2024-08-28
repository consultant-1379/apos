#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1C.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version 
# Note:
#       None.
##
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh


apos_intro $0

# R1B -> R1C
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_10 R1D
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
