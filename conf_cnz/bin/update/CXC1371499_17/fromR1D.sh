#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Name:
#       fromR1C.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue Aug 1 2023 - Swapnika Baradi (XSWAPBA)
#   Fix for TR IA45804
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf/'
SRC='/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts'
DEST='/usr/lib/systemd/scripts'

# BEGIN: DHCP configuration update
ITEM='apg-dhcpd.sh'
pushd $CFG_PATH &> /dev/null
./apos_deploy.sh --from $SRC/$ITEM --to $DEST/$ITEM
[ ! $? = 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
popd &> /dev/null
# END: DHCP configuration update

# R1D -> R1E
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_18 R1A01
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

