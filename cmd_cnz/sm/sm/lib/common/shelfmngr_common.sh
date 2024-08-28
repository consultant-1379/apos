#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       shelfmngr_common.sh
# Description:
#       A collection of common functions for the shelfmngr script.
##
# Usage:
#	. <shelfmngr_root>/lib/common/shelfmngr_common.sh
##
# Changelog:
# Wed Sep 07 2017 - Raghavendra Koduri (xkodrag)
#       Added support for GEP7
# Wed Sep 25 2013 - Malangsha Shaik (xmalsha)
#	Added support for GEP5
# Fri Mar 09 2012 - Francesco Rainone (efrarai)
#	First Version
##

export TRUE=$( true; echo $? )
export FALSE=$( false; echo $? )
export LOG_TAG='shelfmngr'
[ ! -d /tmp/apos ] && mkdir -p /tmp/apos
export OUT_TMP='/tmp/apos/shelfmngr.log'
export ERR_TMP="$OUT_TMP"
export SHELFMNGR_DIR="${AP_HOME:-/opt/ap}/apos/bin/sm"
export CMD_DIR='cmd'
export MIB_DIR='mib'
export LIB_DIR='lib'
export LIB_COMMON_DIR="$LIB_DIR/common"
export MAN_DIR="$LIB_COMMON_DIR/man"
export HW_TYPE=$( ${AP_HOME:-/opt/ap}/apos/conf/apos_hwtype.sh)
#export SLOT_MIN=0
#export SLOT_MAX=25

# Backward-compatible variables ------------------------------------------ BEGIN
mibspath="$SHELFMNGR_DIR/mib"
intRegExp='SNMPv2.*=\ INTEGER:\ (.*)'
strRegExp='SNMPv2.*=\ STRING:\ (.*)'
hexRegExp='SNMPv2.*=\ Hex-STRING:\ (.*)'
intGrep='SNMPv2.*= INTEGER'
strGrep='SNMPv2.*= STRING'
hexGrep='SNMPv2.*= Hex-STRING'
#boardTypes=( SCB APUB CPUB MAUB GEA DVD Disk )
# Backward-compatible variables -------------------------------------------- END

function log(){
	local PRIO='-p user.notice'
	local MESSAGE="${*:-notice}"	
	#/bin/logger $PRIO $LOG_TAG "$MESSAGE" >$OUT_TMP 2>$ERR_TMP	
	echo -e "$MESSAGE"
}

function log_error(){	
	local PRIO='-p user.err'
	local MESSAGE="${*:-error}"	
	/bin/logger $PRIO $LOG_TAG "$MESSAGE" >$OUT_TMP 2>$ERR_TMP
	echo -e "$MESSAGE" >&2
}

function abort(){
	local MESSAGE="ABORTING (${@:-unspecified error occurred})"
	log_error "$MESSAGE"		
	exit $FALSE
}

function get_commands(){
	local COMMANDS=''
	for DIR in $(find $SHELFMNGR_DIR/$CMD_DIR -type d 2>/dev/null); do
		DIR=$(basename $DIR)
		[[ ! $DIR =~ ^${CMD_DIR}$ ]] && COMMANDS="${COMMANDS}${DIR} "
	done
	echo $COMMANDS
}

