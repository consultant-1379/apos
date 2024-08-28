#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A04.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# -Thu Feb 23  2017 - Anjali M (XANJALI)
#        Fixed review comments.
# -Mon Feb 20  2017 - Yeswanth Vankayala (xyesvan) 
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC='/opt/ap/apos/etc/deploy'
HW_TYPE='/opt/ap/apos/conf/apos_hwtype.sh'
DD_REPLICATION_TYPE=$(get_storage_type)
LDE_CONFIG_MGMT='usr/lib/lde/config-management'
CMD_DRBDADM='/sbin/drbdadm'


function isMD() {
  [ "$DD_REPLICATION_TYPE" == "MD" ] && return $TRUE
  return $FALSE
}

function is10G(){
  local NETWORK_BW=''
  NETWORK_BW=$( $CMD_PARMTOOL get --item-list drbd_network_capacity 2>/dev/null | \
  awk -F'=' '{print $2}')
  [ -z "$NETWORK_BW" ] && NETWORK_BW='1G'

  [ "$NETWORK_BW" == '10G' ] && return $TRUE
  return $FALSE
}

# Get the Hypervisor type
HYPERVISOR=$( $HW_TYPE --verbose | grep "system-manufacturer" | awk -F"=" '{print $2}' | sed -e 's@^[[:space:]]*@@g' -e 's@^"@@g' -e 's@"$@@g' )
[ -z "$HYPERVISOR" ] && apos_abort 'Failed to fetch hypervisor type'


