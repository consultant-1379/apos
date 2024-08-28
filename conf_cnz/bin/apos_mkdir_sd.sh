#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_mkdir_sd.sh
# Description:
#       A script to create system disk folder structure.
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
# - Fri Mar 22 2013 - Vincenzo Conforti (qvincon)
#	Changed to manage AP2 configuration
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Tue Dec 21 2010 - Francesco Rainone (efrarai)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

FOLDER_LIST_FILE="sd_folder.list"
SUBSYSTEM_LIST_FILE="sd_subsystem.list"
DEF_CPFTP_DIR='/var/cpftp'

FOLDER_LIST_FILE_AP2="sd_folder_ap2.list"
SUBSYSTEM_LIST_FILE_AP2="sd_subsystem_ap2.list"

# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)
	
# check AP type
if [ $AP2 == $AP_TYPE ]; then
	/opt/ap/apos/conf/apos_mkdir.sh $FOLDER_LIST_FILE_AP2 $SUBSYSTEM_LIST_FILE_AP2
else
	/opt/ap/apos/conf/apos_mkdir.sh $FOLDER_LIST_FILE $SUBSYSTEM_LIST_FILE
	# Create virtual directories for the APIO_1 FTP site
	apio_vdirs='APZ:/data/apz cpa:/data/apz/data/cpa/cphw/crash cpb:/data/apz/data/cpb/cphw/crash CPSDUMP:/data/cps/data CPSLOAD:/data/fms/data tracelog:/data/cps/logs tracelog_cpa:/data/cps/logs/tesrv/cpa tracelog_cpb:/data/cps/logs/tesrv/cpb'
	for item in $apio_vdirs; do
		alias=$(echo $item | awk -F':' '{ print $1 }')
		path=$(echo $item | awk -F':' '{ print $2 }')
		mkdir -m 770 -p $DEF_CPFTP_DIR/$alias
	done

	# Workaround: Create the lowercase reference to APZ
	pushd $DEF_CPFTP_DIR &>/dev/null
	ln -s APZ apz 2>/dev/null
	popd &>/dev/null
fi


# End of file
