#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A12.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Mon Aug 10 - Yeswanth Vankayala (xyesvan)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#BEGIN: Fix for TR HY40656
SUDOERS_FILE="/etc/sudoers"
sed -e '/Defaults secure_path/ s/^#*/#/' -i $SUDOERS_FILE 2>/dev/null
# END

#BEGIN: Fix for TR HY44809
CFG_PATH='/opt/ap/apos/conf'
TMP_FILE='/tmp/tlsdTraceFile.log'

if [ -x /opt/com/util/com_config_tool ]; then
  DEST_DIR=$(/opt/com/util/com_config_tool location)
else
  DEST_DIR='/storage/system/config/com-apr9010443'
fi
DEST_DIR=$DEST_DIR/lib/comp


pushd $CFG_PATH &> /dev/null
  ./apos_deploy.sh --from $CFG_PATH/libcom_tlsd_manager.cfg --to $DEST_DIR/libcom_tlsd_manager.cfg
  if [ $? -ne 0 ]; then
    apos_abort 1 "failure while deploying libcom_tlsd_manager.cfg"
  fi

#Removing tlsdTraceFile.log
if [ -f $TMP_FILE ]; then
  /usr/bin/rm -rf $TMP_FILE 2>/dev/null || apos_log 'tlsdTraceFile.log not available'
fi

popd &>/dev/null
# END: TLS support


#Disable automaticBackup attribute
immcfg -a automaticBackup="0" CmwSwMswMId=1
if [ $? -eq 0 ]; then
  apos_log "automaticBackup is disabled"
else
  apos_log "Failed to disable automaticBackup"
fi

#Disable automaticRestore attribute
immcfg -a automaticRestore="0" CmwSwMswMId=1
if [ $? -eq 0 ]; then
  apos_log "automaticRestore is disabled"
else
  apos_log "Failed to disable automaticRestore"
fi

#HY55333 TR FIX
if is_vAPG; then

  echo 'subscribing ExecStartPost in lde-network.service file..'
  apos_servicemgmt subscribe "lde-network.service" "ExecStartPost" /opt/ap/apos/conf/apos_kernel_parameter_change.sh || apos_abort 'failure subscribing kernel parameter change..'
  echo 'done'

  if systemctl -q is-active lde-network.service ; then
    apos_log 'lde-network service is active, executing apos_kernel_parameter_change.sh script '
    pushd $CFG_PATH &> /dev/null 
    apos_check_and_call $CFG_PATH apos_kernel_parameter_change.sh
    popd &>/dev/null
  fi

fi



# R1A10 -> R1A11
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_12 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
