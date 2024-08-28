#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#    aposchrony_enabler.sh
# Description:
#       This script is to create folder used by optimaized lde-brf backup functionality
#       during Upgrade 
#
##
# Changelog:
# - Thu 17 feb 2022 - Rajeshwari Padavala (xcsrpad)
#      Updating cluster.conf with "ntp.server-type chrony" in case of vBSC
#       First version.
#
# If installation_type is MI, then installtion is happening in Native
# installation_type parameter is not available on virtual
# Note: This script doesn't trigger during recovery scenario 
installation_type=$(cat /cluster/mi/installation/installation_type 2>/dev/null)
if [[ -n "$installation_type" && "$installation_type" == 'MI' ]]; then
  /bin/logger 'aposchrony_enabler: Skipping configuration changes, not applicable on Native!'
  exit 0
fi

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh 

  

function enableChrony(){

  # nested lock function to ensure mutual exclusion in the case of editing
  # clustered resource (e.g. /cluster/etc/cluster.conf)
	function lock() {
	  message="acquiring lock on $lockfile..."
	  echo "$message"
	  apos_log "$message"
		
	  /usr/bin/lockfile -2 -l 16 -s 4 $lockfile
		
	  local return_code=$?
	  if [ $return_code -eq $TRUE ]; then
		message="lock successfully acquired"
		echo "$message"
		apos_log "$message"
	  else
		message="unable to acquire lock"
		echo "ERROR: $message" >&2
		apos_log user.crit "$message"
	  fi
	  return $return_code
	}

	# nested unlock function to ensure mutual exclusion in the case of editing
	# clustered resource (e.g. /cluster/etc/cluster.conf)
	function unlock() {
	  message="releasing lock on $lockfile"
	  echo "$message"
	  apos_log "$message"
		
	  /usr/bin/rm -f $lockfile
		
	  local return_code=$?
	  if [ $return_code -eq $TRUE ]; then
		message="lock successfully released"
		echo "$message"
		apos_log "$message"
	  else
		message="unable to release lock"
		echo "ERROR: $message" >&2
		apos_log user.crit "$message"
	  fi
	  return $return_code
	}
	 
	local lockdir=$(apos_create_brf_folder clear)
	local lockfile=$lockdir/$FUNCNAME.lock
	local cluster_file=''
	local message=''
	local return_code=''
	local tmp_error=$(/usr/bin/mktemp -t $(/usr/bin/basename $0).XXX)
	local mutex=$FALSE
	local old_trap=''
	  
	cluster_file=/cluster/etc/cluster.conf
	mutex=$TRUE
	# store the current handler for the EXIT signal.
	old_trap=$(trap | grep -P '[[:space:]]EXIT$')
	# overwrite the handler for the EXIT signal.
	trap unlock EXIT
	   
	if [ ! -w "$cluster_file" ]; then
	  message="ABORT: file $cluster_file not found or not writable"
	  echo "ABORT: $message" >&2
	  apos_abort "$message"
	else
	  message="setting ntp.server-type in $cluster_file"
	  echo "$message"
	  apos_log "$message"
	fi
  

	#[ ! -f $CLU_FILE ] && apos_abort 'cluster.conf file not found'
	if [ $mutex -eq $TRUE ]; then
		lock
	fi
	return_code=$TRUE
	if isvBSC; then
	  if grep -qw '^[[:space:]]*ntp.server-type[[:space:]]ntp$' $cluster_file 2>/dev/null; then
	   /usr/bin/sed -i 's/ntp.server-type ntp/ntp.server-type chrony/' $cluster_file 2>${tmp_error}
	   return_code=$?
	  else    
		  if ! grep -qw '^[[:space:]]*ntp.server-type[[:space:]]chrony$' $cluster_file 2>/dev/null; then
		   apos_log "ntp-server type entry not found, appending it to cluster.conf file"
		  /usr/bin/sed -i '/node 2 control SC-2-2/a\ntp.server-type chrony\' $cluster_file 2>${tmp_error}
		  return_code=$?
		  fi 
	  fi	  
	else
	  if ! grep -q '^[[:space:]]*ntp.server-type[[:space:]]ntp$' $cluster_file 2>/dev/null; then 
	  /usr/bin/sed -i '/node 2 control SC-2-2/a\ntp.server-type ntp\' $cluster_file 2>${tmp_error}
	  return_code=$?
	  fi 
	fi

  
	if [ $return_code -ne $TRUE ]; then
		message="failure while executing sed in-place on the file \"$cluster_file\" ($(<${tmp_error}))"
		echo "ABORT: $message" >&2
		apos_abort "$message"
	fi

	if [ $mutex -eq $TRUE ]; then
		unlock
	fi
		
	apos_log 'Sucessfully updated ntp.server-type configuration in cluster.conf file'
	if [ $mutex -eq $TRUE ]; then
		# restore the previous handler for the EXIT signal, or completely reset it.
		if [ -n "$old_trap" ]; then
		  eval $old_trap
		else
		  trap - EXIT
		fi
	fi
	#Unset nested functions
	unset lock
	unset unlock
	  
	## BEGIN: Reload the cluster configuration on the current node
	   cluster config -r -a &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
	## END: Reload the cluster configuration

  
}

##### M A I N #####
apos_log "BEGIN: aposchrony_enabler"

if isvBSC; then
   enableChrony
else
   apos_log "Nothing to do as apt_type is not vBSC"
fi

apos_log "END: aposchrony_enabler"
exit $TRUE
# End of file
