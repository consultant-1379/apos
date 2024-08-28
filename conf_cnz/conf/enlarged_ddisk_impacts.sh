#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       enlarged_ddisk_impacts.sh
#
# Description:
#       A script to handle enlarged data disk.
#       Performs disk partitions and configures DRBD1 resource.
#
##
# Usage:
#       ./enlarged_ddisk_impacts.sh
##
# Changelog:
# - Fri Aug 21 2015 - Pratap Reddy (xpraupp)
#       First version.      
##

# global variable-set
TRUE=$( true; echo $? )
FALSE=$( false; echo $? )
SYSTEM_DISK='/dev/eri_disk'
LOG_TAG='-t enlarge_datadisk.sh'

# commands
CMD_RAIDMGR='/opt/ap/apos/bin/raidmgr'
CMD_SSH='/usr/bin/ssh'
CMD_LOGGER='/bin/logger'
CMD_CP='/bin/cp'
CMD_RM='/bin/rm'
CMD_SED='/usr/bin/sed'
CMD_GREP='/usr/bin/grep'

# ------------------------------------------------------------------------
function log(){
  local PRIO='-p user.notice'
  local MESSAGE="${*:-notice}"
  $CMD_LOGGER $PRIO $LOG_TAG "$MESSAGE" 2>&1
  echo -e "$MESSAGE"
}

# ------------------------------------------------------------------------
function log_error(){
  local PRIO='-p user.err'
  local MESSAGE="${*:-error}"
  $CMD_LOGGER $PRIO $LOG_TAG "$MESSAGE" 2>&1
	echo -e "$MESSAGE"
}

# ------------------------------------------------------------------------
function abort(){
  log_error "ABORTING: <"$1">"
  exit 1
}

#------------------------------------------------------------------------
function is_connected(){
  [ $(drbd-overview | $CMD_GREP "$1" | $CMD_GREP 'Secondary/Secondary'| wc -l) -eq 1 ] && return $TRUE
  return $FALSE
}

#------------------------------------------------------------------------
function wait_for_drbd1_to_join(){
  while ! is_connected 'drbd1' ;do
    sleep 5
  done
  $CMD_ECHO 'drbd1 is now joined from node 2' &>/dev/null 2>&1
}

#------------------------------------------------------------------------
function extend_drbd1() {
  # On SC-2-1, partition the data disk atatched to VM
  # then create lvm on data partition
  [ ! -x $CMD_RAIDMGR ] && abort "raidmgr: no execute permissions found"

	echo "Enlarging DRBD capacity on $THOST"
	OPTS='--part --lvm --force --verbose'
 	$CMD_RAIDMGR "$OPTS" 
	[ $? -ne 0 ] && abort "Failed"
  
 	# On SC-2-2, partition the data disk atatched to VM
 	# then create lvm on data partition
	echo "Enlarging DRBD capacity on $RHOST"
 	$CMD_SSH $RHOST $CMD_RAIDMGR $OPTS
	[ $? -ne 0 ] && abort "Failed"

  # wait for drbd1 is to be active on other node
  wait_for_drbd1_to_join

  # format the drdb1
  echo -n "Formatting the resource... "
  OPTS='--format --mount'
  $CMD_RAIDMGR $OPTS || abort "Failure while formatting drbd1 resource"
  
  # create the folder structure
  OPTS='--folder'
  $CMD_RAIDMGR $OPTS || abort "Failure while creating folder structure"
  echo 'success'
}

