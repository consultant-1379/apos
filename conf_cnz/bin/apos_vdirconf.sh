#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_vdirconf.sh
# Description:
#       A script to set the virtual directories.
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
# - Wed Jan 20 2016 - Gianluca Santoro (eginsan)
#	Removed back thicks. Removed service xinetd restart.
# - Thu Feb 18 2016 - Roni Newatia (xronnew)
#       Removed "tracelog_cpa:/data/cps/logs/tesrv/cpa and tracelog_cpb:/data/cps/logs/tesrv/cpb"
#       as a fix for TR HU25530
# - TUe Jul 22 2014 - Antonio Buonocunto (eanbuon)
#	Added new vdir tracelog_cpa and tracelog_cpb
# - Tue Jul 16 2013 - Pratap Reddy (xpraupp)
#   	Modified to support both MD and DRBD
# - Tue Jun 04 2013 - Pratap Reddy (xpraupp)
#   	Replaced drbdmgr with ddmgr
# - Mon Apr 01 2013 - Tanu Aggarwal (xtanagg)
#   	Replace RAID with DRBD.
# - Tue Jul 03 2012 - Buonocunto (eanbuon) Rainone (efrarai) Ronca (efabron)
#		Fix. Shame on Alfonso.
# - Wed Jun 27 2012 - Alfonso Attanasio (ealfatt)
#		Adaptation to BRF.
# - Tue May 14 2012 - Paolo Palmieri (epaopal)
#		Configuration of NBI folder on default ftp site.
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#		Configuration scripts rework.
# - Tue Oct 18 2011 - Francesco Rainone (efrarai)
#       Bugfix.
# - Mon Sep 26 2011 - Francesco Rainone (efrarai)
#       Bugs correction.
# - Mon Sep 05 2011 - Paolo Palmieri (epaopal)
#       Bugs correction.
# - Thu Jul 19 2011 - Paolo Palmieri (epaopal)
#       Definition of the APG FTP sites and related virtual directories.
# - Mon Mar 14 2011 - Francesco Rainone (efrarai)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

RAIDMGR='/opt/ap/apos/bin/raidmgr'
DEF_CPFTP_DIR='/var/cpftp'

function isMD(){
     [ "$DD_REPLICATION_TYPE" == "MD" ] && return $TRUE
     return $FALSE
}

function dir_create_and_check () {	
	# $1 is the octal-mask permission to be given to the directory
	# $2 is the directory to be created/modded	
	mask=${1}
	dir=${2}
	
	if [ -d "${dir}" ]; then
		/bin/chmod ${mask} "${dir}" || apos_abort "failure while changing permissions of ${dir}"
		apos_log "${dir} exists, permissions ${mask} set"
	else
		/bin/mkdir -m ${mask} -p "${dir}" || apos_abort "failure while creating the folder ${dir}"
		apos_log "${dir} created, permissions ${mask} set"
	fi
}


# Main
# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)

HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
[ -z "$HW_TYPE" ] && apos_abort 1 'HW_TYPE not found'

# fetching data storage type varaible
DD_REPLICATION_TYPE=$(get_storage_type)

isMD && RAIDMGR='/opt/ap/apos/bin/raidmgmt'

if [ $AP2 != $AP_TYPE ]; then

	# Creating folders on data disk only on AP1
	if [[ ! "$(${RAIDMGR} --is-mounted)" =~ is\ mounted\ to ]]; then
		apos_abort "Data disk not mounted"
	fi

	# Create virtual directories for the APIO_1 FTP site
	apio_vdirs='APZ:/data/apz cpa:/data/apz/data/cpa/cphw/crash cpb:/data/apz/data/cpb/cphw/crash CPSDUMP:/data/cps/data CPSLOAD:/data/fms/data tracelog:/data/cps/logs'
	for item in $apio_vdirs; do
		alias=$(echo $item | awk -F':' '{ print $1 }')
		path=$(echo $item | awk -F':' '{ print $2 }')
		dir_create_and_check 777 $path
		/bin/mount --bind $path $DEF_CPFTP_DIR/$alias || apos_abort "failure while mounting a bind from ${path} to $DEF_CPFTP_DIR/$alias"
	done

fi

apos_outro $0
exit $TRUE

# End of file
