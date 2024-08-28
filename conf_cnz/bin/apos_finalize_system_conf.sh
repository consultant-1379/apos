#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_finalize_system_conf.sh
#
# Description:
#       A script to reconfigure system configuration parameters.
#
##
# Usage:
#       ./apos_finalize_system_conf.sh
##
# Changelog:
# - Thu May 22 2019 - Dharma Teja (xdhatej)
#       HX56291: applied retry mechnaism for fetching system_type attribute.
# - Tue Sep 18 2018 - Suman Kumar Sahu (zsahsum)
#	Removed update_pso_params
# - Thu Apr 12 2018 - Amit Varma (xamivar)
#       Removed the code for adhoc template solution.
# - Wed Mar 21 2018 - Yeswanth Vankayala (xyesvan)
#       drbd1 resume-sync added and wait_for_drbd0_to_sync removed 
# - Tue Jan 16 2018 - Prabhakaran Dayalan (xpraday)
#	    Handling LDE rpm Activation failed after faulty node recovery.
# - Fri Jul 28 2017 - Yeswanth Vankayala (xyesvan)
#       drbd0 sync fix for snrinit 
# - Wed Apr 12 2017 - Yeswanth Vankayala (xyesvan)
#       Adaptations for Single APG Images.
# - Fri May 05 2017 - Usha Manne (XUSHMAN)
#       Handling of additional custom networks during deploy phase.
# - Wed Jan 04 2017 - Antonio Buonocunto (EANBUON)
#       Handling of Dynamic MAC address
# - Mon Nov 14 2016 - Franco D'Ambrosio (EFRADAM)
#       Modified the methods to fetch deployment parameters
# - Wed Aug 31 2016 - Neeraj Kasula(xneekas)
#       Spillover TS user:added add_default_tsuser function
# - Mon July 25 2016 - Raghavendra Rao K (xkodrag)
#       Added support for single node recovery using adhoc tempaltes
# - Wed May 04 2016 - Pratap Reddy (xpraupp)
#       Applied smart campaign impacts
# - Tue Apr 12 2016 - Pratap Reddy (xpraupp)
#       TR FIX:HU70993 and included compute_resource_objects function 
# - Fri Jan 22 2016 - Pratap Reddy (xpraupp)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

# script-wide variables
node_id=$(get_node_id)

#-------------------------------------------------------------------------------
function abort() {
  local rCode=$1
  local MESSAGE="$2"
  echo -e "Aborting ($rCode): $MESSAGE" >&2
  apos_abort $rCode "$MESSAGE"
}

#-------------------------------------------------------------------------------
function usage() {
  echo 'apos_finalize_system_conf.sh'
  echo 'A script to finalize system configurations'
  echo
  echo 'Usage:    apos_finalize_system_conf.sh [--interactive]'
  echo
}

#-------------------------------------------------------------------------------
function update_cluster_config() {
  # Set local mac addresses in /cluster/etc/cluster.conf
  if [ $SIMULATED_ENV -eq $FALSE ]; then 
    add_custom_interfaces_in_cluster_conf cluster || abort 1 "failure while adding addtional custom interfaces in cluster.conf"
    set_local_macs_in_cluster_conf cluster || abort 1 "failure while setting local mac addresses in cluster.conf"
  fi

  # Set ip addresses in /cluster/etc/cluster.conf
  set_ips_in_cluster_conf cluster || abort 1 "failure while setting ip addresses in cluster.conf"
  
  # reload of cluster.conf (for mac address handling)
  /usr/bin/cluster config --reload || abort 1 "failure while reloading cluster configuration"
  
  return $TRUE
}

#-------------------------------------------------------------------------------
function update_imm_params() {
  # NetworkConfiguration object configuration in IMM
  if [ -x /opt/ap/apos/conf/apos_models_conf.sh ]; then
    /opt/ap/apos/conf/apos_models_conf.sh
    if [ $? -ne 0 ]; then
      abort 1 "\"apos_models_conf.sh\" exited with non-zero return code"
    fi
  else
    abort 1 'apos_models_conf.sh not found or not executable'
  fi
}

