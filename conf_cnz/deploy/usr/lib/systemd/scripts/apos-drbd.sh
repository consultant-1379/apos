#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos-drbd.sh
# Description:
#       A script to start APOS drbd deamon.
# Note:
#       The present script is executed during the start/stop phase of the
#       apos-drbd.service
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Wed Mar 21 2018 - Yeswanth Vankayala (xyesvan)
#   drbd1 sync fix
# - Wed Nov 20 2017 - Furquan Ullah (XFURULL)
#	Rework to align code.
# - Wed Nov 07 2017 - Avinash Gundlapally/Pranshu Sinha (xavigun/xpransi)
#	changes done to adopt SLES 12SP2 changes.
# - Sat Jul 29 2017 - Yeswanth Vankayala (xyesvan)
#       drbd0 sync fix for snrinit in ephermeral storage
# - Mon July 25 2016 - Raghavendra Rao K (xkodrag)
#       Added support for single node recovery using adhoc tempaltes
# - Fri Mar 18 2016 - PratapReddy Uppada (xpraupp)
#       Including vAPZ changes
# - Thu Jan 21 2016 - Antonio Nicoletti (eantnic) - Crescenzo Malvone (ecremal)
#       First version.
##

# Load the APOS common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

resource='drbd1'
SYSTEM_DISK='/dev/eri_disk'
CMD_RAIDMGR='/opt/ap/apos/bin/raidmgr'
CMD_DRBDADM='/sbin/drbdadm'
CMD_CAT='/usr/bin/cat'
CMD_SSH='/usr/bin/ssh'
CMD_GREP='/usr/bin/grep'
CMD_AWK='/usr/bin/awk'
CMD_RM='/usr/bin/rm'
PROC_DRBD='/proc/drbd'
APG_META_CONVERT_SCRIPT='/usr/lib/systemd/scripts/apg-drbd-meta-convert'
CMD_DRBD_STATUS='/opt/ap/apos/conf/apos_drbd_status'
if [ "$(</etc/cluster/installation/distro)" = "SLES" ]; then
  LVM_FILTER='filter = [ "a|drbd0|vd[a-z].*|sd[a-z].*|", "r|eri_thumbdrive.*|" ]'
fi

function enable_vg() {
  ERI_VG="/dev/eri-data-vg"
  vgchange -ay $ERI_VG 2>/dev/null
  return $?
}

function is_connected(){
  local PEER_NODE=$(</etc/cluster/nodes/peer/hostname)
  #in snr phase peer node will be in active state.
  if is_snr_phase; then
    local_role=$($CMD_DRBD_STATUS role drbd1 local)
    peer_role=$($CMD_DRBD_STATUS role drbd1 peer)
    repstate=$($CMD_DRBD_STATUS repstate drbd1)

    if [ "$local_role" == "Secondary" ] && [ "$peer_role" == "Primary" ] && [ "$repstate" == "SyncTarget" ]; then
      return $TRUE
    fi
  elif [ $($CMD_DRBDADM status "$resource" | $CMD_GREP "$resource role:Secondary" | wc -l ) -eq 1 ] && [ $($CMD_DRBDADM status "$resource" | $CMD_GREP "$PEER_NODE role:Primary" | wc -l ) -eq 1 ]
  then 
    return $TRUE
  fi

  return $FALSE
}

function wait_for_drbd0_sync(){
  apos_log "(enter) apos_drbd: wait_for_drbd0_sync"
  local count=0
  local disk_status=''

  while true
  do
    disk_status=$( $CMD_DRBDADM dstate drbd0)
    if [[ "$disk_status" =~ "Inconsistent/UpToDate" ]]; then
      if [[ $count -eq 0 || $count -eq 12 ]]; then # print msg in 60 seconds
        apos_log "apos_drbd: waiting for drbd0 sync to complete"
        count=0
      fi
      
      /bin/sleep 5
      ((count = count + 1))
      continue
    fi

    if [[ "$disk_status" != "UpToDate/UpToDate" ]]; then
      apos_log "apos_drbd: disk status found ($disk_status), exiting"    
    else
      apos_log "apos_drbd: drbd0 sync completed"
    fi

    # break otherwise
    break
  done

  apos_log "(exit)  apos_drbd: wait_for_drbd0_sync"
}

function wait_for_drbd1_to_join(){
  apos_log "apos_drbd: waiting for drbd1 to join"
  while ! is_connected ;do
    /bin/sleep 5
  done
  apos_log "apos_drbd: drbd1 is now joined"
}

