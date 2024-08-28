#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2014 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A04.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Mon Jan 04 2016 - Pratap Reddy (XPRAUPP)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# R1A03 -> R1A04
#------------------------------------------------------------------------------#

##
# BEGIN: Nothing to do
# END: Nothing to do
##

#------------------------------------------------------------------------------#

# R1A04 -> R1A05
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1A05
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
