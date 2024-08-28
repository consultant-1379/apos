#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A06.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Wed Aug 30 2017 - Pratap Reddy Uppada (xpraupp)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
SRC='/opt/ap/apos/etc/deploy/usr/lib/lde/config-management'
CFG_PATH="/opt/ap/apos/conf"
AP_TYPE=$(apos_get_ap_type)
FILE="/etc/sysctl.conf"
KEYWORD=""
NEW_ROW=""

function isAP2(){
  [ "$AP_TYPE" == 'AP2' ] && return $TRUE
  return $FALSE
}

##
# BEGIN: ipsec handling
##
apos_log 'Increasing the size of ipsec connection routing table (setting gc threshold limit for ipv4)'
KEYWORD="net.ipv4.xfrm4_gc_thresh"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then
  NEW_ROW="net.ipv4.xfrm4_gc_thresh = 32768"
  cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
  mv "$FILE.new" "$FILE"
else
  NEW_ROW="\n# To increase the size of ipsec connection routing table\nnet.ipv4.xfrm4_gc_thresh =32768 "
  echo -e "$NEW_ROW" >> $FILE
fi

#Reload configuration of sysctl
/sbin/sysctl -p &> /dev/null
if [ $? -ne 0  ]; then
  apos_abort "Failure while reloading configuration of sysctl!"
fi

##
# END: ipsec handling
##


##
# BEGIN: SEC ldap case sensitivity handling
if isAP2; then
  pushd $CFG_PATH &> /dev/null
  ./apos_deploy.sh --from "$SRC/apos_secacs-config" --to "/usr/lib/lde/config-management/apos_secacs-config"
  if [ $? -ne $TRUE ]; then
    apos_abort "failure while deploying apos_dhcpd-config file"
  fi

	./apos_insserv.sh /usr/lib/lde/config-management/apos_secacs-config
  if [ $? -ne 0 ]; then
   apos_abort "failure while creating symlink to file apos_secacs-config"
  fi

  # reload config to update apos_secacs-config
  /usr/lib/lde/config-management/apos_secacs-config config reload
  if [ $? -ne 0 ];then
    apos_abort "Failure while executing apos_secacs-config"
  fi
  popd &> /dev/null
fi

pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_sec-ldapconf.sh
popd &>/dev/null
# END: SEC ldap case sensitivity handling
##

# R1A06 --> R1A07
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_7 R1A07
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
