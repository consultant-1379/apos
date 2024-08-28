#------------------------------------------------------------------------------#
# ROJ 208 323                                                                  #
# snmp queries to be used in a SCB-based EGEM magazine.                        #
#------------------------------------------------------------------------------#
# NOTES: - This file is intended to be sourced by the shelfmngr routines so it #
#        MUST be compliant with the bash syntax.                               #
#------------------------------------------------------------------------------#
export SLOT_MIN=0
export SLOT_MAX=25

function GET_BOOTDEV(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && GET_BOOTDEV_v1
	[[ $HW_TYPE =~ 'GEP5' ]] && GET_BOOTDEV_v5
	return $TRUE
}

function GET_BOOTDEV_v1(){
	local slot=$BOARD
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "querying the first boot device of the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	local BOOTDEV=''
	local snmpres1=''
	local snmpres=''

        local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
        local OID="$(get_oid_for_slot OID_GET_BOOTDEV $slot)"
                for IP in $IP_LIST; do
		        snmpres1=$(snmpget -L n -v 2c -c public $IP ${OID} 2>/dev/null| awk '{print $4}')
		        snmpres=$(echo $snmpres1 | cut -c2-9)
		        if [ ! -z $snmpres ]; then
        		        BOOTDEV=$(get_dev_by_id $snmpres)
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
        local snmpres1=''
        local snmpres=''

        local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
        local OID="$(get_oid_for_slot OID_GET_BOOTDEV_v5 $slot)"
                for IP in $IP_LIST; do
			snmpres1=$(snmpget -L n -v 2c -c public $IP ${OID} 2>/dev/null | grep "$hexGrep")
        		snmpres=$( echo $snmpres1 | cut -d : -f4 | cut -c1-12 | sed 's@[[:space:]+]*@@g')
                        if [ ! -z $snmpres ]; then
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
	[[ $HW_TYPE =~ 'GEP5' ]] && GET_BAUDRATE_v5
	return $TRUE
}

function GET_BAUDRATE_v1(){
	local slot=$BOARD
    	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "querying the baudrate of board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	local BAUDRATE=''
        local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
        local OID="$(get_oid_for_slot OID_GET_BAUDRATE $slot)"
        for IP in $IP_LIST; do
              	local snmpres1=$(snmpget -L n -v 2c -c public $IP ${OID} 2>/dev/null| awk '{print $4}')
		local snmpres=`echo $snmpres1 | cut -c2-9`
    		if [ ! -z $snmpres ]; then
        		BAUDRATE=$(get_baud_by_id $snmpres)
        		is_verbose && BAUDRATE="${BAUDRATE} (0x${snmpres})"
			log $BAUDRATE
			return $TRUE
               fi
        done
        abort 'snmp request failed'
}

function GET_BAUDRATE_v5(){
	abort 'This option is not supported on GEP5 hardware generation'
}

