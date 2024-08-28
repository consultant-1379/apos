#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:  apos_3PP_remove_present_in_lde.sh
#       
# Description:
#       A script to remove APG 3PP rpms which are already integrated as part of LDEwS
# Note:
#       Invoked by apos_ext plugin on both the Nodes of APG.
##
# Usage:
#       Used during APG Upgrade.
# Output:
#       None.
##
# Changelog:
# - Thu Aug 29 2021 - Sowjanya GVL (XSOWGVL)
#   First version.

. /opt/ap/apos/conf/apos_common.sh
apos_intro $0
THIS_ID=$(</etc/cluster/nodes/this/id)
VERSION=$(lde-info  | grep -i Numeric | awk -F ' ' '{print $3}' | awk -F '.' '{print $1"."$2}')

cd /cluster/rpms
libnghttp_rpm=$(ls |grep -i libnghttp)
libgobject_rpm=$(ls |grep -i libgobject)
libsgutil_rpm=$(ls |grep -i libsgutil)
libnettle_rpm=$(ls |grep -i libnettle)
libhog_rpm=$(ls |grep -i libhogweed)
libp11_rpm=$(ls |grep -i libp11)
libopen_vm_tools_rpm=$(ls |grep -i open-vm-tools)
libvmtools0_rpm=$(ls |grep -i libvmtools0)

cd -

#3PP rpms list which are already integrated by LDEwS
RPM_LIST_4_16=(
$libnghttp_rpm
$libgobject_rpm
$libsgutil_rpm
$libnettle_rpm
$libhog_rpm
$libp11_rpm
)

RPM_LIST_4_18=(
$libp11_rpm
$libnghttp_rpm
$libnettle_rpm
$libhog_rpm
$libvmtools0_rpm
$libopen_vm_tools_rpm
)


pre_check() {
  apos_log "Running pre-check...."
  local id=$(cat /etc/cluster/nodes/this/id)
  if [ $id -eq $THIS_ID ]; then
    apos_log "pre-check OK!!..."
  else
    apos_log "Failed pre-check, please run the script locally"
    apos_log "example: if you remove rpm on SC-2, please run script on SC-2"
    apos_abort 'per-check failure while trying to remove APG 3PP rpms'
  fi
}

die_and_rollback() {
  apos_log "FAILED operation...."
  apos_log "Rolling back..."
  cluster rpm -a $rpm_file_name -n ${THIS_ID}
}


update_rpm_conf() {
  apos_log "Updating RPM Conf...."
  echo "APPLICATION ${rpm_syntax} ${rpm_file_name} ACTIVATED" >> $rpm_conf
}

check_rpm_conf() {
  apos_log "Checking RPM config...."
  grep "$rpm_name" $rpm_conf
  if [ $? -eq 1 ]; then
    apos_log "RPM does not exist, start updating rpm conf...."
    update_rpm_conf
  else
    apos_log "RPM exist in rpm conf, OK...."
  fi
}


start_procedure() {
  rpm_file_name=$1
  rpm_path=/cluster/rpms/${rpm_file_name}
  rpm_syntax=$(rpm -qp $rpm_path --nosignature --qf "%{NAME} %{VERSION}-%{RELEASE} $RPM\n")
  rpm_name=$(echo $rpm_syntax | awk '{print $1}')
  rpm_revision=$(echo $rpm_syntax | awk '{print $2}')
  pre_check
  rpm_conf=/etc/rpm_${THIS_ID}.conf
  check_rpm_conf
  apos_log "Removing RPM $rpm_name ...."
  cluster rpm -r ${rpm_file_name} -n ${THIS_ID} || die_and_rollback
  apos_log "Activate RPM $rpm_name ...."
  cluster rpm -A -n ${THIS_ID} || die_and_rollback

return 0
}

invoke() {
  if [[ -n "$VERSION" && "$VERSION" == '4.16' ]];then
	for j in "${RPM_LIST_4_16[@]}"; do
  		apos_log rpm to be removed on $THIS_ID node is $j
		start_procedure $j
	done
  elif [[ -n "$VERSION" && "$VERSION" == '4.18' ]];then
	for j in "${RPM_LIST_4_18[@]}"; do
                apos_log rpm to be removed on $THIS_ID node is $j
                start_procedure $j
	done
  else
	apos_log "no action needed to remove 3pp rpm"
  fi
return 0
}

# _____________________
#|    _ _   _  .  _    |
#|   | ) ) (_| | | )   |
#|_____________________|
# Here begins the "main" function...
invoke
apos_outro $0
exit $TRUE

