#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A09.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Sat Jul 18 - Yewanth Vankayala (xyesvan)
#       Cluster conf relad added 
# Mon Jul 13 - Anjali M (xanjali)
# Thu Jul 09 - Ramya Medichelmi (zmedram)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CFG_PATH='/opt/ap/apos/conf'
SRC='/opt/ap/apos/etc/deploy'
SOCK_PATH='usr/lib/systemd/system/'

# Get the AP type
AP_TYPE=$(apos_get_ap_type)
[ -z "$AP_TYPE" ] && apos_abort "AP_TYPE not found"

if [ "$AP_TYPE" == 'AP1' ]; then
  # BEGIN: Fix for TR HY37860
  pushd $CFG_PATH &>/dev/null
  [ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"

  ./apos_deploy.sh --from "$SRC/$SOCK_PATH/apg-vsftpd-APIO_1.socket" --to "/$SOCK_PATH/apg-vsftpd-APIO_1.socket"
  [ $? -ne 0 ] && apos_abort 1 "Failure during the deployment of apg-vsftpd-APIO_1.socket file"

  ./apos_deploy.sh --from "$SRC/$SOCK_PATH/apg-vsftpd-APIO_2.socket" --to "/$SOCK_PATH/apg-vsftpd-APIO_2.socket"
  [ $? -ne 0 ] && apos_abort 1 "Failure during the deployment of apg-vsftpd-APIO_2.socket file"

  cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
  popd &>/dev/null
fi

# END : Fix for TR HY37860


# BEGIN: Fix for TR HY52833
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
# END: Fix for TR HY52833

# R1A09 -> R1A10
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_12 R1A10
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
