#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1B.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
##
# Mon 03 Oct - Naveen kumar G (zgxxnav)
# #        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
LDE_SUDO_FILE="/etc/sudoers.d/lde-sudo-config"

sed -e '/Defaults use_pty/ s/^#*/#/' -i $LDE_SUDO_FILE 2>/dev/null
if [ $? -eq 0 ]; then
  apos_log "Commenting Defaults use_pty in lde-sudo-config file success"
else
  apos_log "Commenting Defaults use_pty in lde-sudo-config file fail"
fi

# R1B -> R1C
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_16 R1C
popd &>/dev/null
#------------------------------------------------------------------------------#
apos_outro $0
exit $TRUE
