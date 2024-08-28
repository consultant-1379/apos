#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A05.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Mon 22 Jan 2018 - Yeswanth Vankayala (xyesvan)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

# R1A05 -> R1A06
#------------------------------------------------------------------------------#
#BEGIN creating turbo_boost_cp file for GEP7 if it does not exist
 flag_GEP7LasGEP5_64="/storage/system/config/apos/gep7LasGEP5_64"
 [[ -f "$flag_GEP7LasGEP5_64" ]] &&  rm -f $flag_GEP7LasGEP5_64 

 TURBO_BOOST_CP="/storage/system/config/apos/turbo_boost_cp"
 if ! [ -f "$TURBO_BOOST_CP" ]; then
   touch $TURBO_BOOST_CP
   apos_log "Writing FALSE to turbo_boost_cp file!"
   echo "FALSE" > $TURBO_BOOST_CP
 fi
#END

# R1A06 -> R1A07
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_8 R1A07
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0

exit $TRUE
# End of file

