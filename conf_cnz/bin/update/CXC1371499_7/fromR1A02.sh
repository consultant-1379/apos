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
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# R1A02 -> R1A03

#Common variables
# BEGIN: Fix TR HV86639
if grep -Pq 'all -A INPUT -p tcp -d 192\.168\.1((69)|(70))\.0/24 --dport 21 -j DROP' /cluster/etc/cluster.conf; then
  apos_log 'converting iptables DROP rules on port 21 to REJECT'
  sed -i -r 's@(all -A INPUT -p tcp -d 192\.168\.1((69)|(70))\.0\/24 --dport 21 -j) DROP@\1 REJECT@g' /cluster/etc/cluster.conf
  if [ $? -eq $TRUE ]; then
    apos_log 'done'
    cluster config --reload --all &>/dev/null || apos_abort 'failure while reloading cluster.conf'
    apos_servicemgmt restart lde-iptables.service >/dev/null || apos_abort 'failure while restarting iptables service'
  else
    apos_abort 'failure while converting iptables DROP rules on port 21 to REJECT'
  fi
else
  apos_log 'iptables DROP rules on port 21 not present: skipping configuration'
fi
# END: Fix TR HV86639 
##


# R1A02 -> R1A03
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_7 R1A03
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
