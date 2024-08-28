#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A08.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue May 2017 - Neelam Kumar(xneelku)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
# BEGIN: Nothing to do 
# END: Nothing to do 
##

# R1A08 --> <Next version>
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_6 R1A09
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

