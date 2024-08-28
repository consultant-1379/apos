#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
#
# Name:
#       fromR1C.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Wed Apr 19 2023 - Koti Kiran Maddi (ZKTMOAD)
#   Fix for TR IA38326 
# - Tue Apr 25 2023 - Pravalika (ZPRAPXX)
#   Impacts for CIS-CAT Improvements feature
# - Mon Jul 31 2023 - Pravalika (ZPRAPXX)
#   TR IA51135 Fix  
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf/'
SRC='/opt/ap/apos/etc/deploy'

# BEGIN: updating iptables configuration
  pushd $CFG_PATH &>/dev/null
  if is_vAPG; then
    apos_check_and_call $CFG_PATH apos_iptables.sh
  fi
  popd &>/dev/null
# END: updating iptables configuration

# As part of CISCAT Improvements feature disabling unused filesystems after upgrade
apos_log 'Deploying lde-disable-unused-filesystems.conf file for disabling unused filesystems'
pushd $CFG_PATH &> /dev/null
  ./apos_deploy.sh --from "$SRC/etc/modprobe.d/lde-disable-unused-filesystems.conf" --to "/etc/modprobe.d/lde-disable-unused-filesystems.conf"
popd &> /dev/null

#As part of CISCAT Improvements feature Reloading the apos_grub-config file to apply the changes
apos_log 'Reloading the grub configuration file'
/usr/lib/lde/config-management/apos_grub-config config reload
if [ $? -ne 0 ]; then
  apos_abort  "Reload of  \"apos_grub-config\" file got failed"
fi

#As part of CISCAT Improvements feature adding new audit events in security_audit file
apos_log 'Adding new audit events in security_audit file'
/usr/lib/lde/config-management/apos_syslog-config config init
if [ $? -ne 0 ];then
apos_abort "Failure while executing apos_syslog-config"
fi
#TR IA51135 fix: Removing restart from this script and moving it to campaign scripts. As sometimes restart is being triggered when LDE is updating rsyslog configuration files leading to restart failure. 
#apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'

#As part of CISCAT Improvements feature changing the umask to 0027 
apos_log 'Changing the umask to 0027'
pushd $CFG_PATH &>/dev/null
 apos_check_and_call $CFG_PATH aposcfg_login-defs.sh
popd &> /dev/null


# R1C -> R1A01
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_17 R1D
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

