#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A07.sh
# Description:
#       A script to update APOS_OSCONFBIN from the last version.
# Note:
#	None.
##
# Changelog:
# - Wed Feb 24 2016 - Pratap Reddy (xpraupp)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# R1A06 -> R1A07
#------------------------------------------------------------------------------#
# BEGIN: Nothing to do 

# END:  Nothing to do
#------------------------------------------------------------------------------#

# R1A07 -> R1A08
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1A08
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
