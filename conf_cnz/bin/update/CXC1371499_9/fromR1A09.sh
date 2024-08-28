#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A09.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version for JOURNALD issue
# Note:
#	None.
##
# Changelog:
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CFG_PATH='/opt/ap/apos/conf'

# BEGIN: Deploy of drbd config
SRC='/opt/ap/apos/etc/deploy'

#deploying apos-drbd.sh files
  DD_REPLICATION_TYPE=$(get_storage_type)

  if [ "$DD_REPLICATION_TYPE" == "DRBD" ]; then
    pushd $CFG_PATH &> /dev/null
    [ ! -x ./apos_deploy.sh ] && apos_abort 1 '$CFG_PATH/apos_deploy.sh not found or not executable'
    ./apos_deploy.sh --from "$SRC/usr/lib/systemd/scripts/apos-drbd.sh" --to "/usr/lib/systemd/scripts/apos-drbd.sh"
    [ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of apos-drbd.sh file"
    popd &>/dev/null
  fi

# END: Deploy of drbd config
##


# R1A09 -> R1A10
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_9 R1A10
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
