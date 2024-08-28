#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A06.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1A06.
# Note:
#	None.
##
# Changelog:
# - Wed Jun 24 2015 - Pratap Reddy Uppada(XPRAUPP)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

SRC='/opt/ap/apos/etc/deploy'
CFG_PATH='/opt/ap/apos/conf'
CLUSTER_CONF_FILE='/cluster/etc/cluster.conf'
# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)

#------------------------------------------------------------------------------#
cluster_conf_reload() {
  local lcc_name="/usr/bin/cluster"
  $lcc_name config -v &>/dev/null
  local status=$?

  if [ $status -ne $TRUE ]; then
    echo -e "\nSyntax error cluster.conf configuration"
  else
    $lcc_name config -r -a
    status=$?
  fi

  return $status
}
#------------------------------------------------------------------------------#

# R1A06 --> R1A07
#------------------------------------------------------------------------------#

##
# BEGIN: Fix TR HT82796
if [ "$AP2" == "$AP_TYPE" ]; then
  apos_log "AP2 node, check if the misconfiguration is present in the cluser.conf"
  grep -E "^#.*WORKAROUND BEGIN" $CLUSTER_CONF_FILE
  if [ $? -eq 0 ]; then 
    apos_log "Misconfiguration present. Apply the fix"
    sed -i -e '/^#.*WORKAROUND BEGIN/d' \
					-e '/# uncomment following line as soon as LDEwS will fix the related TR/d' \
    	   	-e 's/^#\(ip 2 mvl2 debug 192.168.200.1\)/\1/' \
    	   	-e '/^#.*WORKAROUND END/d' $CLUSTER_CONF_FILE
    [ $? -ne $TRUE ] && apos_abort "cluster.conf manipulation went wrong!"

    cluster_conf_reload
    [ $? -ne $TRUE ] && apos_abort "the cluster.conf reload went wrong!"
    apos_log "Update of cluster.conf success!!!" 
  else
    apos_log "Misconfiguration not present, skip the fix"
  fi  

  ifconfig | grep -q mvl2 
  if [ $? -ne 0 ]; then 
    ip addr add 192.168.200.1/24 dev mvl2
    [ $? -ne $TRUE ] && apos_abort "Configuration of mvl2 went wrong!"
    ip link set mvl2 up
    [ $? -ne $TRUE ] && apos_abort "Enabling of mvl2 interface went wrong!"
    apos_log "Enabling of mvl2 interface success!!!" 
  else
    apos_log "Skip enabling of mvl2 interface"
  fi

else
  apos_log "AP1 node, skip fix of TR HT82796"
fi

# END: fix TR HT82796
##

#------------------------------------------------------------------------------#

# R1A06 -> R1A07
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R1A07
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A07"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
