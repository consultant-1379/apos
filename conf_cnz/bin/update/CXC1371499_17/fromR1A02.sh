#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue Fe 21 2023 - Naveen Kumar G (ZGXXNAV)
#   ts session timeout (15 mins) configured in sshd_config_4422 
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0



# R1A02 -> R1B
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_17 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
