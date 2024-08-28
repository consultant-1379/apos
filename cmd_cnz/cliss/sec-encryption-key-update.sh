#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       sec-encryption-key-update.sh
# Description:
#       A script to wrap the invocation of sec-encryption-key-update from the COM CLI.
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
# - Monday Mar 01 2019 - G V L SOWJANYA (XSOWGVL)
#               Removed Info function since ldap user with role systemSecurityAdministrator is not having access to log file
#		Checking the existence of sec command before doing anything like parsing etc..		
# - Thursday Feb 06 2019 - G V L SOWJANYA (XSOWGVL)
#		Added parse function to check the command syntax and print usage if needed before invoking the SEC command
# - Thursday Jan 31 2019 - G V L SOWJANYA (XSOWGVL)
#		First version.
##

# Source common functions
. /opt/ap/apos/conf/apos_common.sh

SEC_CMD_RUN='/opt/eric/sec-crypto-cxp9027895/bin/sec-encryption-key-update'
CMD_GETOPT=/usr/bin/getopt
CMD_CAT=/bin/cat
LOG_DIR=/tmp
LOG_FILE=sec-encryption-key-update.log

exit_usge=2

#----------------------------------------------------------------------------------------
function console_print(){
	echo -e "$1"
}

#----------------------------------------------------------------------------------------
function log(){
	/bin/logger -t "$LOG_TAG" "$*"
}

#----------------------------------------------------------------------------------------
function usage(){
$CMD_CAT << EOF
Usage : 
sec-encryption-key-update [-c|--confirm]|[-s|--status]|[-h|--help]

	-c|--confirm generates new internal keys *without* prompting confirmation
	-s|--status gives the status of internal re-encryption
	-h|--help prints help
        
EOF
}

#----------------------------------------------------------------------------------------
function usage_error(){
	console_print "$1"
	usage
	exit $2
}

#----------------------------------------------------------------------------------------
function check_sec_cmd_existence(){
if [ ! -f ${SEC_CMD_RUN} ]; then
	echo 'ERROR: sec-encryption-key-update command not found'
	apos_abort 'ERROR: sec-encryption-key-update command not found'
else
	apos_log 'INFO: sec-encryption-key-update command found'
fi
}

#----------------------------------------------------------------------------------------
function parse_args(){
	[ $# -gt 1 ] && usage_error "Incorrect usage" $exit_usge
  
	local OPTIONS='c s h'
	local LONG_OPTIONS='confirm status help'

	$CMD_GETOPT --quiet --quiet-output --longoptions="$LONG_OPTIONS" --options="$OPTIONS" -- "$@"
	[ $? -ne $TRUE ] && usage_error "Incorrect usage" $exit_usge

	while [ $# -gt 0 ]; do
		case "$1" in
			--confirm|-c|--status|-s)/usr/bin/sudo $SEC_CMD_RUN $1
				  exit $?	
				  ;;
			-h|--help)usage
				  exit $?
			   	  ;;
			*)usage_error "Incorrect usage" $exit_usge
	 	esac
		shift
	done


}

# _____________________
#|    _ _   _  .  _    |
#|   | ) ) (_| | | )   |
#|_____________________|
# Here begins the "main" function...
log "START: <$0>"

# Check for SEC cmd existence on the node in case of no arguments passed
        check_sec_cmd_existence

# parse the command-line paramters
	parse_args $*

# Launch the command in case of no arguments passed
	/usr/bin/sudo ${SEC_CMD_RUN} "$@"

exit $?