#-------------------------------------------------------------------------------
function wait_for_cmw_status(){
  apos_log "Waiting for cmw status.."
  local TIME_OUT=900 # 15 mins
  local COUNT=0

  while [[ $COUNT -lt $TIME_OUT ]]
  do
    if [[ "$(/opt/coremw/bin/cmw-status node app sg su comp si csiass)" == "Status OK" ]]; then
      break
    else
      sleep 1
      ((COUNT ++))
    fi
  done
  [ $COUNT -eq $TIME_OUT ] && abort 1 "CoreMW status failed"
  
  apos_log "leaving wait_for_cmw_status"

}

#-------------------------------------------------------------------------------
function unlock_this_node() {

  local timeout=900
  local su="safSu=SC-${node_id},safSg=2N,safApp=ERIC-apg.nbi.aggregation.service"
   /usr/bin/amf-adm -t $timeout unlock-in $su || apos_log "snrint:unlock-in [$su] failed. exiting"
   /usr/bin/amf-adm -t $timeout unlock $su || apos_log "snrint:unlock [$su] failed. exiting"
   sleep 1
   
  # unlock no-red su's
  for su in $(/usr/bin/amf-state su | grep "safSu=SC-${node_id},safSg=NWA,safApp=ERIC-apg*" | sort); do
    /usr/bin/amf-adm -t $timeout unlock-in $su || apos_log "snrint:unlock-in [$su] failed. exiting"
    /usr/bin/amf-adm -t $timeout unlock $su || apos_log "snrint:unlock [$su] failed. exiting"
    usleep 500000
  done 

  # wait for cmw to settle-down
  wait_for_cmw_status
}

#-------------------------------------------------------------------------------
function set_tsuser_properties() {
  local SSH_LOGIN_FILE='/cluster/etc/login.allow'
  local expiry=1
  local TS_USER='ts_user'

  if [ -x /opt/ap/apos/bin/usermgmt/usermgmt ]; then
    USERADD="/opt/ap/apos/bin/usermgmt/usermgmt user add --global"
    USERMOD="/opt/ap/apos/bin/usermgmt/usermgmt user modify"
  else
    apos_abort "usermgmt not found executable"
  fi

  # verify, if ts_user is already defined or not on the node
  /usr/bin/getent passwd $TS_USER &>/dev/null
  if [ $? -ne 0 ]; then 
    apos_abort "ts_user does not exist on the node"
  fi

  # setting default password to "ts_user1@"
  echo  "$TS_USER:ts_user1@" | /usr/sbin/chpasswd 2>/dev/null
  if [ $? -eq 0 ]; then
    /usr/bin/passwd -e "$TS_USER" 2>/dev/null || apos_abort "Failed to force ts_user to set new password"
  fi

  # set account expiry to 1 day
  local old_date=$(date +"%y-%m-%d %H:%M:%S")
  local new_date=$(date -d "$old_date $expiry day" +%y-%m-%d)
  /usr/bin/chage -E $new_date "$TS_USER" || apos_abort "Failed to set expiry information for ts_user"

  # Adding ts_user to login.allow file
  echo "$TS_USER all" >>${SSH_LOGIN_FILE}
}

#-------------------------------------------------------------------------------
function cleanup() {
  if is_deploy_phase || is_snr_phase ; then
    # remove the config_stage file
    if [ -f "$STAGE_FILE" ]; then
      /bin/rm -f $STAGE_FILE || abort 1 "Failed to remove configuration stage file"
    else
      abort 1 "config_stage file not Found"
    fi

    #removing recovery file
    if [ -f $SNRINT_REBUILD_INPROGRESS ]; then
      /bin/rm -f $SNRINT_REBUILD_INPROGRESS || abort 1 "Failed to remove $SNRINT_REBUILD_INPROGRESS after snr"
    fi
  fi
    
  apos_log "leaving cleanup"
}

#-------------------------------------------------------------------------------
function confirm_cluster_reboot() {
  local CMD=''
  local rCode=1
  while [ "$CMD" != "y" ] && [ "$CMD" != "n" ]; do
    echo -e "\nCluster reboot is required to update NBI configurations !!!"
    echo -e "Are you sure you want to perform cluster reboot:"
    echo -en "[y=yes, n=no]?: "
    read CMD
  done
  [ "$CMD" == 'y' ] && rCode=0
  return $rCode
}

