#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A03.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Mon Jan 16 2017 - Antonio Buonocunto
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

SRC='/opt/ap/apos/etc/deploy/usr/lib/lde/config-management'
CFG_PATH="/opt/ap/apos/conf"
AP_TYPE=$(apos_get_ap_type)

apos_intro $0

function isAP2(){
  [ "$AP_TYPE" == 'AP2' ] && return $TRUE
  return $FALSE
}

# R1A03 -> R1A04
#BEGIN: adding apos-ntp-config for virtual environment------------------------#
if ! isAP2; then
  pushd $CFG_PATH &> /dev/null
  ./apos_deploy.sh --from "$SRC/apos_dhcpd-config" --to "/usr/lib/lde/config-management/apos_dhcpd-config" || apos_abort "failure while deploying apos_dhcpd-config file"
  # reload config to update apos_dhcpd-config
  /usr/lib/lde/config-management/apos_dhcpd-config config reload
  if [ $? -ne 0 ];then
    apos_abort "Failure while executing apos_dhcpd-config"
  fi
  popd &> /dev/null

  # Reload the cluster configuration on the current node to trigger ntp-conig execution
  cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
fi
# END: deploying apos_ntp-config file
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#

# R1A04 -> R1A05
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_6 R1A04 
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
