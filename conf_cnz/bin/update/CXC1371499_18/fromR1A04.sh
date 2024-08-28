#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2023 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Name:
#       fromR1A04.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
#  - Fri Aug 18 2023 - Kishore (zkisvel)
#   First version of script  
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf/'
SRC='/opt/ap/apos/etc/deploy'


# BEGIN: Deployment of sudoers
STORAGE_TYPE=$(get_storage_type)

pushd $CFG_PATH &> /dev/null

if [ "$STORAGE_TYPE" == "MD" ] ; then
    ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup"
else
    ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
fi

popd &> /dev/null
# END: Deployment of sudoers
##


# R1A04 -> R1A05
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_18 R1A05
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

