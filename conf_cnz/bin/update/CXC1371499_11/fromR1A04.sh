#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A04.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue Dec 3 2019 - Yeswanth Vankayala (xyesvan)
#      COM Shipment Integration
# - Tue Nov 26  2019 - Sowmya Pola (xsowpol) 
#       First version.
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
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_md" --to "/etc/sudoers.d/APG-comgroup"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_drbd" --to "/etc/sudoers.d/APG-comgroup"
fi

if [ "$STORAGE_TYPE" == "MD" ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
fi

popd &> /dev/null
# END: Deployment of sudoers
##


# BEGIN: handling wwwrun & ftpsecure to cmw-imm-users group
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH aposcfg_appendgroup.sh
popd &>/dev/null
# END: handling wwwrun & ftpsecure to cmw-imm-users group


# R1A03 -> R1A04
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_11 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
