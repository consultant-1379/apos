#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       bspmngr_common.sh
# Description:
#       A collection of common functions for the bspmngr script.
##
# Usage:
#	. <bspmngr_root>/lib/common/bspmngr_common.sh
##
# Changelog:
# Fri Feb 21 2014 - Stefano V
#		Code cleanup and optimization
# Wed Feb 5 2014 - Rajeswari P
#		First Version
##

export CLUSTERCONF="/opt/ap/apos/bin/clusterconf/clusterconf"

export TRUE=$( true; echo $? )
export FALSE=$( false; echo $? )
export LOG_TAG='bspmngr'
[ ! -d /tmp/apos ] && mkdir -p /tmp/apos
export OUT_TMP='/tmp/apos/bspmngr.log'
export OUT_FILE='/tmp/apos/ironout.log'
export TMP_XML='/tmp/apos/tmp.xml'
export TMP_FILE='/tmp/apos/tmp.txt'
export ERR_TMP="$OUT_TMP"
export BSPMNGR_DIR="${AP_HOME:-/opt/ap}/apos/bin/bspm"
export CMD_DIR='cmd'
export LIB_DIR='lib'
export LIB_COMMON_DIR="$LIB_DIR/common"
export MAN_DIR="$LIB_COMMON_DIR/man"
export HW_TYPE=$( ${AP_HOME:-/opt/ap}/apos/conf/apos_hwtype.sh)
export SLOT_MIN=0
export SLOT_MAX=28
export INVALID_SLOT=27
export TENANT=
export SHELF_ID=
export MY_SLOT=
export DMXC_IP_A=
export DMXC_IP_B=
export NC_SESSION_OPEN_FAILED=3
export DMXC_PORT="831"

MY_SHELF_ADDR=
SHELF_ID=
ap_node_num=
rm='/bin/rm'
immlist='/usr/bin/immlist'
awk='/usr/bin/awk'
ncget='/opt/ap/acs/bin/ncget'
ncaction='/opt/ap/acs/bin/ncaction'
nceditconfig='/opt/ap/acs/bin/nceditconfig'
ironsidecmd='/opt/ap/acs/bin/ironsidecmd'



# Backward-compatible variables ------------------------------------------ BEGIN
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
	for DIR in $(find $BSPMNGR_DIR/$CMD_DIR -type d 2>/dev/null); do
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
		[ ! -d "$BSPMNGR_DIR/$CMD_DIR/$COMMAND" ] && abort "wrong command specified ($COMMAND)"
	else
		COMMAND=$(get_commands)
	fi	
	local SUB_COMMANDS=''
	for CMD in $COMMAND; do
		for FILE in $(find $BSPMNGR_DIR/$CMD_DIR/$CMD -type f 2>/dev/null); do
			FILE=$(basename $FILE)
			[ -x "${BSPMNGR_DIR}/${CMD_DIR}/${CMD}/${FILE}" ] && SUB_COMMANDS="${SUB_COMMANDS}${FILE} "
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

function fetch_shelf_address(){
				[ ! -z $MY_SHELF_ADDR ] && return $TRUE

        #echo "Fetching the AP shelf id..."
				local ap_node_num=$($immlist -a apNodeNumber axeFunctionsId=1  | $awk -F'=' '{print $2}')
				[[ $ap_node_num -ne 1 && $ap_node_num -ne 2 ]] && abort "apNodeNumber not found"
         
        local ap_shelf_id=''
        [ $ap_node_num -eq 1 ] && ap_shelf_id="$($immlist -a apBladesDn apgId=AP1,logicalMgmtId=1,AxeEquipmentequipmentMId=1 | $awk -F'=' '{print $4}'| $awk -F',' '{print $1}')"
        [ $ap_node_num -eq 2 ] && ap_shelf_id="$($immlist -a apBladesDn apgId=AP2,logicalMgmtId=1,AxeEquipmentequipmentMId=1 | $awk -F'=' '{print $4}'| $awk -F',' '{print $1}')" 
        [ -z $ap_shelf_id ] && abort "ap_shelf_id not found"

				[ $ap_node_num -eq 1 ] && MY_SLOT="$($immlist -a apBladesDn apgId=AP1,logicalMgmtId=1,AxeEquipmentequipmentMId=1 | $awk -F'=' '{print $3}'| $awk -F',' '{print $1}')"
        [ $ap_node_num -eq 2 ] && MY_SLOT="$($immlist -a apBladesDn apgId=AP2,logicalMgmtId=1,AxeEquipmentequipmentMId=1 | $awk -F'=' '{print $3}'| $awk -F',' '{print $1}')"

        plug0=$(echo $ap_shelf_id | awk -F. '{print $1}')
        plug1=$(echo $ap_shelf_id | awk -F. '{print $2}')
        plug3=$(echo $ap_shelf_id | awk -F. '{print $4}')



        #printf "MAGAZINE %x%x%x\n" $plug3 $plug1 $plug0

        tmp=$(printf "%x%x%x" $plug3 $plug1 $plug0)

        MY_SHELF_ADDR=$(printf '%d' "0x$tmp")

        return $TRUE
}

