#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_iptables.sh
# Description:
#       A script to initialize the iptables.
# Note:
#       To be executed only on one node.
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Wed Apr 19 2023 - Koti Kiran Maddi (zktmoad)
#   Fix for TR IA38326
# - Wed Oct 28 2022 - Koti Kiran Maddi (zktmoad)
#   Fix for TR IA12117 
# - Wed Aug 03 2022 - Amrutha Padi (zpdxmrt)
#   Fix for TR HZ59046 
# - Tue Dec 1 2020 - Swapnika Baradi (xswapba)
#       Fix for TR HY37046
# - Wed Jun 17 2020 - Sindhuja Palla (xsinpal)
#       Fix for TR HY45047
# - Wed Jan 15 2020 - Pratap Reddy Uppada (xpraupp)
#       IPv6 impacts for virtual
# - Wed Oct 24 2018 - Pratap Reddy Uppada (xpraupp)
#       updated to reload cluster config on local node
# - Tue Mar 20 2017 - Raghavendra Koduri (xkodrag)
#       Support for GEP7
# - Tue Mar 20 2017 - Rajashekar Narla (xcsrajn)
#       Removal of unwanted rules for VM (HV60362).
# - Fri Jul 08 2016 - Alessio Cascone (ealocae)
#       Removal of rules for CPS mapping (HU92119).
# - Mon May 30 2016 - Claudio Elefante (xclaele)
#       FTP anonymous issue impacts.
# - Thu Apr 7 2016 - Antonio Buonocunto (EANBUON)
#       cps protection
# - Fri Nov 27 2015 - Antonio Buonocunto (EANBUON)
#       apos servicemgmt adaptation
# - Wed Sep 09 2015 - Francesco D'Errico (xfraerr)
#       Insert new rules for the BackPlane hardening (checks on bond0, eth3, eth4 and 10 Gb IP).
# - Fri May 02 2014 - Francesco Rainone (efrarai)
#       Fix for a bug that alternatively adds/removes iptables rules.
# - Thu Apr 23 2014 - Antonio Buonocunto (eanbuon)
#       Cableless impacts.
# - Wed Feb 26 2014 - Antonio Buonocunto (eanbuon) - Francesco Rainone (efrarai)
#       Disable ipv6.
# - Wed Dec 04 2013 - Gianluigi Crispino (xgiacri)
#   Added logic to consider Reliable Ethernet rules for restore.
# - Fri Nov 23 2012 - Paolo Palmieri (epaopal)
#       Improved to add rules only if not present.
# - Thu Nov 08 2012 - Paolo Palmieri (epaopal)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

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
    kill_after_try 3 30 360 "$lcc_name config -r" 2>/dev/null || apos_abort 1 'ERROR: Failed to reload cluster configuration'
  fi

  return $status
}

