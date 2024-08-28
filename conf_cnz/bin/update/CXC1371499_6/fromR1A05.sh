#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A05.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# -Tue Mar 21 2017 - Rajashekar Narla  (xcsrajn)
#       Fix fo HV60362
# - Wed Mar 15 2017 - Pratap reddy(xpraupp)
#   	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
SRC='/opt/ap/apos/etc/deploy'
CFG_PATH='/opt/ap/apos/conf'

##
# BEGIN: rsyslog configuration changes
SYSLOG_CONFIG_FILE='usr/lib/lde/config-management/apos_syslog-config'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${SYSLOG_CONFIG_FILE}" --to "/${SYSLOG_CONFIG_FILE}" || \
  apos_abort "failure while deploying syslog configuration file"
apos_servicemgmt restart rsyslog.service &>/dev/null || \
  apos_abort 'failure while restarting syslog service'
popd &>/dev/null
# END: rsyslog configuration changes
##

##
# BEGIN: smartd impacts
pushd $CFG_PATH &> /dev/null
apos_check_and_call $CFG_PATH apos_smartdisk.sh
popd &>/dev/null
# END: smartd impacts
##

##
# BEGIN: GRUB configuration fix
GRUB_CONFIG_FILE='usr/lib/lde/config-management/apos_grub-config'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${GRUB_CONFIG_FILE}" --to "/${GRUB_CONFIG_FILE}" || \
  apos_abort "failure while deploying grub configuration file"
popd &>/dev/null

# Moved at end the reload the cluster configuration on the current node
# to trigger apos_grub-config execution
#cluster config --reload &> /dev/null || \
#  apos_abort 'Failure while reloading cluster configuration'
# END:  GRUB configuration fix
##

##
# BEGIN: Fix for TR HV73989

# Instruction to convert "-ExecStartPre=/opt/..." to "ExecStartPre=-/opt/..."
/usr/bin/sed -i -r 's@^-(Exec[A-Za-z]+=)@\1-@g' /usr/lib/systemd/system/lde-iptables.service || \
  apos_abort 'failure while applying fix to lde-iptables.service'

# END: Fix for TR HV73989
##

##
# BEGIN: TR HV60632 FIX

tmp=$( mktemp --tmpdir apos_conf_iptables_XXXXX )
num_rules_mod=0
cc_path="/opt/ap/apos/bin/clusterconf"
cc_name="clusterconf"

if is_vAPG; then
  rules_todel=(
  "all -A INPUT -p tcp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i bond0 -j DROP"
  "all -A INPUT -p udp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i bond0 -j DROP"
  "all -A INPUT -p tcp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i bond0 -j DROP"
  "all -A INPUT -p udp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i bond0 -j DROP"
  )

  rules_toadd=(
  "all -A INPUT -p tcp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth5 -j DROP"
  "all -A INPUT -p udp -m multiport --dport 52000,52001,52002,52010,52011,52100,52101,52110,52111 -i eth5 -j DROP"
  "all -A INPUT -p tcp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth5 -j DROP"
  "all -A INPUT -p udp -m multiport --dport 5000,5001,5002,5010,5011,5100,5101,5110,5111 -i eth5 -j DROP"
  )

  pushd ${cc_path} > /dev/null 2>&1

  if [ ! -f ${tmp} ]; then
    apos_abort "unable to create a temporary file"
  fi

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

  ./${cc_name} iptables --display | tail -n +2 | cut -f2- | cut -d' ' -f2- > ${tmp} 2>&1
  for rule in "${rules_toadd[@]}"; do
    ispresent=$FALSE
    while read line; do
      if [ "${line}" = "${rule}" ]; then ispresent=$TRUE; break; fi
    done < "${tmp}"
    [ $ispresent -eq $FALSE ] && ./${cc_name} iptables --m_add ${rule} && (( num_rules_mod = $num_rules_mod  +1 ))
  done
  rm -f ${tmp}

  popd > /dev/null 2>&1
    
fi
# END: TR HV60632 FIX
##  

# BEGIN: Reload the cluster configuration on the current node
# to trigger apos_grub-config execution and reload the iptables
cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
# END: Reload the cluster configuration

# BEGIN: Reload the service units
apos_servicemgmt reload lde-iptables.service --type=service &>/dev/null || apos_abort 'failure while reloading system services'
# END: Reload the service units

# BEGIN: Restart the iptables service
apos_servicemgmt restart lde-iptables.service &>/dev/null || apos_abort 'failure while restarting lde-iptables.service' 
# END: Restart the iptables service

##
# BEGIN: OP#62 impacts

pushd $CFG_PATH &> /dev/null 
./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_22 --to /etc/ssh/sshd_config_22 
if [ $? -ne 0 ]; then 
  apos_abort 1 "failure while deploying \"sshd_config_22\" file" 
fi 

./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_830 --to /etc/ssh/sshd_config_830 
if [ $? -ne 0 ]; then 
  apos_abort 1 "failure while deploying \"sshd_config_830\" file" 
fi 
popd &>/dev/null 

# BEGIN: Restart the ssh target
apos_servicemgmt restart lde-sshd.target &>/dev/null || apos_abort 'failure while restarting lde-sshd target' 
# END: Restart the ssh target

# END: OP#62 impacts
##


##
# BEGIN: Fix Integrity issue observed in LSV05 TR HV74123

#deploying apos-drbd.sh files
DD_REPLICATION_TYPE=$(get_storage_type)

if [ "$DD_REPLICATION_TYPE" == "DRBD" ]; then
  pushd $CFG_PATH &> /dev/null
  [ ! -x apos_deploy.sh ] && apos_abort 1 '$CFG_PATH/apos_deploy.sh not found or not executable'
  ./apos_deploy.sh --from "$SRC/usr/lib/systemd/scripts/apos-drbd.sh" --to "/usr/lib/systemd/scripts/apos-drbd.sh"
  [ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of apos-drbd.sh file"

  popd &>/dev/null
fi

#deploying apos-recovery-conf.sh files
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
if [ "$HW_TYPE" == 'VM' ]; then
  pushd $CFG_PATH &> /dev/null
  [ ! -x apos_deploy.sh ] && apos_abort 1 '$CFG_PATH/apos_deploy.sh not found or not executable'
  ./apos_deploy.sh --from "$SRC/usr/lib/systemd/scripts/apos-recovery-conf.sh" --to "/usr/lib/systemd/scripts/apos-recovery-conf.sh"
  [ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of apos-recovery-conf.sh file"

  popd &>/dev/null
fi



# END: Fix Integrity issue observed in LSV05
##


# R1A05 -> R1A06
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_6 R1A06
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
