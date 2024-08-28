#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2014 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1A02.
# Note:
#	None.
##
# Changelog:
# - Mon Dec 14 2015 - Vankayala Yeswanth (XYESVAN)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# R1A02 -> R1A03
#------------------------------------------------------------------------------#

##
# BEGIN: Nothing to do
# END: Nothing to do
##

#------------------------------------------------------------------------------#

# R1A02 -> R1A03
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371544 R1A03
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