# Function to check if the reliable network configuration is defined
function is_rif_defined(){
  local stateToReturn=$FALSE
  APOS_RE_CONF="/cluster/storage/system/config/apos/apos_rif.conf"

  if [ -e $APOS_RE_CONF ]; then
    rifStateA=$(cat $APOS_RE_CONF |grep RIFSTATE1 | awk ' BEGIN { FS = "=" } ; { print $2}'| awk ' BEGIN { FS = ";" } ; { print $1}')
    rifStateB=$(sed -n "$2p" $APOS_RE_CONF |grep RIFSTATE2 | awk ' BEGIN { FS = "=" } ; { print $2}'| awk ' BEGIN { FS = ";" } ; { print $1}')
    if [ $rifStateA -eq 1 ] && [ $rifStateB -eq 1 ] ; then
      stateToReturn=$TRUE
    fi
  else
    apos_log "reliable network interface not defined"
    stateToReturn=$FALSE
  fi

  return $stateToReturn
}
iptables_del_reject() {
pushd ${cc_path} > /dev/null 2>&1
for PORT in 111 2049
  do
        for ETHERNET in eth7 eth8
        do
                ./${cc_name} iptables -D |grep "tcp \-\-dport $PORT" | grep tcp | grep "[[:space:]]${ETHERNET}" | grep REJECT> /dev/null
                if [ $? == 0 ]; then
                rule_del=$(./${cc_name} iptables --display | grep "tcp \-\-dport $PORT" | grep "[[:space:]]${ETHERNET}" | grep REJECT |awk -F" " '{print $1}')
                ./${cc_name} iptables --m_delete ${rule_del}
                fi
                ./${cc_name} ip6tables -D |grep "tcp \-\-dport $PORT" | grep tcp | grep "[[:space:]]${ETHERNET}" | grep REJECT> /dev/null
                if [ $? == 0 ]; then
                 rule6_del=$(./${cc_name} ip6tables --display | grep "tcp \-\-dport $PORT" | grep "[[:space:]]${ETHERNET}" | grep REJECT |awk -F" " '{print $1}')
                ./${cc_name} ip6tables --m_delete ${rule6_del}
		fi
	done
done
popd > /dev/null 2>&1
}
iptables_rules_nocable() {
  pushd ${cc_path} > /dev/null 2>&1

  local tmp=$( mktemp --tmpdir apos_conf_iptables_XXXXX )
  local num_rules_mod=0
  if [ -f ${tmp} ]; then
    ./${cc_name} iptables --display | tail -n +2 | cut -f2- | cut -d' ' -f2- > ${tmp} 2>&1
    [ $? -ne $TRUE ] && apos_abort "the clusterconf tool exits with error"
    rules=("${rules_nocable[@]}")
    rules_todel=("${rules_nocable[@]}")
    if is_vAPG; then
      unique_iptable_rules=( "${rules_VM_BackPlane[@]}" "${rules_BP_SSD_GEP[@]}" "${rules_ftp[@]}")
      rules=("${rules_no_rif[@]}" "${unique_iptable_rules[@]}" "${rules_VM_cust[@]}")
      rules_todel=("${rules_no_rif[@]}" "${unique_iptable_rules[@]}" "${rules_VM_cust[@]}")
    fi
    for rule in "${rules_todel[@]}"; do
        while read line; do
            if [ "${line}" = "${rule}" ]; then
                rule_id=$(./${cc_name} iptables --display | grep "${rule}" |awk -F" " '{print $1}')
                ./${cc_name} iptables --m_delete ${rule_id}
                (( num_rules_mod = $num_rules_mod  +1 ))
            fi
        done < "${tmp}"
    done
    ./${cc_name} iptables --display | tail -n +2 | cut -f2- | cut -d' ' -f2- > ${tmp} 2>&1
    for rule in "${rules[@]}"; do
        local ispresent=$FALSE
        while read line; do
            if [ "${line}" = "${rule}" ]; then ispresent=$TRUE; break; fi
        done < "${tmp}"
        [ $ispresent -eq $FALSE ] && ./${cc_name} iptables --m_add ${rule} && (( num_rules_mod = $num_rules_mod  +1 ))
    done
    rm ${tmp}
  else
    apos_abort "unable to create a temporary file"
  fi

  local tmp6=$( mktemp --tmpdir apos_conf_iptables_XXXXX )
  local num_rules6_mod=0
  if [ -f ${tmp6} ]; then
    ./${cc_name} ip6tables --display | tail -n +2 | cut -f2- | cut -d' ' -f2- > ${tmp6} 2>&1
    [ $? -ne $TRUE ] && apos_abort "the clusterconf tool exits with error"
    rules6=("${rules6_nocable[@]}")
    rules6_todel=("${rules6_nocable[@]}")
    if is_vAPG; then
      rules6=("${rules_no_rif[@]}" "${rules6_router[@]}" "${rules6_VM_cust[@]}")
      rules6_todel=("${rules_no_rif[@]}" "${rules6_router[@]}" "${rules6_VM_cust[@]}")
    fi

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
    rm ${tmp6}
  else
    apos_abort "unable to create a temporary file"
  fi

  popd > /dev/null 2>&1
  if [ $num_rules_mod != 0 ]; then
        cluster_conf_reload
        local ret_status=$?
        if [ $ret_status != 0 ]; then
                apos_abort "the iptables configuration went wrong!"
        fi

       # iptables restart to make the new rules effective
       apos_servicemgmt restart lde-iptables.service &>/dev/null || apos_abort "failure while reloading iptables rules"
  fi
}

