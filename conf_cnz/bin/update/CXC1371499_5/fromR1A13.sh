#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A13.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Fri Jun 10 2016 - Alessio Cascone (EALOCAE)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
CFG_PATH="/opt/ap/apos/conf"

pushd $CFG_PATH &> /dev/null

# /etc/ssh/sshd_config file set up - SSH server configuration for external networks
apos_check_and_call $CFG_PATH aposcfg_sshd_config.sh

apos_servicemgmt disable apg-vsftpd.socket &>/dev/null
if [ $? -ne 0 ];then
  apos_abort "Failure while deactivating apg-vsftpd.socket"
fi

STORAGE_TYPE=$(get_storage_type)
SRC='/opt/ap/apos/etc/deploy'
if [ "$STORAGE_TYPE" == "MD" ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup" 
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
fi
popd &> /dev/null

# R1A13 -> R1A14
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1A14
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