function GET_MAC(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && GET_MAC_v1
	[[ $HW_TYPE =~ 'GEP5' ]] && GET_MAC_v5
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
	
	local ETH_LIST=''
	if [ $OPT_ETH -eq $TRUE ]; then
		if [ $OPT_ETH_ARG == 'all' ]; then
			ETH_LIST='eth0 eth1 eth2 eth3 eth4'
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
			abort 'eth0, eth1 and eth2 are only valid for apub boards'
		fi
		for S in $SLOT_LIST; do
			[[ $S -ne $APA && $S -ne $APB ]] && abort 'eth0, eth1 and eth2 are only valid for apub boards'
		done
	fi
	
	for SLOT in $SLOT_LIST; do
		if is_verbose || [ $OPT_ALL_SLOTS -eq $TRUE ] || [ $OPT_ALL_BOARDS -eq $TRUE ]; then
			log "slot[${SLOT}]"
		fi
		for ETH in $ETH_LIST; do			
			local OID=''
			local OFFSET=0
			if [ $OPT_BASE -eq $TRUE ]; then
				OID="$(get_oid_for_slot OID_GET_MAC_BASE ${SLOT})"
			elif [ $OPT_ETH -eq $TRUE ]; then
				if [ $ETH == "eth3" ]; then
					OID="$(get_oid_for_slot OID_GET_MAC_ETH3 ${SLOT})"
				else
					OID="$(get_oid_for_slot OID_GET_MAC_ETH4 ${SLOT})"
					case $ETH in
						eth4)
							OFFSET=0
						;;
						eth2)
							OFFSET=1
						;;
						eth0)
							OFFSET=3
						;;
						eth1)
							OFFSET=4
						;;
					esac			
				fi
			fi
			local snmpres=''
			local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"	
			for IP in $IP_LIST; do
				snmpres=$(snmpget -L n -v 2c -c public $IP ${OID} 2>/dev/null | grep "$hexGrep")
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
			if [ $OPT_BASE -eq $TRUE ]; then
				OID="$(get_oid_for_slot OID_GET_MAC_BASE_v5 ${SLOT})"
			elif [ $OPT_ETH -eq $TRUE ]; then
				if [ $ETH == "eth3" ]; then
					OID="$(get_oid_for_slot OID_GET_MAC_ETH3_v5 ${SLOT})"
				else
					OID="$(get_oid_for_slot OID_GET_MAC_ETH4_v5 ${SLOT})"
					case $ETH in
						eth0)
							OFFSET=6
						;;	
						eth1)
							OFFSET=7
						;;
						eth2)
							OFFSET=1
						;;
						eth3)
							OFFSET=-1
						;;
						eth4)
							OFFSET=0
						;;
						eth5)
							OFFSET=3
						;;
						eth6)
							OFFSET=4
						;;
					esac			
				fi
			fi
			
			local snmpres=''
                        local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
                        for IP in $IP_LIST; do
                                snmpres=$(snmpget -L n -v 2c -c public $IP ${OID} 2>/dev/null | grep "$hexGrep")
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
	[[ $HW_TYPE =~ 'GEP5' ]] && GET_MASTER_v5
	return $TRUE
}

function GET_MASTER_v1(){
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	local SLOT_LIST="$(get_slot_by_name 'sc_a') $(get_slot_by_name 'sc_b')"
	for SLOT in $SLOT_LIST; do 
		local OID="$(get_oid_for_slot OID_GET_MASTER $SLOT)"
		for IP in $IP_LIST; do
			local snmpres=$(snmpget -L o -v 2c -c public $IP ${OID} 2>$ERR_TMP | grep "$intGrep")
			if [[ $snmpres =~ $intRegExp ]]; then
				if [ ${BASH_REMATCH[1]} == '1' ]; then						
					log $( get_board_by_ip "$IP" )			
					return $TRUE
				fi
			fi
		done	
	done
        abort 'snmp request failed'
}

function GET_MASTER_v5(){
        local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
        local SLOT_LIST="$(get_slot_by_name 'sc_a') $(get_slot_by_name 'sc_b')"
        for SLOT in $SLOT_LIST; do
                local OID="$(get_oid_for_slot OID_GET_MASTER_v5 $SLOT)"
                for IP in $IP_LIST; do
                        local snmpres=$(snmpget -L o -v 2c -c public $IP ${OID} 2>$ERR_TMP | grep "$intGrep")
                        if [[ $snmpres =~ $intRegExp ]]; then
                                if [ ${BASH_REMATCH[1]} == '1' ]; then
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
	[[ $HW_TYPE =~ 'GEP5' ]] && GET_PRODUCTID_v5
	return $TRUE
}

