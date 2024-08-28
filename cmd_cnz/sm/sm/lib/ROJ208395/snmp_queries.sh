#------------------------------------------------------------------------------#
# ROJ 208 395                                                                  #
# snmp queries to be used in a SCX-based EGEM2 magazine.                        #
#------------------------------------------------------------------------------#
# NOTES: - This file is intended to be sourced by the shelfmngr routines so it #
#        MUST be compliant with the bash syntax.                               #
#------------------------------------------------------------------------------#
export SLOT_MIN=0
export SLOT_MAX=28

function GET_BOOTDEV(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && GET_BOOTDEV_v1
	[[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && GET_BOOTDEV_v5
	return $TRUE
}

function GET_BOOTDEV_v1(){
	local slot=$BOARD
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "querying the first boot device of the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	local BOOTDEV=''
	local snmpres1=''
	local snmpres=''
	local OID=$(get_oid_for_slot OID_GET_BOOTDEV $slot)
        local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for IP in $IP_LIST; do
		snmpres1=$(snmpget -L n -v 2c -c NETMAN $IP ${OID} 2>/dev/null | grep "$hexGrep")
		snmpres=$(echo "$snmpres1" | awk -F'= ' '{print $2}' | awk -F ': ' '{print $2}')
		snmpres=$( echo "$snmpres" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]' )

		if [ ! -z "$snmpres" ]; then
			BOOTDEV="$(get_dev_by_id ${snmpres: -8})"
			is_verbose && BOOTDEV="${BOOTDEV} (0x${snmpres})"
			log $BOOTDEV
			return $TRUE
		fi
	done
	abort 'snmp request failed'
}

function GET_BOOTDEV_v5(){
	local slot=$BOARD
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "querying the first boot device of the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	local BOOTDEV=''
	local snmpres=''
	local OID=$(get_oid_for_slot OID_GET_BOOTDEV_v5 $slot)
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for IP in $IP_LIST; do
		snmpres=$(snmpget -L n -v 2c -c NETMAN $IP ${OID} 2>/dev/null | grep "$hexGrep")
		snmpres=$( echo $snmpres | cut -d : -f4 | cut -c1-12 | sed 's@[[:space:]+]*@@g')
		if [ ! -z "$snmpres" ]; then
			BOOTDEV=$(get_dev_by_id $snmpres)
			is_verbose && BOOTDEV="${BOOTDEV} (0x${snmpres})"
			log $BOOTDEV
			return $TRUE
		fi
	done
	abort 'snmp request failed'
}

function GET_BAUDRATE(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && GET_BAUDRATE_v1
	[[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && GET_BAUDRATE_v5
	return $TRUE
}

function GET_BAUDRATE_v1(){
	local slot=$BOARD
    	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "querying the baudrate of board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	local BAUDRATE=''
	local snmpres1=''
     	local snmpres=''
    	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	local OID=$(get_oid_for_slot OID_GET_BAUDRATE $slot)
	for IP in $IP_LIST; do
		snmpres1=$(snmpget -L n -v 2c -c NETMAN $IP ${OID} 2>/dev/null | grep "$hexGrep")
		snmpres=$(echo "$snmpres1" | awk -F'= ' '{print $2}' | awk -F ': ' '{print $2}')
		snmpres=$( echo "$snmpres" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]' )
		if [ ! -z "$snmpres" ]; then
			BAUDRATE="$(get_baud_by_id ${snmpres: -8})"
         		is_verbose && BAUDRATE="${BAUDRATE} (0x${snmpres})"
			log $BAUDRATE
			return $TRUE
    		fi
	done
    abort 'snmp request failed'
}

function GET_BAUDRATE_v5(){
    abort 'This option is not supported on GEP5 and GEP7  hardware generation'
}

function GET_MAC(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && GET_MAC_v1
	[[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && GET_MAC_v5
	return $TRUE
}
	
function GET_MAC_v1(){
	local SLOT_LIST=''
	if [[ $OPT_ALL_BOARDS -eq $TRUE || $OPT_ALL_SLOTS -eq $TRUE ]]; then
		SLOT_LIST=$(seq -s ' ' $SLOT_MIN $SLOT_MAX)
	else
		SLOT_LIST=$BOARD
		! is_slot $BOARD && SLOT_LIST=$(get_slot_by_name $BOARD)
	fi
	
	local ETH=''
	if [ $OPT_ETH -eq $TRUE ]; then
		abort 'MAC address retrieval for a specific NIC is not supported by the present shelf.'
	elif [ $OPT_BASE -eq $TRUE ]; then
		ETH='base_mac'
	fi
		
	for SLOT in $SLOT_LIST; do
		if is_verbose || [ $OPT_ALL_SLOTS -eq $TRUE ] || [ $OPT_ALL_BOARDS -eq $TRUE ]; then
			log "slot[${SLOT}]"
		fi
		local OID=''
		local OFFSET=0
		OID="$(get_oid_for_slot OID_GET_MAC_BASE ${SLOT})"			
		local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
		local snmpres=''
		for IP in $IP_LIST; do
			snmpres=$(snmpget -L n -v 2c -c NETMAN $IP ${OID} 2>/dev/null | grep "$hexGrep")
			if [[ $snmpres =~ $hexRegExp ]]; then
				local MAC=$(echo "${BASH_REMATCH[1]}" | tr -d ' ')
				MAC=$( increase_mac "$MAC" ${OFFSET} )
				local TAB=''
				if is_verbose || [ $OPT_ALL_SLOTS -eq $TRUE ] || [ $OPT_ALL_BOARDS -eq $TRUE ]; then				
					TAB="\t"
				fi
				log "${TAB}${ETH}=${MAC}"			
				break
			fi
		done
	done
	return $TRUE 
}

function GET_MAC_v5(){
	local SLOT_LIST=''
	if [[ $OPT_ALL_BOARDS -eq $TRUE || $OPT_ALL_SLOTS -eq $TRUE ]]; then
		SLOT_LIST=$(seq -s ' ' $SLOT_MIN $SLOT_MAX)
	else
		SLOT_LIST=$BOARD
		! is_slot $BOARD && SLOT_LIST=$(get_slot_by_name $BOARD)
	fi
	
	local ETH_LIST=''
	if [ $OPT_ETH -eq $TRUE ]; then
		if [ $OPT_ETH_ARG == 'all' ]; then
			ETH_LIST='eth0 eth1 eth2 eth3 eth4 eth5 eth6'
		else
			ETH_LIST=$OPT_ETH_ARG
		fi
	elif [ $OPT_BASE -eq $TRUE ]; then
		ETH_LIST='base_mac'
	fi
	
	if [[ $ETH_LIST =~ eth[0-2] ]]; then
		local APA=$(get_slot_by_name apub_a)
		local APB=$(get_slot_by_name apub_b)
		if [ $OPT_ALL_BOARDS -eq $TRUE ] || [ $OPT_ALL_SLOTS -eq $TRUE ]; then
			abort 'eth0, eth1, eth2, eth3, eth4 and eth5 are only valid for apub boards'
		fi
		for S in $SLOT_LIST; do
			[[ $S -ne $APA && $S -ne $APB ]] && abort 'eth0, eth1, eth2, eth3, eth4 and eth5 are only valid for apub boards'
		done
	fi
	
	for SLOT in $SLOT_LIST; do
		if is_verbose || [ $OPT_ALL_SLOTS -eq $TRUE ] || [ $OPT_ALL_BOARDS -eq $TRUE ]; then
			log "slot[${SLOT}]"
		fi
		for ETH in $ETH_LIST; do			
			local OID=''
			local OFFSET=0
			OID="$(get_oid_for_slot OID_GET_MAC_BASE_v5 ${SLOT})"
			case $ETH in
			eth0)
				OFFSET=8
				;;	
			eth1)
				OFFSET=9
				;;
			eth2)
				OFFSET=3
				;;
			eth3)
				OFFSET=1
				;;
			eth4)
				OFFSET=2
				;;
			eth5)
				OFFSET=5
				;;
			eth6)
				OFFSET=6
				;;
			esac			
			
			local snmpres=''
			local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
			for IP in $IP_LIST; do
				snmpres=$(snmpget -L n -v 2c -c NETMAN $IP ${OID} 2>/dev/null | grep "$hexGrep")
				if [[ $snmpres =~ $hexRegExp ]]; then
					local MAC=$(echo "${BASH_REMATCH[1]}" | tr -d ' ')
					MAC=$( increase_mac "$MAC" ${OFFSET} )
					local TAB=''
					if is_verbose || [ $OPT_ALL_SLOTS -eq $TRUE ] || [ $OPT_ALL_BOARDS -eq $TRUE ]; then				
						TAB="\t"
					fi
					log "${TAB}${ETH}=${MAC}"			
					break
				fi
			done
		done		
	done
	return $TRUE
}

