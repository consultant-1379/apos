#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A04.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version 
# Note:
#       None.
##
# Changelog:
# - 28 May 2019 - Chaitanya Tamiri (xtamcha)
#       Impact for new COM 7.10 introduction
# - Mon 27 May 2019 - Harika Bavana (XHARBAV)
#     First version for deployment of hooks.
# - Wed Feb 13 2019 - Nazeema Begum (xnazbeg)
#       First version.
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh


apos_intro $0
#Common variables
CFG_PATH="/opt/ap/apos/conf"
SRC="/opt/ap/apos/etc/deploy"
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
cluster_file='/cluster/etc/cluster.conf'

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling

# nfs thread count change for gep1
# WORKAROUND FOR JOURNALD SOCKET MEMORY FIX: BEGIN
pushd $CFG_PATH &> /dev/null
if [ "$HW_TYPE"  == "GEP1" ] || [ "$HW_TYPE"  == "GEP2" ]; then
  apos_check_and_call $CFG_PATH apos_cba_workarounds.sh
  [ ! -f /etc/systemd/journald.conf ] && apos_abort 'journald.conf file not found'
  if grep -q '^#Storage=.*$' /etc/systemd/journald.conf 2>/dev/null; then
    sed -i 's/#Storage=.*/Storage=none/g' /etc/systemd/journald.conf 2>/dev/null || \
    apos_abort 'Failure while updating journald.conf file with Storage=none parameter'
    # Re-start the systemd-journald.service
    apos_servicemgmt restart systemd-journald.service &>/dev/null || apos_abort 'failure while restarting systemd-journald service'
  else
    apos_log 'WARNING: Storage value found different than auto. Skipping configuration changes'
  fi

        # Cleanup of Journal directory
        if [ -d /run/log/journal ]; then
                /usr/bin/rm -rf '/run/log/journal' 2>/dev/null || apos_log 'failure while cleaning up journal folder'
        fi
fi
popd &> /dev/null
# WORKAROUND FOR JOURNALD SOCKET MEMORY FIX: END


#BEGIN Deployment of hooks

pushd $CFG_PATH &> /dev/null
[ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/cluster/hooks/post-installation.tar.gz" --to "/cluster/hooks/post-installation.tar.gz" --exlo
popd &>/dev/null


pushd $CFG_PATH &>/dev/null
[ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/cluster/hooks/after-booting-from-disk.tar.gz" --to "/cluster/hooks/after-booting-from-disk.tar.gz" --exlo
popd &>/dev/null

#END Deployment of hooks

# R1A04 -> R1A05
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_10 R1A05
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