function configure_drdb1() {

  [ !  -b $SYSTEM_DISK ] && apos_abort 1 "$SYSTEM_DISK is not a block device"
  SYSTEM_DISK="$( /usr/bin/readlink -f $SYSTEM_DISK)"

  NODE_ID=$(cat /etc/cluster/nodes/this/id)
  [ -z "$NODE_ID" ] && apos_abort "Node ID not found"

  if ! /sbin/lvs | grep 'eri-data-lv' ; then 
    [ ! -x $CMD_RAIDMGR ] && apos_abort 1 "raidmgr: no execute permissions found"
    # On SC-2-1, partition the data disk atatched to VM
    # then create lvm on data partition
    OPTS='--part --lvm --force'
    $CMD_RAIDMGR "$OPTS"
    [ $? -ne 0 ] && apos_abort 1 "Failed to create partitions for data disk"
  else
   return $TRUE
  fi 

  if is_deploy_phase ; then
    # format the drdb1
    if [ "$NODE_ID" -eq 1 ]; then
      # wait for drbd1 is to be active on other node
      wait_for_drbd1_to_join

      OPTS='--format --mount'
      $CMD_RAIDMGR $OPTS || apos_abort 1 "Failure while formatting drbd1 resource"
    fi

    if [ "$NODE_ID" -eq 2 ]; then
      # if second node boots up early then it shall wait for the first node
      # to join the cluster and let it format the drbd1.
      wait_for_drbd1_to_join
    fi

  elif is_snr_phase; then
    wait_for_drbd1_to_join
  fi
  
}

unmount()
{
  # FIXME: not sure why  '/data/opt/ap/nbi_fuse' is mounted on com_fuse_module
  com_mount='/data/opt/ap/nbi_fuse'
  umount $com_mount &>/dev/null

  # proceed with remaining mounts
  mounts=$(sort < /proc/mounts | $CMD_GREP $($CMD_DRBDADM sh-dev $resource) | $CMD_AWK '{print $2}')
  for mount in $mounts
  do
    if ! umount $mount &>/dev/null; then
      apos_abort 1 "Failed to unmount mountpoint:\"$mount\""
    fi
  done
  return $TRUE
}