# Returns a space-separated list of all the sub-commands belonging to the
#  specified command. All the sub-commands of ALL the commands if no parameters
#  have been specified.
function get_sub_commands(){
	local COMMAND=''
	if [ $# -gt 0 ]; then
		COMMAND=$1
		[ ! -d "$SHELFMNGR_DIR/$CMD_DIR/$COMMAND" ] && abort "wrong command specified ($COMMAND)"
	else
		COMMAND=$(get_commands)
	fi	
	local SUB_COMMANDS=''
	for CMD in $COMMAND; do
		for FILE in $(find $SHELFMNGR_DIR/$CMD_DIR/$CMD -type f 2>/dev/null); do
			FILE=$(basename $FILE)
			[ -x "${SHELFMNGR_DIR}/${CMD_DIR}/${CMD}/${FILE}" ] && SUB_COMMANDS="${SUB_COMMANDS}${FILE} "
		done
	done
	echo $SUB_COMMANDS
}

function command_is_valid(){
	local COMMAND=''
	if [ $# -gt 0 ]; then
		COMMAND=$1		
	else
		abort 'missing parameter'
	fi	
	local VALID_COMMANDS=$(get_commands)
	for C in $VALID_COMMANDS; do
		[ "$COMMAND" == "$C" ] && return $TRUE
	done
	return $FALSE
}

function sub_command_is_valid(){
	local COMMAND=''
	local SUB_COMMAND=''
	if [ $# -eq 1 ]; then		
		SUB_COMMAND=$1
	elif [ $# -eq 2 ]; then
		COMMAND=$1
		SUB_COMMAND=$2
	else
		abort 'missing or unexpected parameter'
	fi	
	local VALID_SUB_COMMANDS=$(get_sub_commands $COMMAND)
	for SC in $VALID_SUB_COMMANDS; do
		[ "$SUB_COMMAND" == "$SC" ] && return $TRUE
	done
	return $FALSE
}

function check_debug(){	
	[ $OPT_DEBUG -eq $TRUE ] && set -x
}

function hex2ascii(){
        echo -e $(echo ${@} | sed -e 's@[[:space:]]@\\x@g' -e 's@^@\\x@g')
}

# Usage: identify_sc_boards
# The function tries to automatically identify the switching boards by asking
# for their ROJ number (except the part following the / symbol).
function identify_sc_boards(){
	local OID_LIST_FILES="$(find $SHELFMNGR_DIR/$LIB_DIR -name 'oid_list.sh')"
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	local SLOT_LIST="$(get_slot_by_name sca) $(get_slot_by_name scb)"
	
	local OID_LIST=''
	local IP=''
	local SLOT=''
	local snmpres=''
	for OID_LIST in $OID_LIST_FILES; do
		. $OID_LIST
		for IP in $IP_LIST; do
			for SLOT in $SLOT_LIST; do
				#CASE SCB-RP
				snmpres=$(snmpset -r 1 -t 1 -L o -v 2c -c public $IP .1.3.6.1.4.1.193.154.2.1.2.1.1.1.12.${SLOT} i 1 2>/dev/null | grep "$intGrep")				
				snmpres=$(snmpget -r 1 -t 1 -L o -v 2c -c public $IP .1.3.6.1.4.1.193.154.2.1.2.1.1.1.5.${SLOT} 2>$ERR_TMP)
				if [[ $snmpres =~ $strRegExp ]]; then
					local PRODUCTID=${BASH_REMATCH[1]}
					local BOARD_ROJ=${PRODUCTID:1:24}
					echo -n ${BOARD_ROJ/\/*/}
					return $TRUE
				fi
				
				#CASE SCX				
				snmpres=$(snmpget -r 1 -t 1 -L o -v 2c -c NETMAN $IP .1.3.6.1.4.1.193.177.2.2.1.3.1.1.1.2.${SLOT} 2>$ERR_TMP)
				if [[ $snmpres =~ $hexRegExp ]]; then
					local PRODUCTID=$(hex2ascii ${BASH_REMATCH[1]})
					local BOARD_ROJ=${PRODUCTID/\/*/}
					echo -n ${BOARD_ROJ}
					return $TRUE
				#CASE SMX
				elif [[ $snmpres =~ $strRegExp ]]; then
                                     local PRODUCTID=${BASH_REMATCH[1]}
                                     local BOARD_ROJ=${PRODUCTID:1:24}
                                     echo -n ${BOARD_ROJ/\/*/}
                                     return $TRUE
				fi
			done
		done		
	done
	
	abort 'failure while trying to contact sc boards.'
}

# Usage: identify_magazine
# The function get the productid from one of the SC boards and sets up a symlink
# pointing to the right OID list file.
function identify_magazine(){
	local OID_FILE='oid_list.sh'
	local SNMP_FILE='snmp_queries.sh'
	local SC_BOARD_ROJ=$(identify_sc_boards)
	local ROJ_DIR="${SC_BOARD_ROJ// /}"
	if [ ! -d ${SHELFMNGR_DIR}/${LIB_DIR}/${ROJ_DIR} ]; then
		abort "board \"${SC_BOARD_ROJ}\" not supported!"
	elif [[ ! -f ${SHELFMNGR_DIR}/${LIB_DIR}/${ROJ_DIR}/${OID_FILE} || ! -f ${SHELFMNGR_DIR}/${LIB_DIR}/${ROJ_DIR}/${SNMP_FILE} ]]; then
		abort "support files not found!"
	fi
	ln -s ${SHELFMNGR_DIR}/${LIB_DIR}/${ROJ_DIR}/${OID_FILE} ${SHELFMNGR_DIR}/${LIB_COMMON_DIR}/${OID_FILE} &>/dev/null || abort "failure while creating the symlink ${SHELFMNGR_DIR}/${LIB_COMMON_DIR}/${OID_FILE}"
	ln -s ${SHELFMNGR_DIR}/${LIB_DIR}/${ROJ_DIR}/${SNMP_FILE} ${SHELFMNGR_DIR}/${LIB_COMMON_DIR}/${SNMP_FILE} &>/dev/null || abort "failure while creating the symlink ${SHELFMNGR_DIR}/${LIB_COMMON_DIR}/${SNMP_FILE}"
}

function is_slot(){
	if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ && $1 -ge $SLOT_MIN && $1 -le $SLOT_MAX ]]; then
		return $TRUE
	else
		return $FALSE
	fi
}

function check_board_format(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/slot_by_name.dat"	
	local BOARD_LOGICAL_NAMES=$(cat $RESOURCE_FILE | awk -F'=' '{print $1}' | tr ';' ' ' | tr "\n" " ")	
	if [ $# -gt 0 ]; then
		if is_slot $1; then
			return $TRUE
		elif [ $(echo "$BOARD_LOGICAL_NAMES" | grep -E "^${1} | ${1} | ${1}$|^${1}$" | wc -l) -gt 0 ]; then
			return $TRUE		
		fi
	else
		abort 'missing parameter'
	fi
	return $FALSE
}

function check_bootdev_format_v1(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
	local BOOTDEV_NAMES=$(cat $RESOURCE_FILE | grep 'v1=' | awk -F':' '{print $1}' | tr ';' ' ' | tr "\n" " ")
	if [ $# -gt 0 ]; then
		if [ $(echo "$BOOTDEV_NAMES" | grep -E "^${1} | ${1} | ${1}$|^${1}$" | wc -l) -gt 0 ]; then
			return $TRUE		
		fi
	else
		abort 'missing parameter'
	fi
	return $FALSE
}

function check_bootdev_format_v5(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
	local BOOTDEV_NAMES=$(cat $RESOURCE_FILE | grep 'v5=' | awk -F':' '{print $1}' | tr ';' ' ' | tr "\n" " ")
	if [ $# -gt 0 ]; then
		if [ $(echo "$BOOTDEV_NAMES" | grep -E "^${1} | ${1} | ${1}$|^${1}$" | wc -l) -gt 0 ]; then
			return $TRUE		
		fi
	else
		abort 'missing parameter'
	fi
	return $FALSE
}

function check_bootdev_format(){
	local rCode=''
        if [[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]]; then
                rCode=$( check_bootdev_format_v1 $1)
        elif [[ $HW_TYPE =~ ^GEP5$ || $HW_TYPE =~ 'GEP7' ]]; then
                rCode=$( check_bootdev_format_v5 $1)
        fi
        return $rCode
}

# Usage: get_slot_by_name <board_name>
function get_slot_by_name(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/slot_by_name.dat"
	if [ $# -gt 0 ]; then
		local BOARD=$1
		if ! check_board_format $BOARD; then
			abort "unsupported board name: \"$BOARD\""			
		fi
		cat $RESOURCE_FILE | grep -E "^${BOARD};|;${BOARD}=" | awk -F'=' '{ print $2 }' 2>/dev/null
	else
		abort 'missing parameter'		
	fi
}

function get_name_by_slot(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/slot_by_name.dat"
	if [ $# -gt 0 ]; then
		local SLOT=$(echo $1 | tr [:upper:] [:lower:])
		if ! is_slot $SLOT; then
			abort "wrong slot format: \"${SLOT}\""			
		fi
		cat $RESOURCE_FILE | grep -E "=${SLOT}$" | awk -F'=' '{ print $1 }' | awk -F';' '{print $1}' 2>/dev/null
	else
		abort 'missing parameter'		
	fi
}

# Usage: get_ip_by_name <board_name> <network>
function get_ip_by_name(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/ip_by_name.dat"
	if [ $# -gt 1 ]; then
		local BOARD=$1
		local NETWORK=$2
		if ! check_board_format $BOARD; then
			abort "unsupported board name: \"$BOARD\""			
		fi
		
		cat $RESOURCE_FILE | grep -E "^${BOARD};|;${BOARD}=" | awk -F'=' '{ print $2 }' | grep -E "^${NETWORK}:" | awk -F':' '{ print $2 }' 2>/dev/null
		
	else
		echo 'missing parameter'
	fi
}

# Usage: get_ip_by_name <ip_address>
function get_board_by_ip(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/ip_by_name.dat"
	if [ $# -gt 0 ]; then
		local IP="$1"
		
		cat $RESOURCE_FILE | grep ":${IP}$" | awk -F= '{print $1}' | awk -F';' '{print $1}' 2>/dev/null		
	else
		echo 'missing parameter'
	fi
}

function boards_are_equal(){
	if [[ $# -eq 2 && $(check_board_format $1) -eq $TRUE && $(check_board_format $2) -eq $TRUE ]]; then
		local BOARD_1=$1
		local BOARD_2=$2
		if ! is_slot $BOARD_1; then
			BOARD_1=$(get_slot_by_name $BOARD_1)
		fi
		if ! is_slot $BOARD_2; then
			BOARD_2=$(get_slot_by_name $BOARD_2)
		fi
		[ $BOARD_1 -eq $BOARD_2 ] && return $TRUE
	else
		abort 'missing or wrong parameter'
	fi
	
	return $FALSE
}

function get_dev_by_id_v1(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
	if [ $# -gt 0 ]; then
		local ID=$(echo $1 | tr [:upper:] [:lower:])
		if [[ ! ${ID} =~ ^[0-9a-f]{8,8}$ ]]; then
			abort "wrong id format: \"${ID}\""			
		fi
		cat $RESOURCE_FILE | grep -E "v1=${ID:0:2}[0-9a-f]{6,6}" | awk -F'=' '{ print $1 }' | awk -F';' '{print $1}' 2>/dev/null
	else
		abort 'missing parameter'		
	fi
}

function get_dev_by_id_v5(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
	if [ $# -gt 0 ]; then
		local ID=$(echo $1 | tr [:upper:] [:lower:])
		if [[ ! ${ID} =~ ^[0-9a-f]{8,8}$ ]]; then
			abort "wrong id format: \"${ID}\""			
		fi
		cat $RESOURCE_FILE | grep -E "v5=${ID:0:2}[0-9a-f]{6,6}" | awk -F'=' '{ print $1 }' | awk -F';' '{print $1}' 2>/dev/null
	else
		abort 'missing parameter'		
	fi
}

function get_dev_by_id(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && get_dev_by_id_v1 $1
    [[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && get_dev_by_id_v5 $1 

}

function get_id_by_dev_v1(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
	if [ $# -gt 0 ]; then
		local DEV=$(echo $1 | tr [:upper:] [:lower:])
		if ! check_bootdev_format ${DEV}; then
			#abort "wrong bootdev format: \"${DEV}\""
			echo "wrong bootdev format: \"${DEV}\""
		fi
		cat $RESOURCE_FILE | grep -E "^${DEV};.*v1|;${DEV}=.*v1" | awk -F'=' '{ print $2 }' 2>/dev/null
	else
		abort 'missing parameter'		
	fi
}

function get_id_by_dev_v5(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
	if [ $# -gt 0 ]; then
		local DEV=$(echo $1 | tr [:upper:] [:lower:])
		if ! check_bootdev_format ${DEV}; then
			#abort "wrong bootdev format: \"${DEV}\""
			echo "wrong bootdev format: \"${DEV}\""
		fi
		cat $RESOURCE_FILE | grep -E "^${DEV};.*v5|;${DEV}=.*v5" | awk -F'=' '{ print $2 }' 2>/dev/null
	else
		abort 'missing parameter'		
	fi
}

function get_id_by_dev(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && get_id_by_dev_v1 $1
    [[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7'  ]] && get_id_by_dev_v5 $1
}

function get_all_boards(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/slot_by_name.dat"
	local BOARD_LOGICAL_NAMES=$(cat $RESOURCE_FILE | awk -F'=' '{print $1}' | awk -F';' '{print $1}' | tr "\n" " ")	
	echo $BOARD_LOGICAL_NAMES
}

function get_known_slots(){
	local KNOWN_SLOTS=''
	for B in $(get_all_boards); do
		KNOWN_SLOTS="${KNOWN_SLOTS}$(get_slot_by_name ${B}) "
	done
	echo $ALL_SLOTS
}

function check_eth(){
	if [ $# -gt 0 ]; then
		if [[ $1 =~ ^eth[0-6]$ ]]; then
			return $TRUE
		else
			return $FALSE
		fi
	else
		abort 'missing parameter'		
	fi
}

# Usage: increase_mac <HEX_MAC_ADDRESS> <DEC_OFFSET>
function increase_mac(){
	if [ $# -ge 2 ]; then
		printf '%012x' $(( 16#${1} + ${2} ))|tr [:lower:] [:upper:]|sed 's/../& /g;s/ $//'
	else
		abort 'missing parameter'		
	fi	
}

# Usage: compute_bootdev_bits <gpr_register> <device_mask>
function compute_bootdev_bits(){
	if [ $# -gt 1 ]; then
		local OP1=$(echo $1 | tr [:upper:] [:lower:])
		[[ ! "$OP1" =~ ^16#.*$ ]] && OP1="16#${OP1}"
		local OP2=$(echo $2 | tr [:upper:] [:lower:])
		[[ ! "$OP2" =~ ^16#.*$ ]] && OP2="16#${OP2}"
		local MASK='16#00FFFFFF'
		local RESULT=$(( ($OP1 & $MASK) | ($OP2 & ~$MASK) ))
		printf "%08x\n" $RESULT
	else
		abort 'missing parameter'		
	fi
}

# Usage: get_oid_for_slot <OID_NAME> <slot>
# for a list of <OID_NAME>s see the file <shelf_type>_oid_list.sh
# <slot> must be an non-negative integer referring to a slot position in the
#  shelf.
function get_oid_for_slot(){
	if [ $# -ge 2 ]; then
		if [[ -n "${1}" && -n "${!1}" ]]; then
			local oid="$1"
		else
			abort "unsupported oid_name specified: \"$1\""
		fi
		if is_slot $2; then
			local slot="$2"
		else
			abort 'wrong slot format'
		fi
		local final_oid=$(eval echo "${!oid}")
		echo "$final_oid"
	else
		abort 'missing parameter'
	fi
}

# function to get the baudrate from Hexa value
function get_baud_by_id(){
    local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/baudrate.dat"
    if [ $# -gt 0 ]; then
        local ID=`echo $1`
        if [[ ! ${ID} =~ ^[0-7]{8,8}$ ]]; then
                 abort "wrong id format: \"${ID}\""
        fi
        cat $RESOURCE_FILE | grep -E "=00${ID:2:4}" | awk -F'=' '{ print $1 }'
    else
        abort 'missing parameter'
    fi
}

function get_id_by_baudrate(){
    local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/baudrate.dat"
    if [ $# -gt 0 ]; then
        local baudrate=`echo $1`
        local BAUDRATES=$(cat $RESOURCE_FILE | awk -F'=' '{print $1}' | tr "\n" " ")
        if [ $(echo "$BAUDRATES" | grep -w "${1}" | wc -l) -gt 0 ]; then
            cat $RESOURCE_FILE | grep -E "^${baudrate}=" | awk -F'=' '{ print $2 }' 2>/dev/null
        fi
    else
         abort 'missing parameter'
    fi
}

# Usage: compute_baudrate_bits <gpr_register> <device_mask>
function compute_baudrate_bits(){
    if [ $# -gt 1 ]; then
        local OP1=$(echo $1 | tr [:upper:] [:lower:])
        [[ ! "$OP1" =~ ^16#.*$ ]] && OP1="16#${OP1}"
        local OP2=$(echo $2 | tr [:upper:] [:lower:])
        [[ ! "$OP2" =~ ^16#.*$ ]] && OP2="16#${OP2}"
        local MASK='16#0F00FFFF'
        local RESULT=$(( ($OP1 & $MASK) | ($OP2 & ~$MASK) ))
        printf "%08x\n" $RESULT
    else
        abort 'missing parameter'
    fi
}

# function to check the baudrate format as mentioned in 
# baudrate.dat file
function check_baudrate_format(){
	local RESOURCE_FILE="$SHELFMNGR_DIR/$LIB_COMMON_DIR/baudrate.dat"
    local BAUDRATES=$(cat $RESOURCE_FILE | awk -F'=' '{print $1}' | tr "\n" " ")
    if [ $# -gt 0 ]; then
        if [ $(echo "$BAUDRATES" | grep -w "${1}" | wc -l) -gt 0 ]; then
                return $TRUE
        fi
    else
        abort 'missing parameter'
    fi
    return $FALSE
}