#-------------------------------------------------------------------------------
function update_installation_conf() {
  local local_file=/boot/.installation.conf
  local cluster_file=/cluster/etc/installation.conf
  # both nodes need to update local installation.conf
  update_boot_disk_in $local_file || abort 1 "failure while updating boot disk in $local_file"
  remove_data_disk_from $local_file || abort 1 "failure while removing data disk from $local_file"
  # only Node A is meant to update cluster installation.conf
  if [ $node_id -eq 1 ]; then
    update_boot_disk_in $cluster_file || abort 1 "failure while updating boot disk in $cluster_file"
    remove_data_disk_from $cluster_file || abort 1 "failure while removing data disk from $cluster_file"
  fi
}

# Since, in the image-based deployment cases, system disk in installation.conf
# is set to comply with the build server environment, we need to update the
# bd-sdb path with the current boot disk.
function update_boot_disk_in() {
  local file="$1"
  if [ ! -w "$file" ]; then
    abort 1 "file $file not found or not readable"
  fi
  local bootdisk=$(readlink /dev/disk_boot)
  if [ -z "$bootdisk" ]; then
    abort 1 "can't retrieve current boot disk"
  fi
  /usr/bin/sed -r -i "s@^([[:space:]]*option[[:space:]]+bd-sdb[[:space:]]+path[[:space:]]*=).*@\1${bootdisk}@g" $file
  if [ $? -ne "$TRUE" ]; then
    abort 1 "failure while updating boot disk in $file"
  fi
}

# Since, in the image-based deployment cases, data disk in installation.conf
# is set to comply with the build server environment, we need to delete the
# bd-sdc entry (and all related partitions: eri-data-part, eri-meta-part).
function remove_data_disk_from() {
  local file="$1"
  if [ ! -w "$file" ]; then
    abort 1 "file $file not found or not readable"
  fi
  /usr/bin/sed -r -i '/((bd-sdc)|(eri-data-part)|(eri-meta-part))/ d' /cluster/etc/installation.conf $file
  if [ $? -ne "$TRUE" ]; then
    abort 1 "failure while removing data disk entries from $file"
  fi
}

#-------------------------------------------------------------------------------
function finalize_deploy_configuration() {
  # 'SIMULATED_ENV' variable set to TRUE if it is a SIMULATED platform.
  # Initially this variable set to FALSE. Check the type of platform
  # (i.e SIMULATED/NON-SIMULATED) by using variable.
  is_SIMULATED && SIMULATED_ENV=$TRUE
  # Update cluster configuration
  update_cluster_config
  
  # Update installation.conf
  update_installation_conf

  if [ "$node_id" -eq 1 ]; then
    # Update IMM parameters
    update_imm_params

    # set properties for ts_user
    # set_tsuser_properties
		 
    #New function to define AXE-DEF VLAN, which was defined by CS service earlier.
    define_axe_def_vlan
  fi
  
  # Both the nodes are UP, reload of cluster.conf to synch up local file system
  /usr/bin/cluster config --reload || abort 1 "failure while reloading cluster configuration"

  if [ $SIMULATED_ENV -eq $FALSE ]; then
    # AP VMs ComputeResource objects
    if [ -x /opt/ap/apos/conf/apos_crmconf.sh ];then
      /opt/ap/apos/conf/apos_crmconf.sh
      if [ $? -ne 0 ];then
        apos_abort 1 "Failure while executing apos_crmconf.sh"
      fi
    else
      apos_abort 1 "Script apos_crmconf.sh not found"
    fi
  fi
  
  #cleanup
  cleanup   
}

#------------------------------------------------------------------------------- 
function sync_rpms() { 
  apos_log "(enter) sync_rpms -->" 
  local cmd_cluster='/usr/bin/cluster'
  apos_log "rpm sync in progress..." 
  if ! $cmd_cluster rpm --sync --node ${node_id} &>/dev/null; then 
      apos_abort 'rpm sync on node ${node_id} failed' 
  fi 
  apos_log "rpm sync in progress... done" 
  
  apos_log "(exit) sync_rpms <--" 
}
 
