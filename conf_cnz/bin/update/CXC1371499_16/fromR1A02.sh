#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
##Mon 20 Jul - P S SOUMYA (zpsxsou)
##         First Version
# Load the apos common functions.

. /opt/ap/apos/conf/apos_common.sh
apos_intro $0
SRC='/opt/ap/apos/etc/deploy'
CFG_PATH='/opt/ap/apos/conf'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_syslog-config" --to "/usr/lib/lde/config-management/apos_syslog-config"
popd &>/dev/null

# R1A02 -> R1A03
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_16 R1A03
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

