#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos-recovery-conf.sh
# Description:
# This script is invoked from apos-recovery-conf.service
# This script is used during the single node recovery procedure
# when the faulty node need requires to rebuild from the golden image.
# 
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Friday  Sep 28 2018 - Pranshu Sinha (xpransi)
#   Changed to adapt for SWM2.0
# - Thursday  June 16 2016 - Raghavendra Rao Koduri (xkodrag)
#     First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

#this file is created on healthy node during recovery
rebuild_progress='/opt/ap/apos/bin/.snrinit.rebuild'
rhost=$(</etc/cluster/nodes/peer/hostname)

#commands
# ------------------------------------------------------------------------
cmd_touch='/usr/bin/touch'
cmd_hwtype='/opt/ap/apos/conf/apos_hwtype.sh'
cmd_drbdadm='/sbin/drbdadm'
cmd_snrinit_rebuild='/opt/ap/apos/conf/apos_snrinit_rebuild.sh'
cmd_rm='/usr/bin/rm'
cmd_reboot='/sbin/reboot'
cmd_ping='/bin/ping'
cmd_ssh='/usr/bin/ssh'
cmd_ls='/usr/bin/ls'
P_DIR='/opt/ap/apos/bin'
REBUILD_INFO='.snrinit.rebuild'

#------------------------------------------------------------------------
function modprobe_drbd() {

  apos_log "snrinit: executing /sbin/modprobe drbd;"
  #loading drbd module
  if ! /sbin/modprobe drbd; then
    apos_abort 1 "snrinit: modprobe drbd failed"
  fi
}

#------------------------------------------------------------------------
function is_rebuild_inprogress() {

  # we can come here due to following reasons.
  #  1. faulty node reboots itself during the recovery process.
  #  2. healthy-node initiates faulty node reboot due to 
  #     non administrative reboot of healthy-node during the faulty
  #     node recovery process.
  # In both the cases, client connection shall be skipped.

  if is_snr_phase; then 
    apos_log "snrinit: rebuild is already in progress"
    return $TRUE
  fi
  kill_after_try 3 1 2 $cmd_ssh $rhost "$cmd_ls $P_DIR/$REBUILD_INFO >/dev/null"
  if [ $? -eq 0 ];  then 
    apos_log "Starting rebuild recovery client"
    # start client
    $cmd_snrinit_rebuild --start-client
    if [ $? -eq 0 ]; then
      $cmd_touch $SNRINT_REBUILD_INPROGRESS
      apos_log "snrinit: client received response"
      return $TRUE
    fi
  fi
  return $FALSE
}


#------------------------------------------------------------------------
function reboot_self(){
  apos_log "snrinit: initiating reboot"

  $cmd_reboot &>/dev/null
  
  # wait for ever till the node is actually down
  while :
  do
    sleep 5
  done
}

#------------------------------------------------------------------------
function create_md(){

  apos_log "snrinit: flushing drbd0 metadata (create-md drbd0)"
  local ecode
  #erases drbd0 meta-data
  $cmd_drbdadm create-md drbd0 << COMMANDS
yes
yes
COMMANDS
  
  ecode=$?
  if [ $ecode -ne 0 ]; then
    apos_log "snrinit: create-md drbd0 failed with error code ($ecode)"
    reboot_self
  fi

  apos_log "snrinit: create-md successful"
  return $TRUE
}

#------------------------------------------------------------------------
function install_node() {
  apos_log "install node started"
  
  if is_rebuild_inprogress; then
  
    apos_log "snrint: single node recovery detected"    
    #load drbd module
    #modprobe_drbd

    #flush drbd0 metadata 
    #create_md
  else
    apos_log "initial deployment detected"
  fi
    
  return $TRUE
}

#------------------------------------------------------------------------
# local version of isvAPG. not sure that this solution should address 
# vmware and simap recovery process.
function isvAPG(){
  local HW_TYPE=$( $cmd_hwtype --verbose | grep 'system-manufacturer' | awk -F '=' '{print $2}')
  if [[ "$HW_TYPE" =~ ^openstack.* ]]; then
    # vmware and simap case may need to be handled differently?
    return $TRUE
  fi
  
  return $FALSE
}

#------------------------------------------------------------------------
function ping_peer(){

  apos_log "snrinit: ping peer attemepts= $1"
  local ping_attempts=$1
  local ping_interval=1
  #fetch peer node id & ip
  peer_id=$(</etc/cluster/nodes/peer/id)
  peer_ip=$(</etc/cluster/nodes/all/$peer_id/networks/internal/primary/address)
  
  local cmd_ping="$cmd_ping -c 1 -W 1 $peer_ip"

  try $ping_attempts $ping_interval $cmd_ping &> /dev/null
  if [ $? -eq 0 ]; then
    return $TRUE
  fi

  return $FALSE
}

#------------------------------------------------------------------------
function wait_for_reboot(){
  local attempts=10
  if ping_peer $attempts -eq 0; then
    apos_log 'snrinit: faulty node is rebooted now'
  else
    apos_log 'WARNING (snrinit):faulty is node still rechable'
  fi
}

#------------------------------------------------------------------------
function recover_faulty_node() {
    
  # Steps to recover:
  # 1. check if the recovery was in progress
  # 2. if not, nothing to do and exit the function call.
  # 3. if recovery is in progress, create /boot/.snrinit.rebuildinprogress
  # 4. reboot the faulty node
  # 5. wait for the fault
  
  apos_log "snrinit: faulty node recovery started" 
  local attempts=5
 
  if ping_peer $attempts ; then
    apos_log "snrinit: creating temporary rebuild file($SNRINT_REBUILD_INPROGRESS) on faulty node"
    kill_after_try 3 1 2 $cmd_ssh $rhost "$cmd_touch $SNRINT_REBUILD_INPROGRESS >/dev/null"
    if [ $? -eq 0 ]; then 
      apos_log "snrinit: issuing fauly node reboot over ssh"            
      kill_after_try 3 1 2 $cmd_ssh $rhost "$cmd_reboot --force >/dev/null &"
      if [ $? -eq 0 ]; then 
        wait_for_reboot
      else    
        apos_log "WARNING (snrinit): $cmd_reboot failed on $rhost"
      fi
    else
      apos_log "WARNING (snrinit): $cmd_touch $SNRINT_REBUILD_INPROGRESS failed on $rhost"
    fi    
  else
    apos_log "WARNING (snrinit): $rhost is not reachable"
  fi
  
  #remove .snrinit.rebuild file in healthy node
  [ -f $rebuild_progress ] && $cmd_rm -f  $rebuild_progress
  apos_log "snrinit: proceeding with the node boot sequence"
    
  return $TRUE
}

# M A I N

case $1 in
  start)
    if isvAPG; then
      if is_deploy_phase || is_snr_phase; then
        # initial deployment or faulty-node case
        install_node
      elif [ -f $rebuild_progress ]; then 
        # healthy node boot case; recover faulty node if snrinit 
        # was in progress before the healthy node reboot.
        recover_faulty_node
      fi
    fi
        ;;
  stop|restart|status)
    # do nothing for now
    apos_log "snrinit: (stop|restart|status) nothing to do"
  ;;
  *)
    apos_abort 1 "snrinit: usupported command $1"    
  ;;
esac

apos_outro $0

exit $TRUE

# End of file
