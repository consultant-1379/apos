#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_mkdir.sh
# Description:
#       A script for the APOS' folders creation on APG43L.
# Note:
#	None.
##
# Usage:
#	apos_mkdir.sh <folder-list-file> <subsystem-list-file>
##
# Output:
#       None.
##
# Changelog:
# - Wed Sep 30 2015 - Fabio Ronca (efabron)
#	Add permission setting on substistem indipendent folder.
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Tue Dec 21 2010 - Francesco Rainone (efrarai)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Global variables
FOLDER_LIST_FILE=$1
SUBSYSTEM_LIST_FILE=$2
SUBSYSTEM_PLACEHOLDER="<subsystem>"

function make_dir() {
	if [ ! -z $1 ]; then
		echo -ne "Creating the folder: \"$1\"... "
		if [ ! -d $1 ]; then
			mkdir -p $1 2> /dev/null
			if [ $? -ne 0 ]; then
				echo -e "FAILED"
			else
				echo -e "done"
			fi
		else
			echo -e "ALREADY PRESENT"
		fi
	fi
}

function apply_permission() {
	if [[ ! -z $1 && ! -z $2 ]]; then
		echo -ne "Setting permission $2 on folder: \"$1\"... "
		if [ -d $1 ]; then
			chmod $2 $1 2> /dev/null
			if [ $? -ne 0 ]; then
				echo -e "FAILED"
			else
				echo -e "done"
			fi
		fi
	fi
}

function create_folders() {
        local OLD_IFS=$IFS
        local TARGET_FOLDER=""
        local TARGET_FOLDER_PERMISSION=""
	IFS=""
	FULL_FOLDER_LIST=$(cat "$FOLDER_LIST_FILE" | sed 's/#.*//g' | sed 's/[\t]*//g' | grep -v '^$' | grep -v '^[ ]*$')
	SUBSYSTEM_LIST=$(cat "$SUBSYSTEM_LIST_FILE" | sed 's/#.*//g' | sed 's/[\t]*//g' | grep -v '^$' | grep -v '^[ ]*$')

	FOLDER_LIST=$(echo $FULL_FOLDER_LIST | grep -v "$SUBSYSTEM_PLACEHOLDER")
	IFS=$'\n'
	for F in $FOLDER_LIST; do
                TARGET_FOLDER=$(echo $F | awk -F':' '{print $1}')
                TARGET_FOLDER_PERMISSION=$(echo $F | awk -F':' '{print $2}')
		make_dir $TARGET_FOLDER
                if [ ! -z $TARGET_FOLDER_PERMISSION ];then
                  apply_permission $TARGET_FOLDER $TARGET_FOLDER_PERMISSION
                fi
	done
	IFS=""
	SS_FOLDER_LIST=$(echo $FULL_FOLDER_LIST | grep "$SUBSYSTEM_PLACEHOLDER")

	IFS=$'\n'

	for SS in $SUBSYSTEM_LIST; do
		for F in $SS_FOLDER_LIST; do
			SSF=$(echo $F | sed "s/$SUBSYSTEM_PLACEHOLDER/$SS/")
			make_dir $SSF
		done
	done

    IFS=$OLD_IFS
}

# Main

create_folders

apos_outro $0
exit $TRUE

# End of file
