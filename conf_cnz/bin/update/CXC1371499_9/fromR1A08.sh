#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A08.sh
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

CMD_SYSTEMCTL='/usr/bin/systemctl'
CFG_PATH='/opt/ap/apos/conf'

############## COM Integration ####################
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null
###################################################

# WORKAROUND: BEGIN
# HW49279: contain a PTF (from SuSE) to disable system call auditing (also the BB for CC-19615)
apos_servicemgmt stop systemd-journald-audit.socket --force &>/dev/null || \
  apos_abort 'failure while stopping systemd-journald-audit socket'
apos_log "apos_servicemgmt stop for systemd-journald-audit.socket: Done"
/usr/bin/systemctl mask systemd-journald-audit.socket &>/dev/null
if [ $? -eq 0 ];then
  apos_log "apos_servicemgmt mask for systemd-journald-audit.socket: Done"
else
  apos_abort "apos_servicemgmt mask for systemd-journald-audit.socket: Failed"
fi
# WORKAROUND: END
## 

##
# WORKAROUND FOR JOURNALD SOCKET MEMORY FIX: BEGIN
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
[ -z "$HW_TYPE" ] && apos_abort 1 'HW_TYPE not found'
if [ "$HW_TYPE"  == 'GEP1' ]; then 
  [ ! -f /etc/systemd/journald.conf ] && apos_abort 'journald.conf file not found'
  if grep -q '^#Storage=.*$' /etc/systemd/journald.conf 2>/dev/null; then 
    sed -i 's/#Storage=.*/Storage=none/g' /etc/systemd/journald.conf 2>/dev/null || \
      apos_abort 'Failure while updating journald.conf file with Storage=none parameter'
    # Re-start the systemd-journald.service
    echo 'performing systemd-journald service restart...'
    apos_servicemgmt restart systemd-journald.service &>/dev/null || apos_abort 'failure while restarting systemd-journald service'
    echo 'done'
  else
    apos_log 'WARNING: Storage value found different than auto. Skipping configuration changes'
  fi

  # Cleanup of Journal directory
  if [ -d /run/log/journal ]; then
    /usr/bin/rm -rf '/run/log/journal' 2>/dev/null || apos_log 'failure while cleaning up journal folder'
  fi
fi
# WORKAROUND FOR JOURNALD SOCKET MEMORY FIX: END
##


# R1A08 -> R1A09
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_9 R1A09
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
