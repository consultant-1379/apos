#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR2A.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R2A.
# Note:
#       None.
##
# Changelog:
# - Tue Mar 08 2016 - Baratam Swetha(XSWEBAR)
#   -- Added profile.local script invoke for HU53683
# - Thu Mar 03 2016 - Roni Newatia(XRONNEW)
#   -- Added COMSA imma syncr timeout for ENM feature
# - Mon Feb 24 2016 - Swapnika Baradi(XSWAPBA)
# - Mon Feb 22 2016 - Nazeema Begum(XNAZBEG)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
SRC='/opt/ap/apos/etc/deploy'
CFG_PATH='/opt/ap/apos/conf'
AP_TYPE=$(apos_get_ap_type)

# R2A --> CXC1371499_4 R1A
#------------------------------------------------------------------------------#
##

# BEGIN: syslog-ng configuration script
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_syslog-config" --to "/usr/lib/lde/config-management/apos_syslog-config" || apos_abort "failure while deploying syslog-ng configuration file"
killall -HUP 'syslog-ng' &>/dev/null || apos_abort 'failure while reloading syslog configuration'
popd &>/dev/null
# END:  syslog-ng configuration script
##

##
# BEGIN: Configuration of COMSA imma syncr timeout
COMSA_DEST_DIR="/storage/system/config/comsa_for_coremw-apr9010555/etc"
COMSA_IMMA_SYNCR_TIMEOUT="360000"
sed -i "s@[[:space:]]*imma_syncr_timeout=.*@imma_syncr_timeout=$COMSA_IMMA_SYNCR_TIMEOUT@g" $COMSA_DEST_DIR/comsa.cfg
if [ $? -ne 0 ]; then
  apos_abort 1 "Configuration of imma_syncr_timeout failed."
else
  apos_log "imma_syncr_timeout configured to $COMSA_IMMA_SYNCR_TIMEOUT."
fi
# END:  Configuration of COMSA imma syncr timeout
##

##
#BEGIN: iptable rules reload for backplane hardening rules reload
pushd $CFG_PATH &>/dev/null
./apos_iptables.sh
cluster config -v &>/dev/null || apos_abort "cluster.conf validation has failed!"
cluster config -r -n $(</etc/cluster/nodes/this/id) &>/dev/null || apos_abort "cluster.config reload has failed!"
service iptables restart &>/dev/null || apos_abort 'failure while restarting iptables service'
popd &>/dev/null 
# END: iptable rules reload for backplane hardening rules reload 
##

##
# BEGIN: Profile local handling
# /etc/profile.local file set up
pushd $CFG_PATH &> /dev/null
if [ "AP1" == "$AP_TYPE" ]; then
 apos_check_and_call $CFG_PATH aposcfg_profile-local.sh
else
 apos_check_and_call $CFG_PATH aposcfg_profile-local_AP2.sh
fi
popd &> /dev/null
# END: Profile local handling
##

# R2A (APG43L 3.1) -> R1A01 (APG43L 3.2 LSV1)
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371544 R1A01 
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A01"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