function GET_PRODUCTID_v1(){
	local SLOTS=''
	if [[ $OPT_ALL_BOARDS -eq $TRUE || $OPT_ALL_SLOTS -eq $TRUE ]]; then
		SLOTS=$(seq -s ' ' $SLOT_MIN $SLOT_MAX)
	else
		SLOTS=$BOARD
		! is_slot $BOARD && SLOTS=$(get_slot_by_name $BOARD)
	fi	
		
	local PRODUCTID=''
	local snmpres=''
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for slot in $SLOTS; do
		local OID="$(get_oid_for_slot OID_GET_PRODUCTID ${slot})"
		# is_verbose && log "querying the product id of the board $(get_name_by_slot ${slot}) (slot $slot)... "
		for IP in $IP_LIST; do
			 snmpres=$(snmpget -L n -v 2c -c public $IP ${OID} 2>/dev/null | grep "$strGrep")
                	 if [[  $snmpres =~ $strRegExp ]]; then
                  		break 
                	 fi
                done
		
		local PRINT_ENABLED=$FALSE
		local FIELD1=''
		local FIELD2=''
		local FIELD3=''
		local FIELD4=''
		local FIELD5=''
		local FIELD6=''
		if [[ $snmpres =~ $strRegExp ]]; then
			PRODUCTID=${BASH_REMATCH[1]}			
			PRINT_ENABLED=$TRUE			
			# 1-24
			FIELD1=$(echo "${PRODUCTID:1:24}" | sed 's@[[:space:]+]*$@@g')
			FIELD1="\n\troj[${FIELD1}]"			
			# 25-7
			FIELD2=$(echo "${PRODUCTID:25:7}" | sed 's@[[:space:]+]*$@@g')
			FIELD2="\n\trevision[${FIELD2}]"
			# 32-12
			FIELD3=$(echo "${PRODUCTID:32:12}" | sed 's@[[:space:]+]*$@@g')
			FIELD3="\n\tboard[${FIELD3}]"
			# 44-13
			FIELD4=$(echo "${PRODUCTID:44:13}" | sed 's@[[:space:]+]*$@@g')
			FIELD4="\n\tserial[${FIELD4}]"
			# 57-9
			FIELD5=$(echo "${PRODUCTID:57:9}" | sed 's@[[:space:]+]*$@@g')
			FIELD5="\n\tdate[${FIELD5}]"
			# 66-31			
			FIELD6=$(echo "${PRODUCTID:66:31}" | sed 's@[[:space:]+]*$@@g')
			FIELD6="\n\tmanufacturer[${FIELD6}]"
		else
			PRODUCTID='""'
			is_verbose && PRINT_ENABLED=$TRUE
		fi
		local SLOT_OUT=$(printf 'slot[%2d]' $slot)
		local BOARD_OUT=$(printf 'board[%10s]' $(get_name_by_slot $slot))
		local PRODUCTID_OUT="$PRODUCTID"
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
    local SLOTS=''
	if [[ $OPT_ALL_BOARDS -eq $TRUE || $OPT_ALL_SLOTS -eq $TRUE ]]; then
		SLOTS=$(seq -s ' ' $SLOT_MIN $SLOT_MAX)
	else
		SLOTS=$BOARD
		! is_slot $BOARD && SLOTS=$(get_slot_by_name $BOARD)
	fi	
		
	local PRODUCTID=''
	local snmpres=''
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for slot in $SLOTS; do
		local OID="$(get_oid_for_slot OID_GET_PRODUCTID_v5 ${slot})"
		# is_verbose && log "querying the product id of the board $(get_name_by_slot ${slot}) (slot $slot)... "
		for IP in $IP_LIST; do
			snmpres=$(snmpget -L n -v 2c -c public $IP ${OID} 2>/dev/null | grep "$strGrep")
			if [[  $snmpres =~ $strRegExp ]]; then
				break		
			fi
		done
		local PRINT_ENABLED=$FALSE
		local FIELD1=''
		local FIELD2=''
		local FIELD3=''
		local FIELD4=''
		local FIELD5=''
		local FIELD6=''
		if [[ $snmpres =~ $strRegExp ]]; then
			PRODUCTID=${BASH_REMATCH[1]}			
			PRINT_ENABLED=$TRUE			
			# 1-24
			FIELD1=$(echo "${PRODUCTID:1:24}" | sed 's@[[:space:]+]*$@@g')
			FIELD1="\n\troj[${FIELD1}]"			
			# 25-7
			FIELD2=$(echo "${PRODUCTID:25:7}" | sed 's@[[:space:]+]*$@@g')
			FIELD2="\n\trevision[${FIELD2}]"
			# 32-12
			FIELD3=$(echo "${PRODUCTID:32:12}" | sed 's@[[:space:]+]*$@@g')
			FIELD3="\n\tboard[${FIELD3}]"
			# 44-13
			FIELD4=$(echo "${PRODUCTID:44:13}" | sed 's@[[:space:]+]*$@@g')
			FIELD4="\n\tserial[${FIELD4}]"
			# 57-9
			FIELD5=$(echo "${PRODUCTID:57:9}" | sed 's@[[:space:]+]*$@@g')
			FIELD5="\n\tdate[${FIELD5}]"
			# 66-31			
			FIELD6=$(echo "${PRODUCTID:66:31}" | sed 's@[[:space:]+]*$@@g')
			FIELD6="\n\tmanufacturer[${FIELD6}]"
		else
			PRODUCTID='""'
			is_verbose && PRINT_ENABLED=$TRUE
		fi
		local SLOT_OUT=$(printf 'slot[%2d]' $slot)
		local BOARD_OUT=$(printf 'board[%10s]' $(get_name_by_slot $slot))
		local PRODUCTID_OUT="$PRODUCTID"
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
	
	local snmpres='' 
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
        local OID="$(get_oid_for_slot OID_GET_GPR_RAM_REG $slot)"
        for IP in $IP_LIST; do
                snmpres=$(snmpget -L n -v 2c -c public $IP ${OID} 2>/dev/null | awk -F ':' '{print $4}' | awk -F '"' '{print $2}')
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
	[[ $HW_TYPE =~ 'GEP5' ]] && SET_BOOTDEV_v5
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
	local snmpres1=''
	local snmpres=''
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"

	# First get the current GPR register
	local OID="$(get_oid_for_slot OID_GET_BOOTDEV $slot)"
        for IP in $IP_LIST; do
		snmpres1=$(snmpget -L n -v 2c -c public $IP ${OID} 2>/dev/null| awk '{print $4}')
		snmpres=`echo $snmpres1 | cut -c2-9`
		if [ ! -z $snmpres ]; then
			# Make a bit-wise AND
			local REGISTER=$(compute_bootdev_bits $snmpres $DEV_ID)
			# Set the calculated value in the GPR register
			local OID="$(get_oid_for_slot OID_SET_BOOTDEV $slot)"
			snmpres=$(snmpset -L n -v 2c -c public $IP ${OID} s "$REGISTER" 2>/dev/null | grep "$strGrep")
	                if [[ $snmpres =~ $strGrep ]]; then
        	                log "the boot device of the board $BOARD has been set to $BOOTDEV (0x${REGISTER})"
                	        return $TRUE
                	fi
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
		snmpres=$(snmpset -L n -v 2c -c public $IP ${OID} x "$REGISTER" 2>/dev/null | grep "$hexGrep")
		if [[ $snmpres =~ $hexGrep ]]; then
			log "the boot device of the board $BOARD has been set to $BOOTDEV (0x${REGISTER})"
			return $TRUE
		fi
	done
	abort 'snmp request failed' 
}

