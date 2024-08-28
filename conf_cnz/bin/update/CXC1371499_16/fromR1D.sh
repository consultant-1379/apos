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
##
# Thrusday 09 jan - Sowjanya Medak (xsowmed)
# Tue 03 Jan - Koti Kiran (zktmoad)
# #        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
#------------------------------------------------------------------------------#
CFG_PATH='/opt/ap/apos/conf/'

# BEGIN: updating iptables configuration
  pushd $CFG_PATH &>/dev/null
  if is_vAPG; then
    apos_check_and_call $CFG_PATH apos_iptables.sh
  fi
  popd &>/dev/null
# END: updating iptables configuration

# R1D -> R1A01
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_17 R1A01
popd &>/dev/null
#------------------------------------------------------------------------------#
apos_outro $0
exit $TRUE