#------------------------------------------------------------------------------- 
function resume_drbd_sync() { 
  apos_log "(enter) resume_drbd_sync -->" 
  local cmd_drbdadm='/sbin/drbdadm'

  apos_log 'applying resume-sync on drbd1...'
  if ! $cmd_drbdadm resume-sync drbd1 &>/dev/null; then 
    apos_log 'applying resume-sync on drbd1... failed'
  else 
    apos_log 'applying resume-sync on drbd1... success'
  fi
  apos_log "(exit) resume_drbd_sync <--" 
}

#-------------------------------------------------------------------------------
function finalize_snr_configuration() {
  apos_log "entering finalize_snr_configuration"

  # update cluster configuration
  update_cluster_config

  # unlock this node
  unlock_this_node

  #delete existing computer resource for this node  
  delete_compute_resource

  wait_for_cmw_status

  # AP VMs ComputeResource objects
  if [ -x /opt/ap/apos/conf/apos_crmconf.sh ];then
    /opt/ap/apos/conf/apos_crmconf.sh
    if [ $? -ne 0 ];then
      apos_abort 1 "Failure while executing apos_crmconf.sh"
    fi
  fi

  # sync cluster rpms 
  sync_rpms
    
  #cleanup
  cleanup 

  # resume-sync drbd1 (optional)
  resume_drbd_sync 

  # reboot-node
  apos_log "apos_recovery completed succesfully rebooting the node"
  reboot_node
  
  apos_log "Leaving finalize_snr_configuration"
}

#-------------------------------------------------------------------------------
function parse_cmdline(){
    # check if the cmd is invoked with option
    [ $# -eq 0 ] && return $TRUE

    local LONG_OPTIONS='help interactive'
    $CMD_GETOPT --quiet --quiet-output --longoptions="$LONG_OPTIONS" -- "$@"
    EXIT_CODE=$?
    [ $EXIT_CODE -ne $TRUE ] && usage && abort 1 "Command line parameter error"

    local ARGS="$@"
    eval set -- "$ARGS"

    while [ $# -gt 0 ]; do
        case "$1" in
            --interactive)
                [ $OPT_INTERACT -eq $TRUE ] && usage && abort 1 " -i option repeated"
                OPT_INTERACT=$TRUE
                shift
                ;;
            --help)
                usage && exit $TRUE
                ;;
            *)
                abort 1 "unrecognized option ($1)"
                ;;
        esac
    shift
    done
}

function delete_compute_resource() {
apos_log "entering delete_compute_resource"

  # Here roleId for Node1 and Node2 are fixed
  local roleId='20011'
  if [ $node_id -eq 2 ]; then
    roleId='20012'
    wait_for_cmw_status
  fi
  
  for cr_obj in $(immfind -c AxeEquipmentComputeResource); do
    cr_roleID=$(immlist -a crRoleId $cr_obj | awk -F "=" '{print $2}' 2>/dev/null)
    [ $? -ne 0 ] &&  apos_abort 1 "ERROR failed to fetch roleID for  $cr_obj" 
    [ -z $cr_roleID ] && apos_abort 1 "Error in fetching cr_roleID  $cr_obj"
    if [ "$cr_roleID" == "$roleId" ]; then 
      node_prev_uid=$(echo $cr_obj | cut -d '=' -f 2 | cut -d ',' -f 1)
      immcfg -d $cr_obj
      break
    fi
  done
  
  apos_log "leaving delete_compute_resource"
}

