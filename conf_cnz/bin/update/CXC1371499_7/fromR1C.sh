#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1C.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Thu JAN 16 2018 - Prabhakaran Dayalan (xpraday)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH="/opt/ap/apos/conf"

##
# BEGIN: LDE rpm Activation Failed after faulty node recovery (CC-16374)

apos_log "From Script for OSCONFBIN R1D executed successfully"

# END: LDE rpm Activation Failed after faulty node recovery (CC-16374)

#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_8 R1A01
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
