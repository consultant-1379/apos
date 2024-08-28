#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A10.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Thu Jul 09 - Ramya Medichelmi (zmedram)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# R1A10 -> R1A11
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_12 R1A11
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