function fetch_shelf_id(){
				
	[ ! -z $SHELF_ID  ] && return $TRUE

        #Get shelf list
	local query=$(printf SHLF-------- )
	fetch_dmxc_ip

        $ironsidecmd -a $DMXC_IP_A -p $DMXC_PORT -s "$query" -o $TMP_FILE > /dev/null
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne $TRUE ]; then
		if [ $EXIT_CODE -eq $NC_SESSION_OPEN_FAILED ]; then
        		clean_xml > /dev/null
        		$ironsidecmd -a $DMXC_IP_B -p $DMXC_PORT -s "$query" -o $TMP_FILE > /dev/null
            		EXIT_CODE=$?
            		if [ $EXIT_CODE -ne $TRUE ]; then
            			abort "Failed to get shelf list from BSP"
            		fi
          	else
              		abort "Failed to get shelf list from BSP"
          	fi
        fi

	number=$(echo $TMP_FILE | awk -F : '{ print $2 }')
	echo $number
	found=$FALSE 
	while read -r line
	do
		name=$line
#		echo "line read from file - $name"
		number1=$(echo $name | awk -F : '{ print $1 }')
		number2=$(echo $name | awk -F : '{ print $2 }')
#		echo "num1 = $number1"
#		echo "num2 = $number2"
        	if [ $number2 -eq $MY_SHELF_ADDR ]; then
                	SHELF_ID=$number1
			found=$TRUE
                	break
		fi
	done < "$TMP_FILE"

        #printf "Shelf ID = %s, Physical Address = %s\n" $number1 $phys
        
	#printf "My ShelfId = %s\n\n" $SHELF_ID
        
        clean_xml > /dev/null
       	if [ $found -eq $FALSE ]; then
		abort "Failed to get shelf list from BSP"
	fi
	
        return $TRUE
}

function is_slot(){
	if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ && $1 -ge $SLOT_MIN && $1 -le $SLOT_MAX && $1 -ne $INVALID_SLOT ]]; then
		return $TRUE
	else
		return $FALSE
	fi
}

function check_board_format(){
	 local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/slot_by_name.dat"
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
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
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
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
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
        elif [[ $HW_TYPE =~ ^GEP5$|^GEP7$ ]]; then
                rCode=$( check_bootdev_format_v5 $1)
        fi
        return $rCode
}

# Usage: get_slot_by_name <board_name>
function get_slot_by_name(){
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/slot_by_name.dat"
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
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/slot_by_name.dat"
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
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/ip_by_name.dat"
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
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/ip_by_name.dat"
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
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
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
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
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
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
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
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/bootdev.dat"
	if [ $# -gt 0 ]; then
		local DEV=$(echo $1 | tr [:upper:] [:lower:])
		if ! check_bootdev_format_v5 ${DEV}; then
			#abort "wrong bootdev format: \"${DEV}\""
			echo "wrong bootdev format: \"${DEV}\""
		fi
		cat $RESOURCE_FILE | grep -E "^${DEV};.*v5|;${DEV}=.*v5|;${DEV}.*v5" | awk -F'=' '{ print $2 }' 2>/dev/null
	else
		abort 'missing parameter'		
	fi
}

function get_id_by_dev(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && get_id_by_dev_v1 $1
    [[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && get_id_by_dev_v5 $1
}

function get_all_boards(){
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/slot_by_name.dat"
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
    local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/baudrate.dat"
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
    local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/baudrate.dat"
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
	local RESOURCE_FILE="$BSPMNGR_DIR/$LIB_COMMON_DIR/baudrate.dat"
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

function clean_xml()
{
	$rm -rf $TMP_XML > /dev/null
	$rm -rf $TMP_FILE > /dev/null
	$rm -rf $OUT_FILE > /dev/null
}

function fetch_dmxc_ip(){
	[ -z $DMXC_IP_A ] && DMXC_IP_A=$($CLUSTERCONF network -D | grep bgci_a | awk  '{print $4}' |  awk -F. '{print $1"."$2"."$3".1"}')
	[ -z $DMXC_IP_B ] && DMXC_IP_B=$($CLUSTERCONF network -D | grep bgci_b | awk  '{print $4}' |  awk -F. '{print $1"."$2"."$3".1"}')
	
	if [ -z $DMXC_IP_A ] || [ -z $DMXC_IP_B ]; then
		abort 'Failed to fetch DMXC addresses'
	fi
}