function SET_BAUDRATE(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && SET_BAUDRATE_v1
	[[ $HW_TYPE =~ 'GEP5' ]] && SET_BAUDRATE_v5
	return $TRUE
}

function SET_BAUDRATE_v1(){
        local slot=$BOARD
        ! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
        is_verbose && log "querying the baudrate of board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
        local BAUDRATE=$OPT_BAUD_ARG
        local BAUD_ID=$(get_id_by_baudrate $BAUDRATE)
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
        local OID="$(get_oid_for_slot OID_GET_BAUDRATE $slot)"
        for IP in $IP_LIST; do
                local snmpres1=$(snmpget -L n -v 2c -c public $IP ${OID} 2>/dev/null| awk '{print $4}')
                local snmpres=$(echo $snmpres1 | cut -c2-9)
                if [ ! -z $snmpres ]; then
	        	# Make a bit-wise AND
			local REGISTER=$(compute_baudrate_bits $snmpres $BAUD_ID)
       			# Set the calculated value in the GPR register
			local OID=$(get_oid_for_slot OID_SET_BAUDRATE $slot)
    			snmpres=$(snmpset -L n -v 2c -c public $IP ${OID} s "$REGISTER" 2>/dev/null | grep "$strGrep")
			if [[ $snmpres =~ $strGrep ]]; then
            			log "the baudrate of the board $BOARD has been set to $BAUDRATE (0x${REGISTER})"
    				return $TRUE
			fi
		fi
        done
        abort 'snmp request failed'
}

