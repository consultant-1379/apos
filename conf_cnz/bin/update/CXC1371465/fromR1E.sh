#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2014 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1E.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1E
# Note:
#	None.
##
# Changelog:
# - Wed Feb 04 2015 - Pratap Reddy Uppada(XPRAUPP)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CFG_PATH="/opt/ap/apos/conf"
# R1E --> R1A01
#------------------------------------------------------------------------------#
cluster_conf_reload() {
  local lcc_name="/usr/bin/cluster"
  $lcc_name config -v &>/dev/null
  local status=$?

  if [ $status -ne $TRUE ]; then
    echo -e "\nSyntax error in the new iptables configuration"
  else
    $lcc_name config -r -a
  fi

  return $status
}
#------------------------------------------------------------------------------#
function is_rif_defined(){
  local stateToReturn=$FALSE
  local APOS_RE_CONF="/cluster/storage/system/config/apos/apos_rif.conf"

  if [ -e $APOS_RE_CONF ]; then
    rifStateA=$(cat $APOS_RE_CONF | grep RIFSTATE1 | awk ' BEGIN { FS = "=" } ; { print $2}'| awk ' BEGIN { FS = ";" } ; { print $1}')
    rifStateB=$(sed -n "$2p" $APOS_RE_CONF | grep RIFSTATE2 | awk ' BEGIN { FS = "=" } ; { print $2}'| awk ' BEGIN { FS = ";" } ; { print $1}')
    if [ $rifStateA -eq 1 ] && [ $rifStateB -eq 1 ] ; then
      stateToReturn=$TRUE
    fi
  else
    apos_log "reliable network interface not defined"
    stateToReturn=$FALSE
  fi
  return $stateToReturn
}

#------------------------------------------------------------------------------#
function delete_rule() {
  cc_path="/opt/ap/apos/bin/clusterconf"
  cc_name="clusterconf"
	pushd ${cc_path} > /dev/null 2>&1
  for rule in "${rules[@]}"; do
    rule_id=$(./${cc_name} iptables --display | grep "${rule}" |awk -F" " '{print $1}')
    [ -z $rule_id ] && break 
    ./${cc_name} iptables --delete $rule_id
    [ $? -ne $TRUE ] && apos_abort "Deletion of iptable rule is failed"
  done
  popd > /dev/null 2>&1
  cluster_conf_reload
  [ $? -ne $TRUE ] && apos_abort "the iptables configuration went wrong!"
  # iptables restart to make the new rules effective
  /sbin/service iptables restart || apos_abort "failure while reloading iptables rules"

}

#------------------------------------------------------------------------------#
##
# BEGIN: Profile local handling
# /etc/profile.local file set up
AP_TYPE=$(apos_get_ap_type)
pushd $CFG_PATH &> /dev/null
if [ "AP1" == "$AP_TYPE" ]; then
  apos_check_and_call $CFG_PATH aposcfg_profile-local.sh
else
  apos_check_and_call $CFG_PATH aposcfg_profile-local_AP2.sh
fi
popd &> /dev/null
# END: Profile local handling
##

##
#  BEGIN: ip rules modification

if [ $(get_oam_access_attr) -eq 1 ]; then
	rules=(
"iptables all -A INPUT -p tcp --dport 830 -i bond1+ -j DROP"
"iptables all -A INPUT -p udp --dport 830 -i bond1+ -j DROP"
"iptables all -A INPUT -p tcp --dport 830 -i eth2 -j DROP"
"iptables all -A INPUT -p udp --dport 830 -i eth2 -j DROP"
)
  # Delete the rules from cluster.conf
  delete_rule
else
 rules=(
"iptables all -A INPUT -p tcp --dport 830 -i eth1 -j DROP"
"iptables all -A INPUT -p udp --dport 830 -i eth1 -j DROP"
"iptables all -A INPUT -p tcp --dport 830 -i eth2 -j DROP"
"iptables all -A INPUT -p udp --dport 830 -i eth2 -j DROP"
)
  # Delete the rules from cluster.conf
  delete_rule
fi

rules=''
if is_rif_defined; then
   rules=(
"iptables all -A INPUT -p tcp --dport 830 -i bond1 -j DROP"
"iptables all -A INPUT -p udp --dport 830 -i bond1 -j DROP"
"iptables all -A INPUT -p tcp --dport 830 -i eth2 -j DROP"
"iptables all -A INPUT -p udp --dport 830 -i eth2 -j DROP"
)
  # Delete the rules from cluster.conf
  delete_rule
fi
# END: ip rules modification
##

# R1A01 -> <NEXT_REVISION>
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R1A01
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A01"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
