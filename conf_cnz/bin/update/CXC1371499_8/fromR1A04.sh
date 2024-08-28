#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
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
# - Fri 15 Dec 2017 - Yeswanth Vankayala (xyesvan)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh


#Common variables
CFG_PATH="/opt/ap/apos/conf"

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
# END: com configuration handling

# BEGIN: Deploy sudoers file for drbd-overview fix
STORAGE_TYPE=$(get_storage_type)
SRC='/opt/ap/apos/etc/deploy'
if [ "$STORAGE_TYPE" == "MD" ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
fi
# END: Deploy sudoers file for drbd-overview fix

popd &> /dev/null


# R1A04 -> R1A05
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_8 R1A05
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0

exit $TRUE
# End of file

