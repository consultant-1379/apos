#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A12.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Fri Jan 08 - Swapnika Baradi (xswapba)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#BEGIN: Fix for TR HY77682
SUDOERS_FILE="/etc/sudoers"
sed -i 's/Defaults env_keep = "[^"]*/& USER CLIENT_IP PORT USER_IS_CACHED/' $SUDOERS_FILE 2>/dev/null
if [ $? -eq 0 ]; then
  apos_log "Updating env_keep variable in sudoers file success"
else
  apos_log "Updating env_keep variable in sudoers file fail"
fi
# END


# R1A04 -> R1B
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_13 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
