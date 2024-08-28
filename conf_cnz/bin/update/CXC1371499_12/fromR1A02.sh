#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
##	Changes in the sshd_config_mssd file to adapt to IPv6 functionality
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0


#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC='/opt/ap/apos/etc/deploy'
AP1='AP1'

# SSHD_MSSD_SERVICE_AP1: represents the reference of the service to be handled only in AP1
SSHD_MSSD_SERVICE_AP1='lde-sshd@sshd_config_mssd.service'

# BEGIN: ssh -s support impacts in APG
pushd $CFG_PATH &> /dev/null

# Fix for issue in APG43L-3.8: Failed to get the AP_TYPE after reboot, after completion of  successful MI
./aposcfg_syncd-conf.sh
  if [ $? -ne 0 ]; then
    apos_abort "failure while executing \"aposcfg_syncd-conf.sh\""
  fi

# Get the AP type
AP_TYPE=$(apos_get_ap_type)
[ -z "$AP_TYPE" ] && apos_abort "AP_TYPE not found"

if [ "$AP_TYPE" == $AP1 ]; then
  ./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_mssd --to /etc/ssh/sshd_config_mssd
  if [ $? -ne 0 ]; then
    apos_abort 1 "failure while deploying \"sshd_config_mssd\" file"
  fi

  apos_log 'Restarting the APG sshd server'
  # Restart sshd mssd daemon handled by APG
  if systemctl -q is-active $SSHD_MSSD_SERVICE_AP1;then
    systemctl restart $SSHD_MSSD_SERVICE_AP1 || apos_abort "Failure while restarting \"$SSHD_MSSD_SERVICE_AP1\""
  else
    systemctl start --no-block $SSHD_MSSD_SERVICE_AP1
  fi
fi

popd &>/dev/null

# R1A12 -> R1A
#------------------------------------------------------------------------------#
# BEGIN: Nothing to do
# END:  Nothing to do
#------------------------------------------------------------------------------#

# R1A02 -> R1A03
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_12 R1A03
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
