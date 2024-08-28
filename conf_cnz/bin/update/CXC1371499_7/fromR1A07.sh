#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A07.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Wed Mar 08 2017 - Baratam Swetha (xswebar)
#       Added deploy of atftp files on AP2 ##
# - Mon Sep 04 2017 - Dharma Teja
#       Added TR fix HW16938 APG not contactable after configuration of NetConf over TLS
#       Added TR fix HV59850 Security compliance-Password Setting
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

CFG_PATH="/opt/ap/apos/conf"
AP_TYPE=$(apos_get_ap_type)

apos_intro $0

# R1A03-> R1A04
#BEGIN: atftpd deploy on AP2(HV56263)

if [ "$AP_TYPE" == "AP2" ]; then
LIST='etc/sysconfig/atftpd
      usr/lib/systemd/scripts/apg-atftps.sh
      usr/lib/systemd/system/apg-atftpd@.service
      usr/lib/systemd/system/apg-atftps.service'

 SRC='/opt/ap/apos/etc/deploy'
    for ITEM in $LIST; do
      pushd $CFG_PATH &> /dev/null
      ./apos_deploy.sh --from $SRC/$ITEM --to /$ITEM
      [ ! $? = 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
    done
    popd &> /dev/null
fi

#END atftpd deploy on AP2(HV56263)


# BEGIN: Rejecting username in password complexity for tsusers(HV59850)
PWD_CONF_FILE="/etc/pam.d/acs-apg-password-local"
NEWPARAM="reject_username"
CMD_GREP='/usr/bin/grep'

$CMD_GREP -i "type*" $PWD_CONF_FILE | $CMD_GREP -q "reject_username"
if [ $? -ne  0 ]; then
  apos_log "adding \"$NEWPARAM\" to $PWD_CONF_FILE..."
  sed -i -e "/type= /s/$/ $NEWPARAM/" $PWD_CONF_FILE
  if [ $? != 0 ]; then
    apos_log "failure while adding \"$NEWPARAM\" to $PWD_CONF_FILE file"
  fi
else
  apos_log "\"$NEWPARAM\" already present"
fi
# END: Rejecting username in password complexity for tsusers(HV59850)


#Fix for TR:HW16938
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null

#------------------------------------------------------------------------------#

# R1A07 -> R1B
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_7 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#
apos_outro $0
exit $TRUE