function SET_BAUDRATE_v5(){
	abort 'This option is not supported on GEP5 hardware generation'
}

function SET_MASTER(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && SET_MASTER_v1
	[[ $HW_TYPE =~ 'GEP5' ]] && SET_MASTER_v5
	return $TRUE
}

function SET_MASTER_v1(){
	local snmpres=''	
	local OID=''

	# set slave (not-master) both the SCs on both the network planes.
        local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
        local SLOT_LIST="$(get_slot_by_name 'sc_a') $(get_slot_by_name 'sc_b')"
        for SLOT in $SLOT_LIST; do
                OID="$(get_oid_for_slot OID_SET_MASTER $SLOT)"
                for IP in $IP_LIST; do
                        snmpres=$(snmpset -L o -v 2c -c public $IP ${OID} i 0 2>/dev/null | grep "$intGrep")
                        if [[ $snmpres =~ $intRegExp ]]; then
                                if [ ${BASH_REMATCH[1]} == '1' ]; then
					break
                                fi
                        fi
                done
        done
	
	if [ $OPT_BOARD -eq $TRUE ]; then
		local slot=$BOARD
		local ip_a=''
		local ip_b=''
		if ! is_slot $BOARD; then
			slot=$(get_slot_by_name $BOARD)
			ip_a=$(get_ip_by_name $BOARD ipna)
			ip_b=$(get_ip_by_name $BOARD ipnb)
		else		
			ip_a=$(get_ip_by_name $(get_name_by_slot $BOARD) ipna)
			ip_b=$(get_ip_by_name $(get_name_by_slot $BOARD) ipnb)
		fi
		is_verbose && log "setting the mastership to the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
		local IP_LIST="$ip_a $ip_b"
		# set master the specified board on both the network planes.
		OID="$(get_oid_for_slot OID_SET_MASTER $slot)"
		for IP in $IP_LIST; do
                        snmpres=$(snmpset -L o -v 2c -c public $IP ${OID} i 1 2>/dev/null | grep "$intGrep")
	                if [[ $snmpres =~ $intRegExp ]]; then
                                if [ ${BASH_REMATCH[1]} == '1' ]; then
                                        log "mastership set to the board \"$BOARD\""
					return $TRUE
                                fi
                        fi
                done
		abort 'snmp request failed'
	else
		log "mastership set to \"none\""
		
	fi
	return $TRUE
}

function SET_MASTER_v5(){
	local snmpres=''	
	local OID=''
	
	# set slave (not-master) both the SCs on both the network planes.

	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	local SLOT_LIST="$(get_slot_by_name 'sc_a') $(get_slot_by_name 'sc_b')"
	for SLOT in $SLOT_LIST; do
		OID="$(get_oid_for_slot OID_SET_MASTER_v5 $SLOT)"	
		for IP in $IP_LIST; do
			snmpres=$(snmpset -L o -v 2c -c public $IP ${OID} i 0 2>/dev/null | grep "$intGrep")
				if [[ $snmpres =~ $intRegExp ]]; then
	                                if [ ${BASH_REMATCH[1]} == '1' ]; then
						break	
					fi
				fi
		done
	done
	
	if [ $OPT_BOARD -eq $TRUE ]; then
		local slot=$BOARD
		local ip_a=''
		local ip_b=''
		if ! is_slot $BOARD; then
			slot=$(get_slot_by_name $BOARD)
			ip_a=$(get_ip_by_name $BOARD ipna)
			ip_b=$(get_ip_by_name $BOARD ipnb)
		else		
			ip_a=$(get_ip_by_name $(get_name_by_slot $BOARD) ipna)
			ip_b=$(get_ip_by_name $(get_name_by_slot $BOARD) ipnb)
		fi
		is_verbose && log "setting the mastership to the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
		local IP_LIST="$ip_a $ip_b"
		# set master the specified board on both the network planes.
		OID="$(get_oid_for_slot OID_SET_MASTER_v5 $slot)"
		for IP in $IP_LIST; do
			snmpres=$(snmpset -L o -v 2c -c public $IP ${OID} i 1 2>/dev/null | grep "$intGrep")
			if [[ $snmpres =~ $intRegExp ]]; then
				if [ ${BASH_REMATCH[1]} == '1' ]; then
					log "mastership set to the board \"$BOARD\""
					return $TRUE
				fi
			fi
		done
		abort 'snmp request failed'
	else
		log "mastership set to \"none\""
	fi
	return $TRUE
}

