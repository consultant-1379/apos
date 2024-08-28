#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2023 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Name:
#       fromR1A01.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue Apr 25 2023 - Pravalika (ZPRAPXX)
#   First version of script  
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# R1A01 -> R1A02
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_18 R1A02
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

