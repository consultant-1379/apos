#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1B.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Sat Feb 21 2020 - Yeswanth Vankayala (xyesvan)
#       First version.
# - Thu Dec 26 2019 - Dharma Teja (xdhatej)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
STORAGE_CONFIG_PATH="/storage/system/config"
APOS_PSO="$STORAGE_CONFIG_PATH/apos"
APG_VERSION_FILE="$APOS_PSO/apg_protocol_version_type"
CFG_PATH="/opt/ap/apos/conf"

pushd $CFG_PATH &>/dev/null
# BEGIN: HSS feature handling
    apos_check_and_call $CFG_PATH apos_failoverd_conf.sh
# END: HSS feature handling
# BEGIN: set up /ets/syncd.conf with AP2 file
    apos_check_and_call $CFG_PATH aposcfg_syncd-conf.sh
# END: set up /ets/syncd.conf with AP2 fil
popd &>/dev/null


if is_vAPG; then
  [ ! -f "$APG_VERSION_FILE" ] && echo "4" > "$APG_VERSION_FILE"
fi


# R1A03 -> R1A04
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_11 R1C
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