iptables_rules_frontcable() {
  pushd ${cc_path} > /dev/null 2>&1

  local CMD_HWTYPE='/opt/ap/apos/conf/apos_hwtype.sh'
  local HW_TYPE=$( $CMD_HWTYPE)
  local tmp=$( mktemp --tmpdir apos_conf_iptables_XXXXX )
  local num_rules_mod=0
  if [ -f ${tmp} ]; then
    ./${cc_name} iptables --display | tail -n +2 | cut -f2- | cut -d' ' -f2- > ${tmp} 2>&1
    [ $? -ne $TRUE ] && apos_abort "the clusterconf tool exits with error"
    if is_rif_defined ; then
        rules=("${rules_with_rif[@]}" "${rules_eth2[@]}" "${rules_BackPlane[@]}")
        if [[ "$HW_TYPE" == "GEP5" || "$HW_TYPE" == "GEP7" ]]; then
                rules=("${rules[@]}" "${rules_BP_SSD_GEP[@]}")
        fi
        rules_todel=("${rules_no_rif[@]}")
    else
        rules=("${rules_no_rif[@]}" "${rules_eth2[@]}" "${rules_BackPlane[@]}")
        if [[ "$HW_TYPE" == "GEP5" || "$HW_TYPE" == "GEP7" ]]; then
                rules=("${rules[@]}" "${rules_BP_SSD_GEP[@]}")
        fi
                rules_todel=("${rules_with_rif[@]}")
    fi
    for rule in "${rules_todel[@]}"; do
        local ispresent=$FALSE
        while read line; do
            if [ "${line}" = "${rule}" ]; then
                rule_id=$(./${cc_name} iptables --display | grep "${rule}" |awk -F" " '{print $1}')
                ./${cc_name} iptables --m_delete ${rule_id}
                (( num_rules_mod = $num_rules_mod  +1 ))
            fi
        done < "${tmp}"
    done
    for rule in "${rules[@]}"; do
        local ispresent=$FALSE
        while read line; do
            if [ "${line}" = "${rule}" ]; then ispresent=$TRUE; break; fi
        done < "${tmp}"
        [ $ispresent -eq $FALSE ] && ./${cc_name} iptables --m_add ${rule} && (( num_rules_mod = $num_rules_mod  +1 ))
    done
    rm ${tmp}
  else
    apos_abort "unable to create a temporary file"
  fi

  local tmp6=$( mktemp --tmpdir apos_conf_iptables_XXXXX )
  local num_rules6_mod=0
  if [ -f ${tmp6} ]; then
    ./${cc_name} ip6tables --display | tail -n +2 | cut -f2- | cut -d' ' -f2- > ${tmp6} 2>&1
    [ $? -ne $TRUE ] && apos_abort "the clusterconf tool exits with error"
    if is_rif_defined ; then
        rules6=("${rules6_with_rif[@]}" "${rules6_eth2[@]}")
        rules6_todel=("${rules6_no_rif[@]}")
    else
        rules6=("${rules6_no_rif[@]}" "${rules6_eth2[@]}")
        rules6_todel=("${rules6_with_rif[@]}")
    fi
        for rule6 in "${rules6_todel[@]}"; do
        local ispresent=$FALSE
        while read line; do
            if [ "${line}" = "${rule6}" ]; then
                        rule6_id=$(./${cc_name} ip6tables --display | grep "${rule6}" |awk -F" " '{print $1}')
                        ./${cc_name} ip6tables --m_delete ${rule6_id}
                        (( num_rules6_mod = $num_rules6_mod  +1 ))
                        fi
        done < "${tmp6}"
    done
    for rule6 in "${rules6[@]}"; do
        local ispresent=$FALSE
        while read line; do
            if [ "${line}" = "${rule6}" ]; then ispresent=$TRUE; break; fi
        done < "${tmp6}"
        [ $ispresent -eq $FALSE ] && ./${cc_name} ip6tables --m_add ${rule6} && (( num_rules6_mod = $num_rules6_mod  +1 ))
    done
    rm ${tmp6}
  else
    apos_abort "unable to create a temporary file"
  fi

  popd > /dev/null 2>&1
  if [ $num_rules_mod != 0 ]; then
        cluster_conf_reload
        local ret_status=$?
        if [ $ret_status != 0 ]; then
                apos_abort "the iptables configuration went wrong!"
        fi

       # iptables restart to make the new rules effective
       apos_servicemgmt restart lde-iptables.service &>/dev/null || apos_abort "failure while reloading iptables rules"
  fi
}


		
			
#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|
#
main(){
local OAM_ACCESS=$(get_oam_param)
if is_vAPG; then
iptables_del_reject
fi
if [ "$OAM_ACCESS" = "NOCABLE" ]; then
  iptables_rules_nocable
else
  iptables_rules_frontcable
fi

}

# Common variables
cc_path="/opt/ap/apos/bin/clusterconf"
cc_name="clusterconf"

lcc_name="/usr/bin/cluster"

param="iptables"

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

