#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1D.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Tue 02 Aug - Swapnika Baradi (xswapba)
#        First Version 
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CACHE_DIR="/dev/shm/"
CACHE_FILE="${CACHE_DIR}/apos_hwtype.cache"
CACHE_FILE_VERBOSE="${CACHE_DIR}/apos_hwtype_verbose.cache"
CMD_RM="/usr/bin/rm"

[ -f "$CACHE_FILE" ] && $CMD_RM $CACHE_FILE
[ -f "$CACHE_FILE_VERBOSE" ] && $CMD_RM $CACHE_FILE_VERBOSE

# R1D -> R1E
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_15 R1E
popd &>/dev/null
#------------------------------------------------------------------------------#
apos_outro $0
exit $TRUE

