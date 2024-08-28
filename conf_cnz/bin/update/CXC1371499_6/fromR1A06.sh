#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A06.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Wed Apr 12 2017 - Pratap reddy(xpraupp)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'

##
# BEGIN: udev rules for DVD auto-close fix
pushd $CFG_PATH &> /dev/null
apos_check_and_call $CFG_PATH apos_udevconf.sh
popd &>/dev/null
# END: udev rules for DVD auto-close fix
##

##
if is_vAPG; then 
  pushd $CFG_PATH &> /dev/null
  # modify service unit file for vmware tools
  apos_check_and_call $CFG_PATH apos_guest.sh
  popd &>/dev/null
fi
##

# R1A06 --> R1A07
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_6 R1A07
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