#-----------------------------------------------------------------------------
# This function defines AXE-DEF vlan in MCP environment
#-----------------------------------------------------------------------------
function define_axe_def_vlan(){
  apos_log "BEGIN Defining AXE-DEF vlan"
  
  local system_type=''
  local MI_PATH="/cluster/mi/installation"
  local CMD_LOGGER="/bin/logger"
  local CMD_PARMTOOL="/opt/ap/apos/bin/parmtool/parmtool"

  system_type=$( $CMD_PARMTOOL get --item-list system_type 2>/dev/null | \
  awk -F'=' '{print $2}')
  $CMD_LOGGER "system_type value after executing the parmtool command is $system_type"
  if [ -z "$system_type" ]; then
	system_type=$( cat $MI_PATH/system_type)
	$CMD_LOGGER "system_type value after searching in MI_PATH is $system_type"
	if [ -z "$system_type" ]; then
		$CMD_LOGGER "Retrying for fetching system_type value with sleep 10sec"
		sleep 10
		 system_type=$( $CMD_PARMTOOL get --item-list system_type 2>/dev/null | \
  awk -F'=' '{print $2}')
		$CMD_LOGGER "system_type value after retrying is $system_type"
	fi		
  fi
  [ -z "$system_type" ] && apos_abort 1 "System type parameter not found!"

  if [ "$system_type" == "SCP" ];then
   apos_log "SCP environment: AXE-DEF vlan definition not applicable"
   return 0; 
  else
   local IMM_CFG="/usr/bin/immcfg"
   local VLAN_CLASS="AxeEquipmentVlan"
   local NET_ADDRESS="networkAddress"
   local NETMASK="netmask"
   local NAME="name"
   local STACK="stack"
   local VLAN_ID="vlanId"
   local VLAN_CATEGORY="vlanCategoryId=1,AxeEquipmentequipmentMId=1"
   local ACS_BIN_DIR="/cluster/storage/system/config/acs_csbin"
   local IMM_FIND="/usr/bin/immfind"
   local IMM_LIST="/usr/bin/immlist"
   local VLAN_FILE="vlan_list"

   CMD_DEF="$IMM_CFG -c $VLAN_CLASS -a $NET_ADDRESS=169.254.211.0 -a $NETMASK=255.255.255.0 -a $NAME=AXE-DEF -a $STACK=1 $VLAN_ID=AXE-DEF,$VLAN_CATEGORY"
   kill_after_try 5 5 6 $CMD_DEF 2>/dev/null || apos_abort 1 'VLAN Table Population Failed'

   if [ ! -d "$ACS_BIN_DIR" ];then
     mkdir $ACS_BIN_DIR > /dev/null  2>&1
   fi

   $IMM_FIND -c $VLAN_CLASS | xargs -i $IMM_LIST {} > $ACS_BIN_DIR/$VLAN_FILE
   if [ $? -eq 0 ];then
     apos_log "Updation of AXE-DEF vlan information in $ACS_BIN_DIR/$VLAN_FILE successful"
   else
     apos_log "Failed to update AXE-DEF vlan information in $ACS_BIN_DIR/$VLAN_FILE"
   fi
  fi
 
  apos_log "END Defining AXE-DEF vlan"

}

#-----------------------------------------------------------------------------
function reboot_node(){
  local hostname=$( cat /etc/cluster/nodes/this/hostname)
  local cmd_cmw_reboot='/opt/coremw/bin/cmw-node-reboot'

  $cmd_cmw_reboot $hostname &> /dev/null
  if [ $? -ne 0 ];then
    apos_abort 1  "Failed to reboot the node $HOSTNAME "
  fi

  # wait for reboot to happen
  while :
  do
    sleep 5
  done
}

##### M A I N #####
OPT_INTERACT=$FALSE
CMD_GETOPT='/usr/bin/getopt'
CMD_GETINFO='/opt/ap/apos/bin/gi/apos_getinfo'
SIMULATED_ENV=$FALSE

apos_log "BEGIN: apos_finalize_system_conf"

parse_cmdline "$@"

if is_system_configuration_allowed; then
  if is_dnr_phase; then
    # fetch parameters from the peer node
    echo "DNR PHASE"
  elif is_snr_phase; then
    # fetch parameters from the peer node
    apos_log 'snr-phase configuration is in progress...'
    finalize_snr_configuration
  elif is_deploy_phase; then
    apos_log 'deploy-phase configuration is in progress...'
    finalize_deploy_configuration
  fi
fi

apos_log "END: apos_finalize_system_conf"

exit $TRUE

# End of file
