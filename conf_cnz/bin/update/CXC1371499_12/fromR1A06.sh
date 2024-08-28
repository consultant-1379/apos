#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
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
# Tue Jun 17 - Sindhuja Palla (xsinpal)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"
LDE_CONFIG_MGMT='usr/lib/lde/config-management'
CLU_HOOKS_PATH='/cluster/hooks/'

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

# Function to modify IPv6 rules from cluster.conf file
modify_iptable_rules() {

  pushd ${cc_path} > /dev/null 2>&1

 local tmp6=$( mktemp --tmpdir apos_conf_iptables_XXXXX )
 rules6=("${rules6_router[@]}")
 rules6_todel=("${rules6_router[@]}")
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
  if [[ $num_rules6_mod != 0 ]]; then
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

 rm ${tmp6}

}

########### MAIN ##############

cc_path="/opt/ap/apos/bin/clusterconf"
cc_name="clusterconf"
cluster_conf_file="/cluster/etc/cluster.conf"

lcc_name="/usr/bin/cluster"
rules6_router=(
"all -A INPUT -p icmpv6 --icmpv6-type router-advertisement -j DROP"
"all -A INPUT -p icmpv6 --icmpv6-type redirect -j DROP"
"all -A OUTPUT -p icmpv6 --icmpv6-type router-solicitation -j REJECT"
"all -A OUTPUT -p icmpv6 --icmpv6-type router-advertisement -j REJECT"
"all -A OUTPUT -p icmpv6 --icmpv6-type redirect -j REJECT"
)

if is_vAPG; then
  modify_iptable_rules
fi

# BEGIN: updating DNR hooks for GEP5 board replacement
pushd $CFG_PATH &>/dev/null
    ./apos_deploy.sh --from "$SRC/$CLU_HOOKS_PATH/after-booting-from-disk.tar.gz" --to "$CLU_HOOKS_PATH/after-booting-from-disk.tar.gz"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying after-booting-from-disk.tar.gz file"
    fi

        ./apos_deploy.sh --from "$SRC/$CLU_HOOKS_PATH/post-installation.tar.gz" --to "$CLU_HOOKS_PATH/post-installation.tar.gz"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying post-installation.tar.gz file"
    fi

    ./apos_deploy.sh --from "$SRC/$CLU_HOOKS_PATH/pre-installation.tar.gz" --to "$CLU_HOOKS_PATH/pre-installation.tar.gz"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying pre-installation.tar.gz file"
    fi
popd &>/dev/null
# END: DNR hooks deploy

# R1A06 -> R1A07
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_12 R1A07
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