#------------------------------------------------------------------------
function update_installation_conf(){
  local etc_installation_conf='/cluster/etc/installation.conf'
  local tmp_installation_conf='/tmp/installation.conf'
  local boot_installation_conf='/boot/.installation.conf'

  [ -f $tmp_installation_conf ] && rm $tmp_installation_conf

  # Calculate the size of the data disk available on node
  DATA_SIZE=$( /sbin/vgs | grep "eri-data-vg" | awk '{print $6}' )
  NEW_DATA_GB=$( echo $DATA_SIZE | grep 'g')
  if [ -z "$NEW_DATA_GB" ]; then
    NEW_DATA_TB=$( echo $DATA_SIZE | grep 't')
    [ -z "$NEW_DATA_TB" ] && abort "VGS size unknown"
    NEW_DATA_TB=$(echo $NEW_DATA_TB | awk -F"." '{print $1}')
    (( NEW_DATA_GB=$NEW_DATA_TB * 1024 ))
  else
    NEW_DATA_GB=$(echo $NEW_DATA_GB | awk -F"." '{print $1}')
  fi

  if [ -f $etc_installation_conf ]; then
    $CMD_CP $etc_installation_conf $tmp_installation_conf

    # Fetch the existing size of the data disk in installation.conf
    OLD_DATA_GB=$( /usr/bin/awk -F"=" '/eri-data-part size/{print $NF}' $tmp_installation_conf | /usr/bin/tr -d '[GbgBtMT]')
    [ -z "$OLD_DATA_GB" ] && abort "Old data disk size found null"
    
    # Check if both sizes are different, if sizes are same
    # not required to updated installation.conf
    if [ $NEW_DATA_GB -ne $OLD_DATA_GB ]; then
      $CMD_SED -i "s/option eri-data-part size=$OLD_DATA_GB/option eri-data-part size=$NEW_DATA_GB/g" $tmp_installation_conf &>/dev/null
      [ $? -ne 0 ] && abort "failure while updating installation.conf"
      # copy updated installation.conf file to original path
      $CMD_CP $tmp_installation_conf $etc_installation_conf
      if ! /usr/bin/lde-partition query -f $etc_installation_conf &>/dev/null; then
        abort "failure while updating installation.conf"
      fi
      # copy updated installation.conf file to
      # boot path on both nodes.
      if [ -f $boot_installation_conf ]; then
        $CMD_CP $etc_installation_conf $boot_installation_conf
        if ! $CMD_SSH $RHOST "$CMD_CP $etc_installation_conf $boot_installation_conf" ; then
          abort "failure while updating installation.conf on remote node"
        fi
      else
        abort "$boot_installation_conf file not found"
      fi
  	fi
  else
   abort "$etc_installation_conf file not found"
  fi

  # cleanup the temparory installation.conf
  $CMD_RM $tmp_installation_conf
}

#------------------------------------------------------------------------
function umount_all(){ 
  mountpoints=$(grep -E '^[^[:space:]]+[[:space:]]\/data\/|^[^[:space:]]+[[:space:]]\/var\/cpftp\/' /proc/mounts | awk '{print $2}')
  for mount_point in $mountpoints; do
    local attempts=0
    local max_attempts=2
    SIGINT_TMOUT=2
    SIGKILL_TMOUT=4
    local UMOUNT_CMD="/usr/bin/timeout --signal=INT --kill-after=$SIGKILL_TMOUT $SIGINT_TMOUT /bin/umount $mount_point"
    # executes the umount instruction
    $UMOUNT_CMD

    local RETURN_CODE=$?
    while [[ $RETURN_CODE -ne 0 && $attempts -lt $max_attempts ]]; do
      echo "unable to unmount $mount_point... retrying"
      attempts=$(( $attempts + 1 ))
      # sleeps only if the umount command hasn't timed-out (RETURN_CODE!=124)
      [ $RETURN_CODE -ne 124 ] && /bin/sleep 0.5

      # tries to umount once more
      $UMOUNT_CMD
      RETURN_CODE=$?
    done

    # check if the mount point is unmounted
    if mountpoint -q $mount_point; then
      echo "unable to unmount \"$mount_point\" after $max_attempts attempts!"
    fi
	done
}

#------------------------------------------------------------------------
function finalize(){

	[ ! -x $CMD_RAIDMGR ] && abort "raidmgr: Execute permission not found"

	OPTS='--unmount'
 	$CMD_RAIDMGR $OPTS || abort "raidmgr: Failure while unmounting drbd1"

  # umount all 
  umount_all

  # Stopping DRDB1
	OPTS='--disable'
 	$CMD_RAIDMGR $OPTS || abort "raidmgr: Failure while disabling drbd1"

  # update the installation.conf with data volumes size
  update_installation_conf
}

#------------------------------------------------------------------------
function sanity_check(){
	THOST=$(</etc/cluster/nodes/this/hostname)
  RHOST=$(</etc/cluster/nodes/peer/hostname)
  [ -z $RHOST ] && abort "REMOTE_HOST received null,exiting..."
  [ !  -b $SYSTEM_DISK ] && abort "$SYSTEM_DISK is not a block device"

	SYSTEM_DISK="$( /usr/bin/readlink -f $SYSTEM_DISK)"
}

# _____________________
#|    _ _   _  .  _    |
#|   | ) ) (_| | | )   |
#|_____________________|
# Here begins the "main" function...

# sanity check to see if things are in place
sanity_check

# configure drdb1 on both nodes
extend_drbd1

# Unmount and disable the drdb1 resource
# also update installation.conf 
finalize

# if we are here, command executed successfully.
exit $TRUE

