#     Copyright (C) 2020 Ericsson AB. All rights reserved.
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
# Fri 13 Aug - Anjireddy Daka (xdakanj)
#        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# R1A04 -> R1A05
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_14 R1A05
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