case $1 in
  start)
    MESSAGE="Starting apos drbd"
    echo $MESSAGE
    apos_log "$MESSAGE"

    # Update the lvm.conf file before we start
    sed -i "/^\s*filter/ c \    $LVM_FILTER" /etc/lvm/lvm.conf
    if is_snr_phase; then
      apos_log "DRBD1: snr phase detected"   
      if ! is_SIMULATED; then 
        # wait for drbd0 sync before configuring drbd1
        wait_for_drbd0_sync
        configure_drdb1
      fi
    fi
 
    #if drbd-overview | grep ":$resource" | grep -q 'Unconfigured'; then
    $CMD_DRBDADM status "$resource" &>/dev/null
    if [ $? -ne 0 ]; then 
      # Make sure the LVM configuration is updated before we start
      /sbin/vgscan &>/dev/null
      [ $? -ne $TRUE ] && apos_abort "failure while scanning for volume groups"
      
      enable_vg      
      [ $? -ne $TRUE ] && apos_abort "failure while activating volume group"
      
      local_node=$(</etc/cluster/nodes/this/hostname)
      peer_node=$(</etc/cluster/nodes/peer/hostname)
      LOCAL_PROC_DRBD_VERSION=$($CMD_CAT $PROC_DRBD | $CMD_GREP -i version | $CMD_AWK -F "version: " '{print $2}' | $CMD_AWK -F "." '{print $1}')
      PEER_PROC_DRBD_VERSION=$($CMD_SSH $peer_node $CMD_CAT $PROC_DRBD | $CMD_GREP -i version | $CMD_AWK -F "version: " '{print $2}' | $CMD_AWK -F "." '{print $1}')


      peer_id=$(($(</etc/cluster/nodes/this/id)&1))
      LOCAL_NODE_DRBD_VERSION=''
      PEER_NODE_DRBD_VERSION=''
	v09_get_gi_cmd="drbdmeta 99 v09 /dev/eri-meta-part 0 get-gi --node-id=$peer_id"
        if ! $v09_get_gi_cmd &>/dev/null; then
	  LOCAL_NODE_DRBD_VERSION="8"
	else
	  LOCAL_NODE_DRBD_VERSION="9"
	fi
	
	if [ "$PEER_PROC_DRBD_VERSION" == 9 ]; then
	  v09_get_gi_peer_cmd="$CMD_SSH $peer_node drbdmeta 99 v09 /dev/eri-meta-part 0 get-gi --node-id=$peer_id"
            if ! $v09_get_gi_peer_cmd &>/dev/null; then
	      PEER_NODE_DRBD_VERSION="8"
	    else
	      PEER_NODE_DRBD_VERSION="9"
            fi
        else
          PEER_NODE_DRBD_VERSION="8"
        fi
	
      if [ "$LOCAL_NODE_DRBD_VERSION" != "9" ]; then
        if [ "$PEER_NODE_DRBD_VERSION" == "8" ]; then
          "$APG_META_CONVERT_SCRIPT" v09 drbd1
          if [ $? -ne $TRUE ]; then
            apos_abort "Failed to find or convert DRBD meta data"
          fi
        elif [ "$PEER_NODE_DRBD_VERSION" == "9" ]; then
            v09_write_md_cmd="drbdmeta --force 99 v09 /dev/eri-meta-part 0 create-md 1"
            if ! $v09_write_md_cmd; then
              apos_abort "Failed to apply DRBD metadata v09"
            fi
            #peer_node_BUID=$($CMD_SSH $peer_node drbdmeta 99 v09 /dev/eri-meta-part 0 get-gi --node-id=$peer_id | $CMD_AWK -F: '{print $2}')
            peer_node_BUID=$($CMD_SSH $peer_node drbdadm show-gi drbd1 | $CMD_GREP [A-Z0-9]:[A-Z0-9]:[A-Z0-9]:[A-Z0-9]:* | $CMD_AWK -F: '{print $2}')
            apos_log "$peer_node_BUID is the value"
            v09_set_gi_cmd="drbdmeta --force 99 v09 /dev/eri-meta-part 0 set-gi --node-id=$peer_id $peer_node_BUID:::"
            if ! $v09_set_gi_cmd; then
              # not fatal (sync > full sync), just log
              apos_log "WARNING: Failed to write DRBD bitmap UUID"
            fi
        fi
      fi
      $CMD_DRBDADM up $resource &>/dev/null
        [ $? -ne $TRUE ] && apos_abort "failure while bringing up drbd resource \"$resource\""
    fi

    ## During the snrphase, puase-sync is applied to let all the application start normally. 
    ## if not set, nfs hang was seen due to heavy load on nfs.
    ## resume-sync is applied from apos_finalize_system_conf.sh
    if is_system_configuration_allowed; then
      if is_snr_phase ; then
        if ! is_SIMULATED; then
          timeout=5; count=0
          while [ $count -le $timeout ] 
          do
            if ! $CMD_DRBDADM pause-sync drbd1 &>/dev/null; then   
              apos_log "apos_drbd: pause-sync on drbd1 failed, trying again"

              if [ $count -eq $timeout ]; then
                apos_abort "apos_drbd: pause-sync on drbd1 failed"
              fi
              sleep 2
              ((count = count + 1))
            else
              apos_log "apos_drbd: pause-sync on drbd1 success" 
              break
            fi    
          done
        fi
      fi
    fi
    ##
    ;;
  stop)
    # check if drbd is already stopped.
    # stop shall be trigered on system reboot only. Manual stop is not allowed
    # and, in the case it happens, node will go for reboot trigerred by HA Agent
    MESSAGE="Stopping apos drbd"
    echo $MESSAGE
    apos_log "$MESSAGE"
    $CMD_DRBDADM status "$resource" &>/dev/null
    if [ $? -eq 0 ]; then
      if unmount; then
        $CMD_DRBDADM down $resource &>/dev/null
        [ $? -ne $TRUE ] && apos_abort "failure while bringing down drbd resource \"$resource\""
      fi
    fi
    apos_log "prep to drbd1 v08"
    if [ -f /boot/create_md_v08 ]; then
      apos_log "file exist and trying to downgrade"
      # rm -f /boot/create_md_v08
      apos_log "Prepare for downgrading, convert metadata v09 -> v08 to match DRBD version"
      $CMD_DRBDADM apply-al drbd1 &> /dev/null
      if ! $APG_META_CONVERT_SCRIPT v08 drbd1; then
        apos_abort "Failed to find or convert DRBD meta data"
      fi
    fi

    ;;
  *)
    apos_log "usupported command $1"
    exit $TRUE
    ;;
esac

apos_outro $0
exit $TRUE
