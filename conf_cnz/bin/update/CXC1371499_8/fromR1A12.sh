#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A12.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# R1A12 -> R1A
#------------------------------------------------------------------------------#
# BEGIN: Nothing to do
# END:  Nothing to do
#------------------------------------------------------------------------------#

# R1A12 -> R1A01
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_9 R1A01
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
