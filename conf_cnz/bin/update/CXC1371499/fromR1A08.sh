#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A08.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1A07.
# Note:
#	None.
##
# Changelog:
# - Fri Jul 31 2015 - Pratap Reddy Uppada(XPRAUPP)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#------------------------------------------------------------------------------#

# R1A07 --> R1A08
#------------------------------------------------------------------------------#

##
# BEGIN: Nothing to do 
# END: Nothing to do
##

#------------------------------------------------------------------------------#

# R1A08 -> R1A09
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R1A09
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A09"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
