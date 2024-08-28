#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A01.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CFG_PATH='/opt/ap/apos/conf'

# R1A01 -> R1A02
#------------------------------------------------------------------------------#
# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
# END: com configuration handling
#------------------------------------------------------------------------------#

#R1A01->R1A02
#------------------------------------------------------------------------------#
# BEGIN: Nothing to do
. /opt/ap/apos/conf/aposcfg_axe_sysroles.sh &>/dev/null
# END:  Nothing to do
#------------------------------------------------------------------------------#


# R1A02 -> R1A03
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_9 R1A02
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