function SET_POWER(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && SET_POWER_v1
	[[ $HW_TYPE =~ 'GEP5' ]] && SET_POWER_v5
	return $TRUE
}

function SET_POWER_v1(){
	local slot=$BOARD
	local state=''
	local OID=''
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "powering $OPT_STATE_ARG the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	if [ $OPT_STATE_ARG == 'on' ]; then
		OID="$(get_oid_for_slot OID_SET_POWER_ON $slot)"
	elif [ $OPT_STATE_ARG == 'off' ]; then
		OID="$(get_oid_for_slot OID_SET_POWER_OFF $slot)"
	else
		abort "wrong state: $OPT_STATE_ARG"
	fi
	
	local snmpres=''
	
  	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for IP in $IP_LIST; do	
		snmpres=$(snmpset -L n -v 2c -c public $IP ${OID} i 0 2>/dev/null | grep "$intGrep")
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
	if [ $OPT_STATE_ARG == 'on' ]; then
		OID="$(get_oid_for_slot OID_SET_POWER_ON_v5 $slot)"
	elif [ $OPT_STATE_ARG == 'off' ]; then
		OID="$(get_oid_for_slot OID_SET_POWER_OFF_v5 $slot)"
	else
		abort "wrong state: $OPT_STATE_ARG"
	fi
	
	local snmpres=''
	
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c public $IP ${OID} i 0 2>/dev/null | grep "$intGrep")
		if [[ $snmpres =~ $intRegExp ]]; then
			log "the board \"$BOARD\" has been successfully powered $OPT_STATE_ARG"
			return $TRUE
		fi
	done
	abort 'snmp request failed'
}

function SET_REBOOT(){
	[[ $HW_TYPE =~ ^GEP1$|^GEP2$ ]] && SET_REBOOT_v1
	[[ $HW_TYPE =~ 'GEP5' ]] && SET_REBOOT_v5
	return $TRUE
}

function SET_REBOOT_v1(){
	local slot=$BOARD
	! is_slot $BOARD && slot=$(get_slot_by_name $BOARD)
	is_verbose && log "sending a reboot command to the board ${BOARD} $(! is_slot $BOARD && echo \(slot $slot\))... "
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	local snmpres=''
	local OID="$(get_oid_for_slot OID_SET_REBOOT $slot)"
	# 0: cold reset
	# 1: warm reset
	# 4: NMI reset
	local reset='1'
	
	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c public $IP ${OID} i $reset 2>/dev/null | grep "$intGrep")
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
	
	local snmpres=''
	local OID="$(get_oid_for_slot OID_SET_REBOOT_v5 $slot)"
	# 0: cold reset
	# 1: warm reset
	# 4: NMI reset
	local reset='1'
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
  	for IP in $IP_LIST; do	
		snmpres=$(snmpset -L n -v 2c -c public $IP ${OID} i $reset 2>/dev/null | grep "$intGrep")
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

	local snmpres=''
	local OID="$(get_oid_for_slot OID_SET_BIOS_IMAGE $slot)"

        # 0: fallback image
        # 1: upg image
	local bios_image='1'

	#
	# OID_SET_BIOS_IMAGE
	#
	local IP_LIST="$(get_ip_by_name sca ipna) $(get_ip_by_name sca ipnb) $(get_ip_by_name scb ipna) $(get_ip_by_name scb ipnb)"
	for IP in $IP_LIST; do
		snmpres=$(snmpset -L n -v 2c -c public $IP ${OID} i $bios_image 2>/dev/null | grep "$intGrep")
		if [[ $snmpres =~ $intRegExp ]]; then
			log "the default bios image has been successfully set"
			return $TRUE
		fi
	done
	abort 'snmp request failed'
}
