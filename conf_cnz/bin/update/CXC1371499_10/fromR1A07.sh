#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A07.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version 
# Note:
#       None.
##
# Changelog:
# - 17 Jul 2019 - Roshini Chilukoti (zchiros)
#     First version for deployment of hooks.
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh


apos_intro $0
#Common variables
CFG_PATH="/opt/ap/apos/conf"
SRC="/opt/ap/apos/etc/deploy"

#BEGIN Deployment of hooks

pushd $CFG_PATH &> /dev/null
[ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/cluster/hooks/pre-installation.tar.gz" --to "/cluster/hooks/pre-installation.tar.gz" --exlo
popd &>/dev/null


pushd $CFG_PATH &>/dev/null
[ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/cluster/hooks/after-booting-from-disk.tar.gz" --to "/cluster/hooks/after-booting-from-disk.tar.gz" --exlo
popd &>/dev/null

#END Deployment of hooks

# R1A07 -> R1B
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_10 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