function GET_MASTER(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && GET_MASTER_v1
	[[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && GET_MASTER_v5
	return $TRUE
}

function GET_MASTER_v1(){
	local SLOT_LIST="$(get_slot_by_name 'sc_a') $(get_slot_by_name 'sc_b')"
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for SLOT in $SLOT_LIST; do
	local OID="$(get_oid_for_slot OID_GET_MASTER $SLOT)"
		for IP in $IP_LIST; do
			snmpres=$(snmpget -L o -v 2c -c NETMAN $IP ${OID} 2>$ERR_TMP | grep "$hexGrep")
			if [[ $snmpres =~ $hexRegExp ]]; then
				local CONTROL_STATE=$(echo "$snmpres" | awk -F'= ' '{print $2}' | awk -F ': ' '{print $2}' | awk '{print $1}')
				if [ ${CONTROL_STATE} == '03' ]; then			
					log $( get_board_by_ip "$IP" )
					return $TRUE
				fi
			fi
		done
	done
	abort 'snmp request failed'
}

function GET_MASTER_v5(){
	local SLOT_LIST="$(get_slot_by_name 'sc_a') $(get_slot_by_name 'sc_b')"
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for SLOT in $SLOT_LIST; do
	local OID="$(get_oid_for_slot OID_GET_MASTER_v5 $SLOT)"
		for IP in $IP_LIST; do
			snmpres=$(snmpget -L o -v 2c -c NETMAN $IP ${OID} 2>$ERR_TMP | grep "$hexGrep")
			if [[ $snmpres =~ $hexRegExp ]]; then
				local CONTROL_STATE=$(echo "$snmpres" | awk -F'= ' '{print $2}' | awk -F ': ' '{print $2}' | awk '{print $1}')
				if [ ${CONTROL_STATE} == '03' ]; then			
					log $( get_board_by_ip "$IP" )
					return $TRUE
				fi
			fi
		done
	done
	abort 'snmp request failed'
}

function GET_PRODUCTID(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && GET_PRODUCTID_v1
	[[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && GET_PRODUCTID_v5
	return $TRUE
}

function GET_PRODUCTID_v1(){
	#-----------------------------------------------------------------------
	# NESTED FUNCTIONS ONLY VISIBLE FROM THE PRESENT FUNCTION
	function query_item(){
		if [ $# -eq 2 ]; then
			local ITEM=${1}
			local slot=${2}
			local OID="$(get_oid_for_slot ${ITEM} ${slot})"
			local snmpres=''
			snmpres=$(snmpget -L n -v 2c -c NETMAN $ipSC_A ${OID} 2>/dev/null | grep "$hexGrep")
			if [[ ! $snmpres =~ $hexRegExp ]]; then
				snmpres=$(snmpget -L n -v 2c -c NETMAN $ipSC_B ${OID} 2>/dev/null | grep "$hexGrep")
			fi
		fi
		if [[ ! $snmpres =~ $hexRegExp ]]; then
			echo ''
			return $FALSE
		fi
		hex2ascii $( echo $snmpres | awk -F'= ' '{print $2}' | awk -F': ' '{print $2}')
	}
	
	# Usage: pad_to_len <string> <length>
	function pad_to_len(){
		if [ $# -eq 2 ]; then
			local STRING="$1"
			local LEN="$2"
			
			if [ "${#STRING}" -lt "$LEN" ]; then
				printf "%-${LEN}s" "${STRING}"
				return $TRUE
			else
				echo "$STRING"
			fi
		fi
	return $FALSE
	}
	#-----------------------------------------------------------------------
	
	local SLOTS=''
	if [[ $OPT_ALL_BOARDS -eq $TRUE || $OPT_ALL_SLOTS -eq $TRUE ]]; then
		SLOTS=$(seq -s ' ' $SLOT_MIN $SLOT_MAX)
	else
		SLOTS=$BOARD
		! is_slot $BOARD && SLOTS=$(get_slot_by_name $BOARD)
	fi	
		
	local PRODUCTID=''
	local ipSC_A=$(get_ip_by_name sc_a ipna)
	local ipSC_B=$(get_ip_by_name sc_b ipna)
	for slot in $SLOTS; do
		local PRINT_ENABLED=$FALSE
		
		local FIELD1=$( query_item 'OID_GET_PRODUCTID_ROJ' $slot)
		local FIELD2=$( query_item 'OID_GET_PRODUCTID_RSTATE' $slot)
		local FIELD3=$( query_item 'OID_GET_PRODUCTID_PNAME' $slot)
		local FIELD4=$( query_item 'OID_GET_PRODUCTID_SERIAL' $slot)
		local FIELD5=$( query_item 'OID_GET_PRODUCTID_DATE' $slot)		
		local FIELD6=$( query_item 'OID_GET_PRODUCTID_VENDOR' $slot)
		
		local PAD_FIELD1=$( pad_to_len "${FIELD1}" 24)		
		local PAD_FIELD2=$( pad_to_len "${FIELD2}" 7)
		local PAD_FIELD3=$( pad_to_len "${FIELD3}" 12)
		local PAD_FIELD4=$( pad_to_len "${FIELD4}" 13)
		local PAD_FIELD5=$( pad_to_len "${FIELD5}" 9)		
		local PAD_FIELD6=$( pad_to_len "${FIELD6}" 31)
		if [[ ! "$FIELD1" =~ ^[[:space:]]*$ ]]; then
			PRODUCTID="\"${PAD_FIELD1}${PAD_FIELD2}${PAD_FIELD3}${PAD_FIELD4}${PAD_FIELD5}${PAD_FIELD6}\""			
			PRINT_ENABLED=$TRUE			
			
			#FIELD1="${FIELD1//[[:space:]]/}"
			FIELD1="\n\troj[${FIELD1}]"			
			
			#FIELD2="${FIELD2//[[:space:]]/}"
			FIELD2="\n\trevision[${FIELD2}]"
			
			#FIELD3="${FIELD3//[[:space:]]/}"
			FIELD3="\n\tboard[${FIELD3}]"
			
			#FIELD4="${FIELD4//[[:space:]]/}"
			FIELD4="\n\tserial[${FIELD4}]"
			
			#FIELD5="${FIELD5//[[:space:]]/}"
			FIELD5="\n\tdate[${FIELD5}]"
			
			#FIELD6="${FIELD6//[[:space:]]/}"
			FIELD6="\n\tmanufacturer[${FIELD6}]"
		else
			PRODUCTID='""'
			is_verbose && PRINT_ENABLED=$TRUE
		fi
		local SLOT_OUT=$(printf 'slot[%2d]' $slot)
		local BOARD_OUT=$(printf 'board[%10s]' $(get_name_by_slot $slot))
		local PRODUCTID_OUT="${PRODUCTID}"
		is_verbose && PRODUCTID_OUT="${FIELD1}${FIELD2}${FIELD3}${FIELD4}${FIELD5}${FIELD6} "
		
		if [ $OPT_ALL_SLOTS -eq $TRUE ]; then
			[ $PRINT_ENABLED -eq $TRUE ] && log "${SLOT_OUT}: ${PRODUCTID_OUT}"
		else
			[ $PRINT_ENABLED -eq $TRUE ] && log "${SLOT_OUT} ${BOARD_OUT}: ${PRODUCTID_OUT}"
		fi
	done
	return $TRUE
}

function GET_PRODUCTID_v5(){
	#-----------------------------------------------------------------------
	# NESTED FUNCTIONS ONLY VISIBLE FROM THE PRESENT FUNCTION
	function query_item(){
		if [ $# -eq 2 ]; then
			local ITEM=${1}
			local slot=${2}
			local OID="$(get_oid_for_slot ${ITEM} ${slot})"
			local snmpres=''
			snmpres=$(snmpget -L n -v 2c -c NETMAN $ipSC_A ${OID} 2>/dev/null | grep "$hexGrep")
			if [[ ! $snmpres =~ $hexRegExp ]]; then
				snmpres=$(snmpget -L n -v 2c -c NETMAN $ipSC_B ${OID} 2>/dev/null | grep "$hexGrep")
			fi
		fi
		if [[ ! $snmpres =~ $hexRegExp ]]; then
			echo ''
			return $FALSE
		fi
		hex2ascii $( echo $snmpres | awk -F'= ' '{print $2}' | awk -F': ' '{print $2}')
	}
	
	# Usage: pad_to_len <string> <length>
	function pad_to_len(){
		if [ $# -eq 2 ]; then
			local STRING="$1"
			local LEN="$2"
			
			if [ "${#STRING}" -lt "$LEN" ]; then
				printf "%-${LEN}s" "${STRING}"
				return $TRUE
			else
				echo "$STRING"
			fi
		fi
	return $FALSE
	}
	#-----------------------------------------------------------------------
	
	local SLOTS=''
	if [[ $OPT_ALL_BOARDS -eq $TRUE || $OPT_ALL_SLOTS -eq $TRUE ]]; then
		SLOTS=$(seq -s ' ' $SLOT_MIN $SLOT_MAX)
	else
		SLOTS=$BOARD
		! is_slot $BOARD && SLOTS=$(get_slot_by_name $BOARD)
	fi	
		
	local PRODUCTID=''
	local ipSC_A=$(get_ip_by_name sc_a ipna)
	local ipSC_B=$(get_ip_by_name sc_b ipna)
	for slot in $SLOTS; do
		local PRINT_ENABLED=$FALSE
		
		local FIELD1=$( query_item 'OID_GET_PRODUCTID_ROJ_v5' $slot)
		local FIELD2=$( query_item 'OID_GET_PRODUCTID_RSTATE_v5' $slot)
		local FIELD3=$( query_item 'OID_GET_PRODUCTID_PNAME_v5' $slot)
		local FIELD4=$( query_item 'OID_GET_PRODUCTID_SERIAL_v5' $slot)
		local FIELD5=$( query_item 'OID_GET_PRODUCTID_DATE_v5' $slot)		
		local FIELD6=$( query_item 'OID_GET_PRODUCTID_VENDOR_v5' $slot)
		
		local PAD_FIELD1=$( pad_to_len "${FIELD1}" 24)		
		local PAD_FIELD2=$( pad_to_len "${FIELD2}" 7)
		local PAD_FIELD3=$( pad_to_len "${FIELD3}" 12)
		local PAD_FIELD4=$( pad_to_len "${FIELD4}" 13)
		local PAD_FIELD5=$( pad_to_len "${FIELD5}" 9)		
		local PAD_FIELD6=$( pad_to_len "${FIELD6}" 31)
		if [[ ! "$FIELD1" =~ ^[[:space:]]*$ ]]; then
			PRODUCTID="\"${PAD_FIELD1}${PAD_FIELD2}${PAD_FIELD3}${PAD_FIELD4}${PAD_FIELD5}${PAD_FIELD6}\""			
			PRINT_ENABLED=$TRUE			
			
			#FIELD1="${FIELD1//[[:space:]]/}"
			FIELD1="\n\troj[${FIELD1}]"			
			
			#FIELD2="${FIELD2//[[:space:]]/}"
			FIELD2="\n\trevision[${FIELD2}]"
			
			#FIELD3="${FIELD3//[[:space:]]/}"
			FIELD3="\n\tboard[${FIELD3}]"
			
			#FIELD4="${FIELD4//[[:space:]]/}"
			FIELD4="\n\tserial[${FIELD4}]"
			
			#FIELD5="${FIELD5//[[:space:]]/}"
			FIELD5="\n\tdate[${FIELD5}]"
			
			#FIELD6="${FIELD6//[[:space:]]/}"
			FIELD6="\n\tmanufacturer[${FIELD6}]"
		else
			PRODUCTID='""'
			is_verbose && PRINT_ENABLED=$TRUE
		fi
		local SLOT_OUT=$(printf 'slot[%2d]' $slot)
		local BOARD_OUT=$(printf 'board[%10s]' $(get_name_by_slot $slot))
		local PRODUCTID_OUT="${PRODUCTID}"
		is_verbose && PRODUCTID_OUT="${FIELD1}${FIELD2}${FIELD3}${FIELD4}${FIELD5}${FIELD6} "
		
		if [ $OPT_ALL_SLOTS -eq $TRUE ]; then
			[ $PRINT_ENABLED -eq $TRUE ] && log "${SLOT_OUT}: ${PRODUCTID_OUT}"
		else
			[ $PRINT_ENABLED -eq $TRUE ] && log "${SLOT_OUT} ${BOARD_OUT}: ${PRODUCTID_OUT}"
		fi
	done
	return $TRUE
}

function GET_RTFDFLAG(){
	local slot=$BOARD
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "Get the RtfdStartedFlag status from the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	local snmpres='' 
	local OID="$(get_oid_for_slot OID_GET_GPR_RAM_REG $slot)"
	for IP in $IP_LIST; do
		snmpres=$(snmpget -L n -v 2c -c NETMAN $IP ${OID} 2>/dev/null | awk -F ':' '{print $4}' | awk -F ' ' '{print $5}')
		if [[ -n "$snmpres" ]]; then
			local flag=${snmpres:0:1}
			if [[ "$flag" =~ '8'|'9'|[A-F]|[a-f] ]]; then
   				log "RtfdStartedFlag on"
				return $TRUE
			else
   				log "RtfdStartedFlag off"
				return $TRUE
			fi
		fi
	done
       	abort 'snmp request failed' 
}

function SET_BOOTDEV(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && SET_BOOTDEV_v1
	[[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && SET_BOOTDEV_v5
	return $TRUE
}

function SET_BOOTDEV_v1(){
	local slot=$BOARD
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "setting the first boot device of the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	local BOOTDEV=''
	if [ $OPT_ETH -eq $TRUE ]; then
		BOOTDEV=$OPT_ETH_ARG
		[[ ! $BOOTDEV =~ ^eth[0-9]$ ]] && BOOTDEV="eth${BOOTDEV}"
	elif [ $OPT_DISK -eq $TRUE ]; then
		BOOTDEV=$OPT_DISK_ARG
	fi
	local DEV_ID=$(get_id_by_dev $BOOTDEV)
	local MASK='FF000000'
	local REGISTER="${MASK}${DEV_ID}"

	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	local snmpres1=''
	local snmpres=''
	
	# Set the value in the GPR/BCS register
	local OID="$(get_oid_for_slot OID_SET_BOOTDEV $slot)"
	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c NETMAN $IP ${OID} x "${REGISTER}" 2>/dev/null | grep "$hexGrep")
		if [[ $snmpres =~ $hexRegExp ]]; then
			log "the boot device of the board $BOARD has been set to $BOOTDEV (0x${DEV_ID} & 0x${MASK})"
			return $TRUE
		fi
	done
	abort 'snmp request failed' 
}

function SET_BOOTDEV_v5(){
	local slot=$BOARD
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "setting the first boot device of the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	local BOOTDEV=''
	if [ $OPT_ETH -eq $TRUE ]; then
		BOOTDEV=$OPT_ETH_ARG
		[[ ! $BOOTDEV =~ ^eth[0-9]$ ]] && BOOTDEV="eth${BOOTDEV}"
	elif [ $OPT_DISK -eq $TRUE ]; then
		BOOTDEV=$OPT_DISK_ARG
	fi
	local DEV_ID=$(get_id_by_dev $BOOTDEV)
	
	local snmpres=''
	local MASK='FF00000000000000000000000000000000000000000000000000000000000000'
	local DEV_ID_FILLIN='FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'
	DEV_ID=${DEV_ID:0:2}
	local REGISTER="${DEV_ID}${DEV_ID_FILLIN}${MASK}"
	
	# Set the calculated value in the GPR register
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	local OID="$(get_oid_for_slot OID_SET_BOOTDEV_v5 $slot)"
	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c NETMAN $IP ${OID} x "$REGISTER" 2>/dev/null | grep "$hexGrep")
		if [[ $snmpres =~ $hexGrep ]]; then
			log "the boot device of the board $BOARD has been set to $BOOTDEV (0x${REGISTER})"
			return $TRUE
		fi
	done
	abort 'snmp request failed'
}

function SET_BAUDRATE(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && SET_BAUDRATE_v1
	[[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && SET_BAUDRATE_v5
	return $TRUE
}

function SET_BAUDRATE_v1(){
    	local slot=$BOARD
    	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
    	is_verbose && log "setting baudrate of the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
    	
	local BAUDRATE=$OPT_BAUD_ARG
    	local BAUD_ID=$(get_id_by_baudrate $BAUDRATE)
	local MASK='00060000'
	local REGISTER="${MASK}${BAUD_ID}"
    	local snmpres1=''
    	local snmpres=''

	# First get the current GPR register
    	local OID=$(get_oid_for_slot OID_SET_BAUDRATE $slot)
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"

	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c NETMAN $IP ${OID} x "${REGISTER}" 2>/dev/null | grep "$hexGrep")
		if [[ $snmpres =~ $hexRegExp ]]; then
		        log "the baudrate of the board $BOARD has been set to $BAUDRATE (0x${BAUD_ID} & 0x${MASK})"
			return $TRUE
    		fi
	done
	abort 'snmp request failed'
}

function SET_BAUDRATE_v5(){
	abort 'This option is not supported on GEP5 and GEP7 hardware generation'
}

function SET_MASTER(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && SET_MASTER_v1
	[[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && SET_MASTER_v5
	return $TRUE
}

function SET_MASTER_v1(){
	local SLOT_LIST="$(get_slot_by_name 'sc_a') $(get_slot_by_name 'sc_b')"
	for SLOT in $SLOT_LIST; do
		local OID="$(get_oid_for_slot OID_GET_AUTONOMOUS $SLOT)"
		local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
		for IP in $IP_LIST; do
			snmpres=$(snmpget -L o -v 2c -c NETMAN $IP ${OID} 2>$ERR_TMP | grep "$intGrep")
			if [[ $snmpres =~ $intRegExp ]]; then
				local AUTONOMOUS=$(echo "$snmpres" | awk -F'= ' '{print $2}' | awk -F': ' '{print $2}')
				if [ ${AUTONOMOUS} == '1' ]; then			
					log "unable to proceed: boards are in autonomous mode (masterhip is automatically set)"
					return $TRUE
				fi
			fi
		done
	done
	abort 'snmp request failed'
	#
	# TO DO: handle mastership change
	#
	# snmpset -v 2c -c NETMAN <SOON_TO_BE_SLAVE_SCX> .1.3.6.1.4.1.193.177.2.2.1.2.1.7.0 i 0
	# snmpset -v 2c -c NETMAN <SOON_TO_BE_MASTER_SCX> .1.3.6.1.4.1.193.177.2.2.1.2.1.7.0 i 1
	# snmpset -v 2c -c NETMAN <SLAVE_SCX> .1.3.6.1.4.1.193.177.2.2.1.2.1.7.0 i 1
}

function SET_MASTER_v5(){
	local SLOT_LIST="$(get_slot_by_name 'sc_a') $(get_slot_by_name 'sc_b')"
	for SLOT in $SLOT_LIST; do
		local OID="$(get_oid_for_slot OID_GET_AUTONOMOUS_v5 $SLOT)"
		local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
		for IP in $IP_LIST; do
			snmpres=$(snmpget -L o -v 2c -c NETMAN $IP ${OID} 2>$ERR_TMP | grep "$intGrep")
			if [[ $snmpres =~ $intRegExp ]]; then
				local AUTONOMOUS=$(echo "$snmpres" | awk -F'= ' '{print $2}' | awk -F': ' '{print $2}')
				if [ ${AUTONOMOUS} == '1' ]; then			
					log "unable to proceed: boards are in autonomous mode (masterhip is automatically set)"
					return $TRUE
				fi
			fi
		done
	done
	abort 'snmp request failed'
	#
	# TO DO: handle mastership change
	#
	# snmpset -v 2c -c NETMAN <SOON_TO_BE_SLAVE_SCX> .1.3.6.1.4.1.193.177.2.2.1.2.1.7.0 i 0
	# snmpset -v 2c -c NETMAN <SOON_TO_BE_MASTER_SCX> .1.3.6.1.4.1.193.177.2.2.1.2.1.7.0 i 1
	# snmpset -v 2c -c NETMAN <SLAVE_SCX> .1.3.6.1.4.1.193.177.2.2.1.2.1.7.0 i 1
}

function SET_POWER(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && SET_POWER_v1
	[[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && SET_POWER_v5
	return $TRUE
}

function SET_POWER_v1(){
	local slot=$BOARD
	local state=''
	local OID=''
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "powering $OPT_STATE_ARG the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	local POWER_STATE=''
	if [ $OPT_STATE_ARG == 'on' ]; then
		OID="$(get_oid_for_slot OID_SET_POWER_ON $slot)"
		POWER_STATE=1
	elif [ $OPT_STATE_ARG == 'off' ]; then
		OID="$(get_oid_for_slot OID_SET_POWER_OFF $slot)"
		POWER_STATE=0
	else
		abort "wrong state: $OPT_STATE_ARG"
	fi
	
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"	
	local snmpres=''
	
  	for IP in $IP_LIST; do	
		snmpres=$(snmpset -L n -v 2c -c NETMAN $IP ${OID} i ${POWER_STATE} 2>/dev/null | grep "$intGrep")
		if [[ $snmpres =~ $intRegExp ]]; then
			log "the board \"$BOARD\" has been successfully powered $OPT_STATE_ARG"
			return $TRUE
		fi
	done
	abort 'snmp request failed'
}

function SET_POWER_v5(){
	local slot=$BOARD
	local state=''
	local OID=''
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "powering $OPT_STATE_ARG the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	local POWER_STATE=''
	if [ $OPT_STATE_ARG == 'on' ]; then
		OID="$(get_oid_for_slot OID_SET_POWER_ON_v5 $slot)"
		POWER_STATE=1
	elif [ $OPT_STATE_ARG == 'off' ]; then
		OID="$(get_oid_for_slot OID_SET_POWER_OFF_v5 $slot)"
		POWER_STATE=0
	else
		abort "wrong state: $OPT_STATE_ARG"
	fi
	
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	local snmpres=''
	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c NETMAN $IP ${OID} i ${POWER_STATE} 2>/dev/null | grep "$intGrep")
		if [[ $snmpres =~ $intRegExp ]]; then
			log "the board \"$BOARD\" has been successfully powered $OPT_STATE_ARG"
			return $TRUE
		fi
	done
	abort 'snmp request failed'
}

function SET_REBOOT(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && SET_REBOOT_v1
	[[ $HW_TYPE =~ 'GEP5' || $HW_TYPE =~ 'GEP7' ]] && SET_REBOOT_v5
	return $TRUE
}

function SET_REBOOT_v1(){
	local slot=$BOARD
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "sending a reboot command to the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	
	local snmpres=''
	local OID="$(get_oid_for_slot OID_SET_REBOOT $slot)"
	# 0: cold reset
	# 1: warm reset
	# 4: NMI reset
	local reset='1'

	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c NETMAN $IP ${OID} i $reset 2>/dev/null | grep "$intGrep")
		if [[ $snmpres =~ $intRegExp ]]; then
			log "the board \"$BOARD\" has been successfully reset"
			return $TRUE
		fi
	done
	abort 'snmp request failed'
}

function SET_REBOOT_v5(){
	local slot=$BOARD
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "sending a reboot command to the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	
	local ipSC_A=$(get_ip_by_name sc_a ipna)
	local ipSC_B=$(get_ip_by_name sc_b ipna)	
	local snmpres=''
	local OID="$(get_oid_for_slot OID_SET_REBOOT_v5 $slot)"
	# 0: cold reset
	# 1: warm reset
	# 4: NMI reset
	local reset='1'
	
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c NETMAN $IP ${OID} i $reset 2>/dev/null | grep "$intGrep")
		if [[ $snmpres =~ $intRegExp ]]; then
			log "the board \"$BOARD\" has been successfully reset"
			return $TRUE
		fi
	done
	abort 'snmp request failed'
}

function SET_CLEARRTFD(){
	local slot=$BOARD
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)

	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	local snmpres=''
	local OID="$(get_oid_for_slot OID_SET_BIOS_IMAGE $slot)"

        # 0: fallback image
        # 1: upg image
	local bios_image='1'

	#
	# OID_SET_BIOS_IMAGE
	#
	count=false
        for IP in $IP_LIST; do
                 snmpres=$(snmpset -L n -v 2c -c NETMAN $IP ${OID} i $bios_image 2>/dev/null | grep "$intGrep")
                if [[ $snmpres =~ $intRegExp ]]; then
                        log "the default bios image has been successfully set"
                        count=true
			break 
                fi
        done
        if [ $count != true ]; then
                abort 'snmp request failed on bios image'
        fi
	

	#
	# OID_SET_BIOS_POINTER
	#

	local OID="$(get_oid_for_slot OID_SET_BIOS_POINTER $slot)"
	
	# 0: fallback image
        # 1: upg image 
	count=false
	local bios_pointer='1'
	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c NETMAN $IP ${OID} i $bios_pointer 2>/dev/null | grep "$intGrep")
		if [[ $snmpres =~ $intRegExp ]]; then
			log "the default bios pointer has been successfully set"
			count=true
			break
		fi
	done
	
	if [ $count != true ]; then
                abort 'snmp request failed on bios pointer'
        fi

#
	# OID_SET_GPR_RAM_REG
	#

	local OID="$(get_oid_for_slot OID_SET_GPR_RAM_REG $slot)"
	 
	# mask bit to set 
	local MASK='80000000'

	# value bit to set
	local VALUE='00000000'

	# prepare parameter 
	count=false
	local REGISTER="${MASK}${VALUE}"
	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c NETMAN $IP ${OID} x "$REGISTER" 2>/dev/null | grep "$hexGrep")
		if [[ $snmpres =~ $hexRegExp ]]; then
			log "the RtfdStartedFlag flag has been successfully cleared"
			count=true
                        break
		fi
	done
	if [ $count != true ]; then
                abort 'snmp request failed on GPR ram register'
        else
                return $TRUE
        fi

}