rules6_no_rif=(
"all -A INPUT -i eth1 -j DROP"
"all -A OUTPUT -o eth1 -j DROP"
)
rules_with_rif=(
"all -A INPUT -p tcp --dport 67 -i bond1 -j DROP"
"all -A INPUT -p udp --dport 67 -i bond1 -j DROP"
"all -A INPUT -p tcp --dport 111 -i bond1 -j DROP"
"all -A INPUT -p udp --dport 111 -i bond1 -j DROP"
"all -A INPUT -p tcp --dport 161 -i bond1 -j DROP"
"all -A INPUT -p udp --dport 161 -i bond1 -j DROP"
"all -A INPUT -p tcp --dport 162 -i bond1 -j DROP"
"all -A INPUT -p udp --dport 162 -i bond1 -j DROP"
"all -A INPUT -p tcp --dport 831 -i bond1 -j DROP"
"all -A INPUT -p udp --dport 831 -i bond1 -j DROP"
"all -A INPUT -p tcp --dport 832 -i bond1 -j DROP"
"all -A INPUT -p udp --dport 832 -i bond1 -j DROP"
"all -A INPUT -p tcp --dport 833 -i bond1 -j DROP"
"all -A INPUT -p udp --dport 833 -i bond1 -j DROP"
"all -A INPUT -p tcp --dport 2049 -i bond1 -j DROP"
"all -A INPUT -p udp --dport 2049 -i bond1 -j DROP"
"all -A INPUT -p tcp --dport 7911 -i bond1 -j DROP"
)
rules6_with_rif=(
"all -A INPUT -i bond1 -j DROP"
"all -A OUTPUT -o bond1 -j DROP"
)
rules_eth2=(
"all -A INPUT -p tcp --dport 67 -i eth2 -j DROP"
"all -A INPUT -p udp --dport 67 -i eth2 -j DROP"
"all -A INPUT -p tcp --dport 111 -i eth2 -j DROP"
"all -A INPUT -p udp --dport 111 -i eth2 -j DROP"
"all -A INPUT -p tcp --dport 161 -i eth2 -j DROP"
"all -A INPUT -p udp --dport 161 -i eth2 -j DROP"
"all -A INPUT -p tcp --dport 162 -i eth2 -j DROP"
"all -A INPUT -p udp --dport 162 -i eth2 -j DROP"
"all -A INPUT -p tcp --dport 831 -i eth2 -j DROP"
"all -A INPUT -p udp --dport 831 -i eth2 -j DROP"
"all -A INPUT -p tcp --dport 832 -i eth2 -j DROP"
"all -A INPUT -p udp --dport 832 -i eth2 -j DROP"
"all -A INPUT -p tcp --dport 833 -i eth2 -j DROP"
"all -A INPUT -p udp --dport 833 -i eth2 -j DROP"
"all -A INPUT -p tcp --dport 2049 -i eth2 -j DROP"
"all -A INPUT -p udp --dport 2049 -i eth2 -j DROP"
"all -A INPUT -p tcp --dport 7911 -i eth2 -j DROP"
)
rules6_eth2=(
"all -A INPUT -i eth2 -j DROP"
"all -A OUTPUT -o eth2 -j DROP"
)
rules_nocable=(
"all -A INPUT -p tcp --dport 67 -i bond1+ -j DROP"
"all -A INPUT -p udp --dport 67 -i bond1+ -j DROP"
"all -A INPUT -p tcp --dport 111 -i bond1+ -j DROP"
"all -A INPUT -p udp --dport 111 -i bond1+ -j DROP"
"all -A INPUT -p tcp --dport 161 -i bond1+ -j DROP"
"all -A INPUT -p udp --dport 161 -i bond1+ -j DROP"
"all -A INPUT -p tcp --dport 162 -i bond1+ -j DROP"
"all -A INPUT -p udp --dport 162 -i bond1+ -j DROP"
"all -A INPUT -p tcp --dport 831 -i bond1+ -j DROP"
"all -A INPUT -p udp --dport 831 -i bond1+ -j DROP"
"all -A INPUT -p tcp --dport 832 -i bond1+ -j DROP"
"all -A INPUT -p udp --dport 832 -i bond1+ -j DROP"
"all -A INPUT -p tcp --dport 833 -i bond1+ -j DROP"
"all -A INPUT -p udp --dport 833 -i bond1+ -j DROP"
"all -A INPUT -p tcp --dport 2049 -i bond1+ -j DROP"
"all -A INPUT -p udp --dport 2049 -i bond1+ -j DROP"
"all -A INPUT -p tcp --dport 7911 -i bond1+ -j DROP"
"all -A INPUT -p udp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -d 169.254.213.0/24 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -d 169.254.213.0/24 -j DROP"
"all -A INPUT -p udp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -d 169.254.213.0/24 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -d 169.254.213.0/24 -j DROP"
)
rules6_nocable=(
"all -A INPUT -i bond1+ -j DROP"
"all -A OUTPUT -o bond1+ -j DROP"
)

