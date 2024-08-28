#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A08.sh
# Description:
#       A script to update APOS_OSCONFBIN from the last version.
# Note:
#	None.
##
# Changelog:
# - Thu Mar 10 2016 - Sindhuja Palla (xsinpal)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

CMD_SED='/usr/bin/sed'
CMD_HWTYPE='/opt/ap/apos/conf/apos_hwtype.sh'
HW_TYPE=$($CMD_HWTYPE)
# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)

apos_intro $0

# R1A07 -> R1A08
#------------------------------------------------------------------------------#
function rollback_abort() {
  if ! cmp -s /cluster/etc/cluster.conf /boot/.cluster.conf; then
    apos_log 'rolling back changes to cluster.conf'
    cp /boot/.cluster.conf /cluster/etc/cluster.conf
  fi
  apos_abort "$1"
}
#------------------------------------------------------------------------------#
##
# BEGIN: /cluster/etc/cluster.conf configuration for sol addition

if [ "$HW_TYPE" == "GEP5" ];then
  pushd /opt/ap/apos/bin/clusterconf &>/dev/null
  if ! ./clusterconf network -D | grep -qE '^[[:space:]]+[0-9]+[[:space:]]+network[[:space:]]+sol_[ab][[:space:]]+'; then
    apos_log "Configuring SOL"
    ./clusterconf network --m_add sol_a 169.254.214.0/24 || rollback_abort "failure while executing clusterconf command"
    ./clusterconf network --m_add sol_b 169.254.215.0/24 || rollback_abort "failure while executing clusterconf command"
    ./clusterconf interface --m_add control eth3:3 alias || rollback_abort "failure while executing clusterconf command"
    ./clusterconf interface --m_add control eth4:3 alias || rollback_abort "failure while executing clusterconf command"
    $CMD_SED -i '/network sol_a / i \\n# The "sol_a" and the "sol_b" networks are for Serial Over Lan connection.' /cluster/etc/cluster.conf
    node_a_ip_a=169.254.214.1
    node_b_ip_a=169.254.214.2
    node_a_ip_b=169.254.215.1
    node_b_ip_b=169.254.215.2
    if [ "$AP_TYPE" == "AP2" ]; then
      node_a_ip_a=169.254.214.3
      node_b_ip_a=169.254.214.4
      node_a_ip_b=169.254.215.3
      node_b_ip_b=169.254.215.4
    fi
    ./clusterconf ip --m_add 1 eth3:3 sol_a $node_a_ip_a || rollback_abort "failure while executing clusterconf command"
    ./clusterconf ip --m_add 2 eth3:3 sol_a $node_b_ip_a || rollback_abort "failure while executing clusterconf command"
    ./clusterconf ip --m_add 1 eth4:3 sol_b $node_a_ip_b || rollback_abort "failure while executing clusterconf command"
    ./clusterconf ip --m_add 2 eth4:3 sol_b $node_b_ip_b || rollback_abort "failure while executing clusterconf command"
    $CMD_SED -i '/ip 1 eth3:3 / i \\n# SOL IP addresses' /cluster/etc/cluster.conf
    cluster config -v &>/dev/null || rollback_abort "failure while validating cluster.conf"
    cluster config -r &>/dev/null || rollback_abort "failure while reloading cluster.conf"
    apos_log "sol settings successfully applied"
  else
    apos_log "SOL already configured, reloading cluster.conf"
    cluster config -v &>/dev/null || rollback_abort "failure while validating cluster.conf"
    cluster config -r &>/dev/null || rollback_abort "failure while reloading cluster.conf"
  fi
  popd &>/dev/null

  for node_ip in $(cat /etc/cluster/nodes/this/ip/169.254.21[45].[1-4]/address); do
    interface=$(</etc/cluster/nodes/this/ip/${node_ip}/interface/name)
    network=$(</etc/cluster/nodes/this/ip/${node_ip}/network/name)
    network_prefix=$(</etc/cluster/nodes/this/networks/${network}/primary/network/prefix)
    if ! ip addr show dev ${interface} | grep -qP "[[:space:]]*inet[[:space:]]+${node_ip}/${network_prefix}[[:space:]]"; then
      apos_log "applying on-the-fly network configuration for SOL on interface ${interface}"
      ip addr add ${node_ip}/${network_prefix} dev ${interface} || apos_abort "failure while setting ${node_ip}/${network_prefix} on interface ${interface}"      
      ip link set ${interface} up || apos_abort "failure while enabling interface ${interface}"
    else
      apos_log "${node_ip}/${network_prefix} on interface ${interface} already set. Skipping"
    fi
  done

# END: /cluster/etc/cluster.conf configuration for sol
##
else
  apos_log "Not GEP5 configuration.SOL settings not required"
fi
#------------------------------------------------------------------------------#

# R1A08 -> R1A09
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1A09
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

