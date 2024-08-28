#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
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
#        First Version
# Wed 16 2021 zbhegna
#	 Added apos_comconf.sh
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0


#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"

##
# BEGIN: Deployment of sudoers
STORAGE_TYPE=$(get_storage_type)
pushd $CFG_PATH &> /dev/null

if [ "$STORAGE_TYPE" == "MD" ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
fi
popd &> /dev/null

pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null

# R1C -> R1D
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_13 R1D
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