rules_BackPlane=(
"all -A INPUT -p tcp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i bond0 -j DROP"
"all -A INPUT -p udp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i bond0 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth3 -j DROP"
"all -A INPUT -p udp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth3 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth4 -j DROP"
"all -A INPUT -p udp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth4 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i bond0 -j DROP"
"all -A INPUT -p udp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i bond0 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth3 -j DROP"
"all -A INPUT -p udp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth3 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth4 -j DROP"
"all -A INPUT -p udp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth4 -j DROP"
)

rules_VM_BackPlane=(
"all -A INPUT -p tcp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth5 -j DROP"
"all -A INPUT -p udp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth5 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth3 -j DROP"
"all -A INPUT -p udp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth3 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth4 -j DROP"
"all -A INPUT -p udp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth4 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth5 -j DROP"
"all -A INPUT -p udp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth5 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth3 -j DROP"
"all -A INPUT -p udp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth3 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth4 -j DROP"
"all -A INPUT -p udp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth4 -j DROP"
)


rules_BP_SSD_GEP=(
"all -A INPUT -p udp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -d 169.254.213.0/24 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -d 169.254.213.0/24 -j DROP"
"all -A INPUT -p udp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -d 169.254.213.0/24 -j DROP"
"all -A INPUT -p tcp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -d 169.254.213.0/24 -j DROP"
)

rules_ftp=(
"all -A INPUT -p tcp -d 192.168.169.0/24 --dport 21 -j REJECT"
"all -A INPUT -p tcp -d 192.168.170.0/24 --dport 21 -j REJECT"
)

rules6_router=(
"all -A INPUT -p icmpv6 --icmpv6-type router-advertisement -j DROP"
"all -A INPUT -p icmpv6 --icmpv6-type redirect -j DROP"
"all -A OUTPUT -p icmpv6 --icmpv6-type router-solicitation -j REJECT"
"all -A OUTPUT -p icmpv6 --icmpv6-type router-advertisement -j REJECT"
"all -A OUTPUT -p icmpv6 --icmpv6-type redirect -j REJECT"
)

rules_VM_cust=(
"all -A INPUT -p tcp --dport 2049 -i eth7 -j DROP"
"all -A INPUT -p udp --dport 2049 -i eth7 -j DROP"
"all -A INPUT -p tcp --dport 2049 -i eth8 -j DROP"
"all -A INPUT -p udp --dport 2049 -i eth8 -j DROP"
"all -A INPUT -p tcp --dport 111 -i eth7 -j DROP"
"all -A INPUT -p udp --dport 111 -i eth7 -j DROP"
"all -A INPUT -p tcp --dport 111 -i eth8 -j DROP"
"all -A INPUT -p udp --dport 111 -i eth8 -j DROP"
"all -A INPUT -p tcp --dport 161 -i eth7 -j DROP"
"all -A INPUT -p udp --dport 161 -i eth7 -j DROP"
"all -A INPUT -p tcp --dport 161 -i eth8 -j DROP"
"all -A INPUT -p udp --dport 161 -i eth8 -j DROP"
)

rules6_VM_cust=(
"all -A INPUT -p tcp --dport 2049 -i eth7 -j DROP"
"all -A INPUT -p udp --dport 2049 -i eth7 -j DROP"
"all -A INPUT -p tcp --dport 2049 -i eth8 -j DROP"
"all -A INPUT -p udp --dport 2049 -i eth8 -j DROP"
"all -A INPUT -p tcp --dport 111 -i eth7 -j DROP"
"all -A INPUT -p udp --dport 111 -i eth7 -j DROP"
"all -A INPUT -p tcp --dport 111 -i eth8 -j DROP"
"all -A INPUT -p udp --dport 111 -i eth8 -j DROP"
"all -A INPUT -p tcp --dport 161 -i eth7 -j DROP"
"all -A INPUT -p udp --dport 161 -i eth7 -j DROP"
"all -A INPUT -p tcp --dport 161 -i eth8 -j DROP"
"all -A INPUT -p udp --dport 161 -i eth8 -j DROP"
)

# Main
main "@"

apos_outro $0

exit $TRUE

# End of file

