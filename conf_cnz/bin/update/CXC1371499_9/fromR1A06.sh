#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A06.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version for COM Integration.
# Note:
#	None.
##
# Changelog:
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CFG_PATH='/opt/ap/apos/conf'

pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null


# R1A06 -> R1A07
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_9 R1A07
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
