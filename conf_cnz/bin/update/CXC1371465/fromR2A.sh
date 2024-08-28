#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2014 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR2A.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R2A.
# Note:
#	None.
##
# Changelog:
# - Wed Oct 14 2015 - Pratap Reddy Uppada(XPRAUPP)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# R2A --> R1A01
#------------------------------------------------------------------------------#
##
# BEGIN: Nothing to do 
# END: Nothing to do
##

# R1A01 -> <NEXT_REVISION>
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R1A01
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A01"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
