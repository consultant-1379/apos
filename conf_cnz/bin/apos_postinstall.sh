#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_postinstall.sh
# Description:
#       APOS post-installation configuration.
# Note:
#	None.
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Tue Jul 16 2013 - Pratap Reddy (xpraupp)
#	Modified to support both MD and DRBD 
# - Tue Jun 04 2013 - Pratap Reddy (xpraupp)
#   Replaced drbdmgr with ddmgr
# - Mon Apr 30 2013 - Pratap Reddy (xpraupp)
#	drbd configuration script modified 
# - Tue Apr 16 2013 - Pratap Reddy (xpraupp)
#	Added configure_drbd_peer function.
# - Mon Apr 01 2013 - Tanu Aggarwal (xtanagg)
#	Replace RAID with DRBD.
# - Mon Mar 25 2013 - ealfatt, edaebao
#       APOS reduced: raid configuration script commented
# - Mon Sep 17 2012 - Antonio Buonocunto (eanbuon)
#	Script rework for single node execution
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Thu Nov 17 2011 - Francesco Rainone (efrarai)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

DRBD_RESOURCE='drbd1'

function isMD(){
	 [ "$DD_REPLICATION_TYPE" == "MD" ] && return $TRUE
	 return $FALSE
}

function isDRBD(){
	[ "$DD_REPLICATION_TYPE" == "DRBD" ] && return $TRUE
    return $FALSE
}

# Parameters: $1=exit code
function check_exit_code() {
	if [[ $1 -ne 0 ]]; then
		apos_abort 1 'unhandled error'
	fi
}

function configure_drbd_local() {
	if [ -d /opt/ap/apos/conf ]; then
		pushd /opt/ap/apos/conf >/dev/null 2>&1
		isMD && {
				echo -e 'performing RAID configuration...'
				if [ -x "/opt/ap/apos/bin/raidmgmt" ]; then
				 	/opt/ap/apos/bin/raidmgmt -p -f -b -m -F >/dev/null 2>&1
					EXIT_C=$?
					check_exit_code $EXIT_C
				else
					apos_abort 1 "file \"raidmgmt\" not found or not executable"
				fi
		}
		isDRBD && {
			echo -e 'performing $DRBD_RESOURCE configuration...'
			if [ -x "/opt/ap/apos/bin/raidmgr" ]; then
				/opt/ap/apos/bin/raidmgr --assemble --mount >/dev/null 2>&1
				EXIT_C=$?
				check_exit_code $EXIT_C
			else
				apos_abort 1 "file \"raidmgr\" not found or not executable"
			fi
	    }	
		echo 'done'
		echo
		popd >/dev/null 2>&1
	else
		apos_abort 1 "the folder /opt/ap/apos/conf cannot be found!"
	fi
}

# Main

HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
[ -z "$HW_TYPE" ] && apos_abort 1 'HW_TYPE not found'

# fetching data storage type varaible
DD_REPLICATION_TYPE=$(get_storage_type)

NODE_THIS=$(/bin/hostname)

case $NODE_THIS in

SC-2-1)
	configure_drbd_local
;;
SC-2-2)
	apos_log "Nothing to do on $NODE_THIS"
;;
*)
abort "unhandled NODE NAME found"

esac


apos_outro $0
exit $TRUE

# End of file
