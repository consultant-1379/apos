#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A01.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# -  Tue Mar 24 2020 - Yeswanth Vankayala (xyesvan)
#      fix for apos_ip-config integrity issue
# -  Fri Mar 13 2020 - Anjali M (xanjali)
#       First version.
# - Thu Mar 15 2020 - Suman kumar sahu (zsahsum)
#       For introduction of new HLR scaling role
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"
LDE_CONFIG_MGMT='usr/lib/lde/config-management'

# Function to reload the cluster conf file
cluster_conf_reload() {
  $lcc_name config -v &>/dev/null
  local status=$?
  if [ $status -ne $TRUE ]; then
    echo -e "\nSyntax error in the new iptables configuration"
  else
    # Work around to mitigate race condition during restore.
    # When a cluster reload is executed simultaneously
    # such reload will fail. Below is WA to mitigate this case.
    kill_after_try 3 30 30 "$lcc_name config -r" 2>/dev/null || apos_abort 1 'ERROR: Failed to reload cluster configuration'
  fi

  return $status
}

# Function to modify IPv4/IPv6 rules from cluster.conf file
modify_iptable_rules() {

  pushd ${cc_path} > /dev/null 2>&1

  local tmp=$( mktemp --tmpdir apos_conf_iptables_XXXXX )
  rules_todel=("${rules6_no_rif[@]}")
  local num_rules_mod=0

  if [ -f ${tmp} ]; then
    ./${cc_name} iptables --display | tail -n +2 | cut -f2- | cut -d' ' -f2- > ${tmp} 2>&1
    [ $? -ne $TRUE ] && apos_abort "the clusterconf tool exits with error"

    for rule in "${rules_todel[@]}"; do
      while read line; do
        if [ "${line}" = "${rule}" ]; then
          rule_id=$(./${cc_name} iptables --display | grep "${rule}" |awk -F" " '{print $1}')
          ./${cc_name} iptables --m_delete ${rule_id}
          (( num_rules_mod = $num_rules_mod  +1 ))
        fi
      done < "${tmp}"
    done
 else
    apos_abort "unable to create a temporary file for modifying iptables rules"
  fi

 local tmp6=$( mktemp --tmpdir apos_conf_iptables_XXXXX )
 rules6=("${rules_no_rif[@]}")
 rules6_todel=("${rules6_no_rif[@]}")
 local num_rules6_mod=0

  if [ -f ${tmp6} ]; then
    ./${cc_name} ip6tables --display | tail -n +2 | cut -f2- | cut -d' ' -f2- > ${tmp6} 2>&1
    [ $? -ne $TRUE ] && apos_abort "the clusterconf tool exits with error"

    for rule6 in "${rules6_todel[@]}"; do
      while read line; do
        if [ "${line}" = "${rule6}" ]; then
          rule6_id=$(./${cc_name} ip6tables --display | grep "${rule6}" |awk -F" " '{print $1}')
          ./${cc_name} ip6tables --m_delete ${rule6_id}
          (( num_rules6_mod = $num_rules6_mod  +1 ))
        fi
       done < "${tmp6}"
    done

  ./${cc_name} ip6tables --display | tail -n +2 | cut -f2- | cut -d' ' -f2- > ${tmp6} 2>&1
  for rule6 in "${rules6[@]}"; do
    local ispresent=$FALSE
    while read line; do
      if [ "${line}" = "${rule6}" ]; then ispresent=$TRUE; break; fi
    done < "${tmp6}"
      [ $ispresent -eq $FALSE ] && ./${cc_name} ip6tables --m_add ${rule6} && (( num_rules6_mod = $num_rules6_mod  +1 ))
    done
  else
    apos_abort "unable to create a temporary file for modifying iptables rules"
  fi

  popd > /dev/null 2>&1
  if [[ $num_rules_mod != 0 || $num_rules6_mod != 0 ]]; then
    cluster_conf_reload
    local ret_status=$?
    if [ $ret_status != 0 ]; then
      echo -e "the iptables configuration went wrong!"
    fi

    # iptables restart to make the new rules effective
    apos_servicemgmt restart lde-iptables.service &>/dev/null || echo -e  "failure while reloading iptables rules"
  else
      echo "No Rules to modify"
  fi

 rm ${tmp}
 rm ${tmp6}

}

########### MAIN ##############

cc_path="/opt/ap/apos/bin/clusterconf"
cc_name="clusterconf"
cluster_conf_file="/cluster/etc/cluster.conf"

lcc_name="/usr/bin/cluster"

rules6_no_rif=(
"all -A INPUT -i eth1 -j DROP"
"all -A OUTPUT -o eth1 -j DROP"
)

rules_no_rif=(
"all -A INPUT -p tcp --dport 67 -i eth1 -j DROP"
"all -A INPUT -p udp --dport 67 -i eth1 -j DROP"
"all -A INPUT -p tcp --dport 111 -i eth1 -j DROP"
"all -A INPUT -p udp --dport 111 -i eth1 -j DROP"
"all -A INPUT -p tcp --dport 161 -i eth1 -j DROP"
"all -A INPUT -p udp --dport 161 -i eth1 -j DROP"
"all -A INPUT -p tcp --dport 162 -i eth1 -j DROP"
"all -A INPUT -p udp --dport 162 -i eth1 -j DROP"
"all -A INPUT -p tcp --dport 831 -i eth1 -j DROP"
"all -A INPUT -p udp --dport 831 -i eth1 -j DROP"
"all -A INPUT -p tcp --dport 832 -i eth1 -j DROP"
"all -A INPUT -p udp --dport 832 -i eth1 -j DROP"
"all -A INPUT -p tcp --dport 833 -i eth1 -j DROP"
"all -A INPUT -p udp --dport 833 -i eth1 -j DROP"
"all -A INPUT -p tcp --dport 2049 -i eth1 -j DROP"
"all -A INPUT -p udp --dport 2049 -i eth1 -j DROP"
"all -A INPUT -p tcp --dport 7911 -i eth1 -j DROP"
)

if is_vAPG; then
  modify_iptable_rules
fi


#------------------------------------------------------------------------------#
# BEGIN: Introduction of new HLR scaling role
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH aposcfg_axe_sysroles.sh
popd &>/dev/null
# END:  Introduction of new HLR scaling role
#------------------------------------------------------------------------------#

# BEGIN: apos_ip-config script configuration
pushd $CFG_PATH &> /dev/null
[ ! -x ./apos_deploy.sh ] && apos_abort 1 "$CFG_PATH/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/$LDE_CONFIG_MGMT/apos_ip-config" --to "/$LDE_CONFIG_MGMT/apos_ip-config"
[ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of apos_ip-config file"
popd &> /dev/null

cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
# END: apos_ip-config script configuration
##

# R1A01 -> R1A02
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_12 R1A02
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
