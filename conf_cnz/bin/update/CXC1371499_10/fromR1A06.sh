#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A06.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version 
# Note:
#       None.
##
# Changelog:
# - 17 Jul 2019 - Yeswanth Vankayala (xyesvan)
#      Fixed missing variable CFG_PATH
# - 15 Jul 2019 - Yeswanth Vankayala (xyesvan)
#       Fix for TR HX78973 and HX79009
# - 3 Jul 2019 - Yeswanth Vankayala (xyesvan)
#       Fix for TR HX76796
# - 03 Jul 2019 - Pratapa Reddy Uppada (xpraupp)
#       First Draft grub.cfg file reload 
# - 1 Jul 2019 - Yeswanth Vankayala (xyesvan)
#       First Draft 
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common Variables
LDE_CONFIG_MGMT='/usr/lib/lde/config-management'
CFG_PATH="/opt/ap/apos/conf"

if [ -f $LDE_CONFIG_MGMT/apos_tipc-config ]; then
  rm -f $LDE_CONFIG_MGMT/apos_tipc-config
  apos_log "Successfully removed apos_tipc-config file"
else
  apos_log"File apos_tipc-config  is not present"
fi

# Reload the apos_gub-config file to apply the changes
/usr/lib/lde/config-management/apos_grub-config config reload
if [ $? -ne 0 ]; then
  apos_abort  "Reload of  \"apos_grub-config\" file got failed"
fi

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling


# R1A06 -> R1A07
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_10 R1A07
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
