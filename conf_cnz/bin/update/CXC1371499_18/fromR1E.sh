#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2024 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Name:
#       fromR1E.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
#  - Fri Feb 02 2024 - Koti Kiran Maddi (zktmoad)
#	-First version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf/'


# R1E -> R1A01
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_19 R1A01
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