#BEGIN Deployment of hooks
pushd $CFG_PATH &> /dev/null
[ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/cluster/hooks/pre-installation.tar.gz" --to "/cluster/hooks/pre-installation.tar.gz" --exlo
./apos_deploy.sh --from "$SRC/cluster/hooks/after-booting-from-disk.tar.gz" --to "/cluster/hooks/after-booting-from-disk.tar.gz" --exlo
./apos_deploy.sh --from "$SRC/cluster/hooks/post-installation.tar.gz" --to "/cluster/hooks/post-installation.tar.gz" --exlo
popd &>/dev/null
#END Deployment of hooks

##
#BEGIN fix for TR HV39005
if [ "$DD_REPLICATION_TYPE" != "DRBD" ]; then
   drbd_file="/usr/lib/systemd/scripts/apos-drbd.sh"
   if [ -f "$drbd_file" ]; then
     /usr/bin/rm -f $drbd_file 2>/dev/null
     if [ $? -ne 0 ]; then
       apos_abort "Failed to remove the $drbd_file file"
     fi
  fi
fi
#END
##

#
# BEGIN: Deployment of apos_drbd-config file (according to system configuration)
if ! isMD; then
  # The apos_drbd-config file(s) must be deployed only 
  # in case of DRBD replication for data disk
  if ! is10G; then
    if ! is_vAPG; then
      pushd $CFG_PATH &> /dev/null
      ./apos_deploy.sh --from "$SRC/$LDE_CONFIG_MGMT/apos_drbd-config" --to "/$LDE_CONFIG_MGMT/apos_drbd-config"
    fi
  fi
  # Reload the cluster configuration on the current node 
  # to trigger apos_drbd-config execution
  cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'

  # Instruct drbd to use the new configuration
  $CMD_DRBDADM adjust drbd1 || apos_abort 'Failure while notifying DRBD about new configuration'
fi
# END  : Deployment of apos_drbd-config file (according to system configuration)
##

#BEGIN: updating apos_adhoc_templates  for virtual environment------------------------#
if is_vAPG;then
  if [[ "$HYPERVISOR" =~ .*openstack.* ]]; then

  this_id=$(</etc/cluster/nodes/this/id)
  peer_id=$(</etc/cluster/nodes/peer/id)
  hostname=$(</etc/cluster/nodes/this/hostname)
  peer_hostname=$(</etc/cluster/nodes/peer/hostname)

  node_name="AP-A"
  peer_nodename="AP-B"

  if [ "$this_id" -eq 2 ]; then
    node_name='AP-B'
    peer_nodename='AP-A'
  fi

  cmd_adhoc_template_mngr="$CFG_PATH/apos_adhoc_template_mgr.sh"
  storage_path='/storage/system/config/apos'
  adhoc_hot_template="${storage_path}/HEAT_${node_name}.yml"

  #status files
  status_file="$(apos_create_brf_folder clear)/.${hostname}_upgraded"
  peer_status_file="$(apos_create_brf_folder clear)/.${peer_hostname}_upgraded"

  # generated hot-template
  if [ -x "$cmd_adhoc_template_mngr" ]; then
   $cmd_adhoc_template_mngr --generate &>/dev/null
   if [ $? -eq 0 ]; then
     # create an temporary status file 
     # /storage/system/config/apos/HEAT_AP-[A/B].yml
     /usr/bin/touch $status_file  
     apos_log "New adhoc templates creation...OK"
   else
    apos_abort "New adhoc templates creation...Failed"
   fi
  else
    apos_abort "$cmd_adhoc_template_mngr file does not exists"
  fi

  # workaround for availability zone and APT TYPE
  #  as this data is missing from user_data file
  subs_string='{availability_zone_ap_substitute}'
  if grep -q $subs_string $adhoc_hot_template; then
    /usr/bin/sed -i -e "s/$subs_string/nova/g" $adhoc_hot_template
    [ $? -ne 0 ] && apos_abort " Failed to substitute availability_zone_ap in $adhoc_hot_template"
  else
    apos_log "availability_zone_ap_substitute variable does not exists in $adhoc_hot_template file"
  fi
  

  # update apt_type value to MSC
  subs_string='{apt_type_substitute}'
  if grep -q $subs_string $adhoc_hot_template; then
    /usr/bin/sed -i -e "s/$subs_string/MSC/g" $adhoc_hot_template
    [ $? -ne 0 ] && apos_abort "Failed to substitute apt_type in $adhoc_hot_template"
  else
    apos_log "apt_type_substitute variable does not exists in $adhoc_hot_template file"
  fi

  # try copy apos_adhoc_templates to nbi from 
  # active node once both the nodes are upgraded
  if [[ -f "$status_file" && -f "$peer_status_file" ]]; then
    /usr/bin/ssh $peer_hostname "$cmd_adhoc_template_mngr --copy-to-nbi  &> /dev/null; echo $?" 2> /dev/null
    removeExitCode=$?

    #clean up  temporary status files
    [ -f "$status_file" ] && /usr/bin/rm $status_file
    [ -f "$peer_status_file" ] && /usr/bin/rm $peer_status_file

    if [ "$removeExitCode" == $TRUE  ]; then
      apos_log "adhoc_hot_templates transferred succesfully to NBI path...OK"
    else
      apos_abort "Failed to transfer adhoc_hot_templates to NBI path"
    fi
  else
      apos_log "Not transferred files as upgradation is still in progress"
  fi
 fi
fi
#END  : updating apos_adhoc_templates  --------------------------------------------#

##
# BEGIN: improving troubleshooting users login phase
if [ "$(apos_get_ap_type)" != "$AP2" ]; then
  pushd $CFG_PATH &> /dev/null
  ./aposcfg_profile-local.sh
  if [ $? -ne 0 ]; then
    apos_abort "failure while executing \"aposcfg_profile-local.sh\""
  fi
  ./aposcfg_syncd-conf.sh
  if [ $? -ne 0 ]; then
    apos_abort "failure while executing \"aposcfg_syncd-conf.sh\""
  fi
  popd &> /dev/null
fi
# END: improving troubleshooting users login phase
##


## Manual Merge of Contribution coming from Avinash for 
#  - TLS 
#  - SSH -s support
## 
if [ -x /opt/com/util/com_config_tool ]; then
  DEST_DIR=$(/opt/com/util/com_config_tool location)
else
  DEST_DIR='/storage/system/config/com-apr9010443'
fi
DEST_DIR=$DEST_DIR/lib/comp

##
# BEGIN: ssh -s support impacts in APG 
pushd $CFG_PATH &> /dev/null
if [ "$(apos_get_ap_type)" == "$AP2" ]; then
  ./aposcfg_profile-local_AP2.sh
  if [ $? -ne 0 ]; then
    apos_abort 1 "failure while executing \"aposcfg_profile-local_AP2.sh\""
  fi
else
  ./aposcfg_profile-local.sh
  if [ $? -ne 0 ]; then
    apos_abort 1 "failure while executing \"aposcfg_profile-local.sh\""
  fi
fi

./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_22 --to /etc/ssh/sshd_config_22
if [ $? -ne 0 ]; then
  apos_abort 1 "failure while deploying \"sshd_config_22\" file"
fi

./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_830 --to /etc/ssh/sshd_config_830
if [ $? -ne 0 ]; then
  apos_abort 1 "failure while deploying \"sshd_config_830\" file"
fi

./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_sshd-config" --to "/usr/lib/lde/config-management/apos_sshd-config"
if [ $? -ne 0 ]; then
	apos_abort 1 "failure while deploying \"apos_sshd-config\" file"
fi

./apos_insserv.sh /usr/lib/lde/config-management/apos_sshd-config
if [ $? -ne 0 ]; then
	apos_abort "failure while creating symlink to file apos_sshd-config"
fi
stop_disable_sshdconfig
popd &>/dev/null

apos_servicemgmt enable lde-sshd@sshd_config_830.service &>/dev/null ||\
	apos_abort 'failure while enabling sshd_config_830 service'
apos_servicemgmt enable lde-sshd@sshd_config_22.service &>/dev/null || \
	apos_abort 'failure while enabling sshd_config_22 service'
apos_servicemgmt restart lde-sshd.target &>/dev/null ||\
	apos_abort 'failure while restarting lde-sshd target'
# END: ssh -s support impacts in APG
##

##
# BEGIN: TLS support 

pushd $CFG_PATH &> /dev/null
if [ -f "$DEST_DIR/libcom_tls_proxy.cfg" ]; then
 #Check if configuration already exist
  if ! grep -q '<tlsdManagement>true</tlsdManagement>' $DEST_DIR/libcom_tls_proxy.cfg;  then
    ./apos_deploy.sh --from $CFG_PATH/libcom_tls_proxy.cfg --to $DEST_DIR/libcom_tls_proxy.cfg
    if [ $? -ne 0 ]; then
      apos_abort 1 "failure while deploying libcom_tls_proxy.cfg"
    fi
  fi
else
  ./apos_deploy.sh --from $CFG_PATH/libcom_tls_proxy.cfg --to $DEST_DIR/libcom_tls_proxy.cfg
  if [ $? -ne 0 ]; then
    apos_abort 1 "failure while deploying libcom_tls_proxy.cfg"
  fi
fi

#deploy libcom_tlsd_manager.cfg
if [ -f "$DEST_DIR/libcom_tlsd_manager.cfg" ]; then
  #Check if configuration already exist
  if ! grep -q '<cliTlsPort>9830</cliTlsPort>' $DEST_DIR/libcom_tlsd_manager.cfg;  then
    ./apos_deploy.sh --from $CFG_PATH/libcom_tlsd_manager.cfg --to $DEST_DIR/libcom_tlsd_manager.cfg
    if [ $? -ne 0 ]; then
      apos_abort 1 "failure while deploying libcom_tlsd_manager.cfg"
    fi
  else
    apos_log "libcom_tlsd_manager.cfg already deployed"
  fi
else
  ./apos_deploy.sh --from $CFG_PATH/libcom_tlsd_manager.cfg --to $DEST_DIR/libcom_tlsd_manager.cfg
  if [ $? -ne 0 ]; then
    apos_abort 1 "failure while deploying libcom_tlsd_manager.cfg"
  fi
fi
popd &>/dev/null
# END: TLS support
##


# R1A05 -> R1A06
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_6 R1A05
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
