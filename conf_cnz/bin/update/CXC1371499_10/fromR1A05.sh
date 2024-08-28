#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A05.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version 
# Note:
#       None.
##
# Changelog:
# - 12 Jun 2019 - Yeswanth Vankayala (xyesvan)
#       Fix for TR HX72492
# - 12 June 2019 - Chaitanya Tamiri (xtamcha)
#       Impact for new COM 7.10 R11A16 introduction
# - 08 May 2019 - Pratapa Reddy Uppada (xpraupp)
#       First Draft (Added steps to disable the postfix service)
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh


apos_intro $0
#Common variables
CFG_PATH="/opt/ap/apos/conf"
SRC="/opt/ap/apos/etc/deploy"
LDE_CONFIG_MGMT='usr/lib/lde/config-management'
SOCK_PATH='usr/lib/systemd/system/'
postfix_service_file='/usr/lib/systemd/system/postfix.service'

# BEGIN: apos_ip-config script configuration
pushd $CFG_PATH &> /dev/null
[ ! -x ./apos_deploy.sh ] && apos_abort 1 "$CFG_PATH/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/$LDE_CONFIG_MGMT/apos_ip-config" --to "/$LDE_CONFIG_MGMT/apos_ip-config"
[ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of apos_ip-config file"
./apos_deploy.sh --from "$SRC/$SOCK_PATH/apg-vsftpd-nbi.socket" --to "/$SOCK_PATH/apg-vsftpd-nbi.socket"
[ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of apg-vsftpd-nbi.socket file"
popd &> /dev/null

# Reload the config file on the current node
/$LDE_CONFIG_MGMT/apos_ip-config config init
[ $? -ne 0 ] && apos_abort "Failure while executing apos_ip-config"

cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
# END: apos_ip-config script configuration
##

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling

##
# BEGIN: postfix server disabling
if [ -f ${postfix_service_file} ]; then
  if apos_servicemgmt is_running postfix.service &>/dev/null; then
    apos_log 'Stopping the postfix service... '
    apos_servicemgmt stop postfix.service &>/dev/null || apos_abort 'failure while stopping postfix service'
    apos_log 'Done'
  else
    apos_log 'postfix service is already stopped'
  fi

  # Disable the service
  apos_log 'Disabling postfix service... '
  if [ -x /sbin/chkconfig ]; then
    /sbin/chkconfig postfix off &>/dev/null || apos_abort 'failure while disbaling the postfix service'
  else
    apos_servicemgmt disable postfix.service &>/dev/null || apos_abort 'failure while disabling postfix service'
  fi
  apos_log 'Done'
else
  apos_log 'postfix service file not found in systemd. Skipping disabling of postfix service'
fi
# END: postfix server disabling
##

# R1A05 -> R1A06
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_10 R1A06
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
