#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_hwinfo.sh
# Description:
#       A script to retrieve the main hardware information on real\simulated environment.
#       It tries to retrieve the info about the following properties:
#       1. The APG HW type.
#       2. The location of the disks.
#       3. The total number of data disks present onto the GEP5 board.
#       4. The overall size of the space of the disks.
#       5. The profile on the virtual environment.
#       6. The cluster IP retrieved with "/etc/cluster/nodes/this/mip/nbi/address".
#       7. The cluster IP retrieved with ifconfig command on active node.
#
#
# Note:
#	None.
##
# Usage:
#	None.
##
# Output:	A sequence of couple of values separated by semicolon is returned. Each couple is associated to a property: 
#							the first element indicates the value of property
#							the second element indicates the result of retrieving operation for that property(ERROR/NO_ERROR)
#				
#			Example:SC-2-1:# ./apos_hwinfo.sh --all
#					
#							hwversion=GEP5;NO_ERROR
#							hwtype=GEP7L_1600;NO_ERROR
#				 			diskslocation=ONBOARD;NO_ERROR
#							disksnumber=3;NO_ERROR
#							diskscapacity=1200;NO_ERROR
#							virtualenvprofile=VE0;NO_ERROR
#							clusterIP1=141.137.47.119;NO_ERROR
#							clusterIP2=141.137.47.119;NO_ERROR
#
#							
#			Below showed in details the possible values of the previous properties:
#							
#			1. hwversion		The APG HW type: 
#					 				"GEP1" or
#									"GEP2" or
#									... or
#									"GEPn"
#			2.diskslocation 	The location of the disks : "EXTERNAL" or "ONBOARD".
#			3.disksnumber		The total number of data disks present onto the GEP5 board : "1" or "3".
#			4.diskscapacity		The disks capacity in GB : 
#				 					"147" or
#				 					"300" or
#				 					"400" or
#									"450" or
#				 					"600" or
#				 					"1200" 
#			5.virtualenvprofile The profile of the virtual environment. 
#								The value is in the form "VEx" with x numeric value.
#								On native environment the value is set to "VE0".
#			6.clusterIP1        The cluster IP retrivied from mip folder (/etc/cluster/nodes/this/mip/nbi/address).
#			7.clusterIP2        The cluster IP retrivied from ifconfig command.
#			8. hwtype      	The APG HW specific board type: 
#					 				"GEP5_64_1200" or
#									"GEP7L_400" or
#									"GEP7L_1600" or
#									"GEP7_128_1600" or
#									... or
#									"GEPn"
#
##
# Return code : $TRUE  for execution successfully 
#				$FALSE for execution unsuccessfully 
##
# Changelog:
# - Mon Oct 2022 - P S Soumya (zpsxsou)
#       Added echo statement for 1300gb for disk capacity.
# - Wed Jun 2022 - Kishore Velkatoori (zkisvel)
#       Updated with VEN feature impacts
# - Fri Jan 24 2020 - Amit Varma (xamivar)
#       Updated with IPv6 impacts for virtual
# - Wed Jan 23 2018 - Raghavendra Rao Koduri(xkodrag)
#       intrduced new option hwtype 
# - Fri Dec 29 2017 -Parameswari Kotha (xparkot)
#        Updated the help message with new size values
# - Fri Jul 08 2016 - Pratap Reddy Uppada(xpraupp)
#       including APOS PLASIL impacts 
# - Thu Dec 10 2015 - Madhu Muthyala (xmadmut)
#       Updated for vAPG imapcts
# - Mon Mar 05 2015 - Giuseppe Pontillo (qgiupon)
#	First version.
##

APOS_DIR=/opt/ap/apos/conf
# Load the apos common functions.
. "${APOS_DIR}"/apos_common.sh


HWINFO_DB_FILE="/opt/ap/apos/conf/hwinfo.dat"
CLUSTERCONF_CMD="/opt/ap/apos/bin/clusterconf/clusterconf"
VM_DATADISK_CMD="/opt/ap/apos/conf/apos_is-datadisk.sh"
CMD_CUT=/usr/bin/cut

DEPLOYMENT_ENVIRONMENT_DIR="/var/log"
DEPLOYMENT_ENVIRONMENT_FILE="${DEPLOYMENT_ENVIRONMENT_DIR}/HWInfo"
APOS_PARM_CMD='/opt/ap/apos/bin/parmtool/parmtool'
ERI_DISKA="/dev/eri_diskA"
ERI_DISKB="/dev/eri_diskB"
VM_ERI_DISK="/dev/eri_disk"
IS_VAPG=$FALSE
DISK_CAPACITY_PATTERN="GEP1-2"

#CACHE info
CACHE_DIR="/dev/shm"
CACHE_FILE="${CACHE_DIR}/apos_hwinfo.cache"
CACHE_FILE_OWNER="root"
CACHE_FILE_GROUP="root"
CACHE_FILE_PERMISSIONS="644"

#Option value
HWVERSION_OPT=$FALSE
HWTYPE_OPT=$FALSE
DISKSLOCATION_OPT=$FALSE
DISKSNUMBER_OPT=$FALSE
DISKSCAPACITY_OPT=$FALSE
VIRTUALENVPROFILE_OPT=$FALSE
CLUSTERIP1_OPT=$FALSE
CLUSTERIP2_OPT=$FALSE
ALL_OPT=$FALSE
DEBUG=''
HELP=''
CLEAN=''

declare HWVERSION
declare HWTYPE
declare DISKSLOCATION
declare DISKSNUMBER
declare DISKSCAPACITY

function usage() {
	echo
	echo 'Usage:   apos_hwinfo.sh [--hwversion|-HWV] [--hwtype|-HWT] [--diskslocation|-DL] [--disksnumber|-DN] [--diskscapacity|-DC]'
	echo '                        [--virtualenvprofile|-VEP] [--clusterIP1|-CLIP1] [--clusterIP2|-CLIP2] [--all|-A] '
	echo '                        [--debug|-D] [--help|-H] [--cleancache|-CC]                                                         '
	echo
	echo 'Display the main hardware information.                                                                    '
	echo	
}

function checkOPT() {

	if [ $# == 0 ]; then
	   usage
	   exit $FALSE;
	fi
	
	while [ $# -ge 1 ]; do
			case "$1" in
					--)
						# No more options left.
						shift
						break
					   ;;
					-HWV|--hwversion)
							HWVERSION_OPT=$TRUE
							;;
					-HWT|--hwtype)
							HWTYPE_OPT=$TRUE
							;;
					-DL|--diskslocation)
							DISKSLOCATION_OPT=$TRUE
							
							;;
					-DN|--disksnumber)
							DISKSNUMBER_OPT=$TRUE
							;;
					-DC|--diskscapacity)
							DISKSCAPACITY_OPT=$TRUE
							;;
					-VEP|--virtualenvprofile)
							VIRTUALENVPROFILE_OPT=$TRUE
							;;
					-CLIP1|--clusterIP1)
							CLUSTERIP1_OPT=$TRUE
							;;
					-CLIP2|--clusterIP2)
							CLUSTERIP2_OPT=$TRUE
							;;	
					-A|--all)
							ALL_OPT=$TRUE
							;;
					-D|--debug)
							DEBUG=$TRUE
							;;
					-CC|--cleancache)
							CLEAN=$TRUE
							;;
					-H|--help)
							HELP=$TRUE
							;;
					*)
							echo "Invalid option: $1" >&2
							usage
							exit $FALSE 
							;;
			esac

			shift
	done
	
	
	if [ $HELP ]; then
	   helpUsage
	   exit $FALSE;
	fi

}

function blockDevDisk(){

		BLOCKDEV_DISK=$1
		BLOCKDEV_DISK=$(echo "${BLOCKDEV_DISK%/*}/1024/1024/1024"|bc)
                VALID_DISK_CAPACITY=$FALSE

		local DISKSIZE=$(cat $HWINFO_DB_FILE | grep -vP '^[[:space:]]*#' | grep -i "DISKCAPACITY;$DISK_CAPACITY_PATTERN")
		
		while IFS= read
		do
			MIN=$( echo $REPLY | awk -F'[] ; []' '{print $4}' | tr -d '\n' )
			MAX=$( echo $REPLY | awk -F'[] ; []' '{print $5}' | tr -d '\n' )
			VAL=$( echo $REPLY | awk -F'[] ; []' '{print $7}' | tr -d '\n' )

			if [ "$MAX" == '*' ] && [ $BLOCKDEV_DISK -ge $MIN ]; then
			   VALID_DISK_CAPACITY=$TRUE
                           break
			elif  [ "$MAX" != '*' ] && [ $BLOCKDEV_DISK -ge $MIN -a $BLOCKDEV_DISK -le $MAX ]; then
                           VALID_DISK_CAPACITY=$TRUE
			   break
                        fi
			
		done <<< "$DISKSIZE"
                if [ "$VALID_DISK_CAPACITY" == $FALSE ];then
                   echo "ERROR"
                else
		   echo "$VAL"
                fi
}


# Define a timestamp function
timestamp() {
  date +"%F %T"
}

function helpUsage(){
	
	usage
	echo '       -HWV, --hwversion         The APG HW type:                                                                    '
	echo '                                          "GEP1" or                                                                  '
	echo '                                          "GEP2" or                                                                  '
	echo '                                           ...   or                                                                  '
	echo '                                          "GEPn"                                                                     '
	echo '       -HWT, --hwtype        The APG board type:                                                                     '
	echo '                                          "GEP5_400" or                                                              '
	echo '                                          "GEP5_1200" or                                                             '
	echo '                                           GEP5_64_1200   or                                                         '
	echo '                                          "GEP7L_400"                                                                '
	echo '                                          "GEP7L_1200" or                                                            '
	echo '                                          "GEP7_128_1200" or                                                         '
	echo '       -DL,  --diskslocation     The location of the disks : "EXTERNAL" or "ONBOARD".                                '
	echo '       -DN,  --disksnumber       The total number of data disks present onto the GEP5 board : "1" or "3".            '
	echo '       -DC,  --diskscapacity     The disks capacity in GB :                                                          '
	echo '                                          "147" or                                                                   '
        echo '                                          "250" or                                                                   '
	echo '                                          "300" or                                                                   '
	echo '                                          "400" or                                                                   '
	echo '                                          "450" or                                                                   '
	echo '                                          "600" or                                                                   '
        echo '                                          "655" or 							           '
        echo '                                          "930" or                                                                   '
        echo '                                          "1300" or                                                                  '
	echo '                                          "1400" or                                                                  '
        echo '                                          "1450" or                                                                  '
	echo '                                          "1200" or                                                                  '
        echo '                                          "1600"                                                                     '
	echo '       -VEP, --virtualenvprofile The profile of the virtual environment.                                             '
	echo '                                 The value is in the form "VEx" with x numeric value.                                '
	echo '                                 On native environment the value is set to "VE0".                                    '
	echo '       -CLIP1,  --clusterIP1     The cluster IP retrieved with mip folder (/etc/cluster/nodes/this/mip/nbi/address). '
	echo '       -CLIP2,  --clusterIP2     The cluster IP retrieved with ifconfig command.                                     '
	echo '       -D,      --debug          Display debug information.                                                          '
	echo '       -CC,     --cleancache     Erase the cache file.                                                               '
	echo '       -H,      --help           Display this help.                                                                  '

}

function createHWInfoCache(){

	DEPLOYMENT_ENVIRONMENT="NOT_SIMULATED"
  if is_SIMULATED || [ -f ${DEPLOYMENT_ENVIRONMENT_FILE} ]; then
    DEPLOYMENT_ENVIRONMENT="SIMULATED"
  fi

	local HWVERSION_FIRST=''
	local HWTYPE_FIRST=''
	local DISKSLOCATION_FIRST=''
	local DISKSNUMBER_FIRST=''
	local DISKSCAPACITY_FIRST=''
	local VIRTUALENVPROFILE_FIRST=''
	#############################################
	local HWVERSION_SECOND=''
	local HWTYPE_SECOND=''
	local DISKSLOCATION_SECOND=''
	local DISKSNUMBER_SECOND=''
	local DISKSCAPACITY_SECOND=''
	local VIRTUALENVPROFILE_SECOND=''	

	if [ "$DEBUG" ]; then echo "$(timestamp) "${FUNCNAME[0]}""\(\)" : DEPLOYMENT_ENVIRONMENT: \"$DEPLOYMENT_ENVIRONMENT\""; fi

	case "$DEPLOYMENT_ENVIRONMENT" in
		SIMULATED)
			if is_SIMULATED; then 
				VIRTUALENVPROFILE_FIRST='VE0'
				HWVERSION_FIRST="$(${APOS_PARM_CMD} get --simulated --item-list installation_hw | awk -F"installation_hw=" '{print $2}' | tr -d '\n')"
			else
				VIRTUALENVPROFILE_FIRST="$( cat ${DEPLOYMENT_ENVIRONMENT_FILE} | tr '[:lower:]' '[:upper:]' | awk -F"VIRTUAL_ENV_PROFILE=" '{print $2}' | tr -d '\n' )"
				if [ "$VIRTUALENVPROFILE_FIRST" == 'VE0' ]; then
				  HWVERSION_FIRST="$( cat ${DEPLOYMENT_ENVIRONMENT_FILE} | tr '[:lower:]' '[:upper:]' | awk -F"INSTALLATION_HW=" '{print $2}' | tr -d '\n' )"
			  fi
			fi
			if [[ "$HWVERSION_FIRST" == "GEP5"* || "$HWVERSION_FIRST" == "GEP7"* ]]; then
			
				DISKSLOCATION_FIRST='ONBOARD'
				HWTYPE_FIRST=$(echo $HWVERSION_FIRST)				
				if [ "$DEBUG" ]; then echo "$(timestamp) "${FUNCNAME[0]}""\(\)" : HWTYPE: \"$HWTYPE_FIRST\""; fi

				HWVERSION_FIRST=$(echo $HWVERSION_FIRST | awk -F'-' '{print $1}')
				DISKSNUMBER_FIRST=$(cat $HWINFO_DB_FILE | grep -vP '^[[:space:]]*#' | grep -i "DISKNUMBER;$HWTYPE_FIRST" | sed 's@.*;@@g')
				DISKSCAPACITY_FIRST=$(cat $HWINFO_DB_FILE | grep -vP '^[[:space:]]*#' | grep -i "DISKCAPACITY;$HWTYPE_FIRST" | sed 's@.*;@@g')

			elif [[ "$HWVERSION_FIRST" == "GEP"* ]]; then
				DISKSLOCATION_FIRST='EXTERNAL'
				DISKSNUMBER_FIRST='NO_VALUE'
				BLOCKDEV_DISK=''

				if [ -h "$VM_ERI_DISK" ]; then
					BLOCKDEV_DISK=$(blockdev --getsize64 /dev/eri_disk)
					BLOCKDEV_DISK=$(blockDevDisk $BLOCKDEV_DISK $DISK_CAPACITY_PATTERN)
				fi
				if [ "$DEBUG" ]; then echo "$(timestamp) "${FUNCNAME[0]}""\(\)" : ERI_DISKA: \"$BLOCKDEV_DISK\""; fi
				DISKSCAPACITY_FIRST=$BLOCKDEV_DISK
			fi
		;;
		
		NOT_SIMULATED)
		
			local SHELF_ARCH=$(immlist -a apgShelfArchitecture axeFunctionsId=1 |  $CMD_CUT -d = -f 2)
			[[ -n $SHELF_ARCH && $SHELF_ARCH -eq 3 ]] && IS_VAPG=$TRUE

			VIRTUALENVPROFILE_FIRST="VE0"
			HWVERSION_FIRST="$(. "${APOS_DIR}"/apos_hwtype.sh)"
		

			if [[ "$HWVERSION_FIRST" == "GEP5"* || "$HWVERSION_FIRST" == "GEP7"* ]]; then
				
				HWTYPE_FIRST="$(. "${APOS_DIR}"/apos_hwtype.sh --verbose)"
				HWTYPE_FIRST="$(echo $HWTYPE_FIRST |  awk -F"hw-type=" '{print $2}' | tr -d '\n')"			
				DISKSLOCATION_FIRST='ONBOARD'
		
				if [ "$DEBUG" ]; then echo "$(timestamp) "${FUNCNAME[0]}""\(\)" : HWTYPE: \"$HWTYPE_FIRST\""; fi
				
				DISKSNUMBER_FIRST=$(cat $HWINFO_DB_FILE | grep -vP '^[[:space:]]*#' | grep -i "DISKNUMBER;$HWTYPE_FIRST" | sed 's@.*;@@g')
				DISKSCAPACITY_FIRST=$(cat $HWINFO_DB_FILE | grep -vP '^[[:space:]]*#' | grep -i "DISKCAPACITY;$HWTYPE_FIRST" | sed 's@.*;@@g')

			elif [[ "$HWVERSION_FIRST" == "GEP"* ]]; then
				DISKSLOCATION_FIRST='EXTERNAL'
				DISKSNUMBER_FIRST='NO_VALUE'
				BLOCKDEV_DISKA=""
				BLOCKDEV_DISKB=""
				
				if [ -h "$ERI_DISKA" ]; then
					BLOCKDEV_DISKA=$(blockdev --getsize64 /dev/eri_diskA)
					BLOCKDEV_DISKA=$(blockDevDisk $BLOCKDEV_DISKA $DISK_CAPACITY_PATTERN)
				fi
				if [ "$DEBUG" ]; then echo "$(timestamp) "${FUNCNAME[0]}""\(\)" : ERI_DISKA: \"$BLOCKDEV_DISKA\""; fi

				if [ -h "$ERI_DISKB" ]; then
					BLOCKDEV_DISKB=$(blockdev --getsize64 /dev/eri_diskB)
					BLOCKDEV_DISKB=$(blockDevDisk $BLOCKDEV_DISKB $DISK_CAPACITY_PATTERN)
				fi
				if [ "$DEBUG" ]; then echo "$(timestamp) "${FUNCNAME[0]}""\(\)" : ERI_DISKB: \"$BLOCKDEV_DISKB\""; fi
				
				if test $BLOCKDEV_DISKA -lt $BLOCKDEV_DISKB ; then
					DISKSCAPACITY_FIRST=$BLOCKDEV_DISKA
				else
					DISKSCAPACITY_FIRST=$BLOCKDEV_DISKB
				fi
			elif [ "$IS_VAPG" == $TRUE ]; then
				DISKSLOCATION_FIRST='EXTERNAL'
				DISKSNUMBER_FIRST='NO_VALUE'
				HWTYPE_FIRST='NO_VALUE'
				BLOCKDEV_DISK=""
                                DISK_CAPACITY_PATTERN="VM-[0-9]*"
				
				if [ -x "$VM_DATADISK_CMD" ]; then
					$(. "$VM_DATADISK_CMD" $VM_ERI_DISK)
					if [ $? -eq $TRUE ]; then
						BLOCKDEV_DISK=$(blockdev --getsize64 $VM_ERI_DISK)
						BLOCKDEV_DISK=$(blockDevDisk $BLOCKDEV_DISK $DISK_CAPACITY_PATTERN)
					fi
				fi
				DISKSCAPACITY_FIRST=$(cat $HWINFO_DB_FILE | grep -vP '^[[:space:]]*#' | grep -iw "DISKCAPACITY;$HWVERSION_FIRST-$BLOCKDEV_DISK" | sed 's@.*;@@g')
				if [ "$DEBUG" ]; then echo "$(timestamp) "${FUNCNAME[0]}""\(\)" : ERI_DISK: \"$DISKSCAPACITY_FIRST\""; fi
			fi
			
		;;
	esac
		
		if [ "$DEBUG" ]; then echo "$(timestamp) "${FUNCNAME[0]}""\(\)" : HWVERSION: \"$HWVERSION_FIRST\""; fi
		if [ "$DEBUG" ]; then echo "$(timestamp) "${FUNCNAME[0]}""\(\)" : DISKSLOCATION: \"$DISKSLOCATION_FIRST\""; fi
		if [ "$DEBUG" ]; then echo "$(timestamp) "${FUNCNAME[0]}""\(\)" : DISKSNUMBER: \"$DISKSNUMBER_FIRST\""; fi
		
		if [[ "$IS_VAPG" == $TRUE ]]; then
			VIRTUALENVPROFILE_SECOND='NO_ERROR'
			HWVERSION_SECOND='NO_ERROR'
			HWTYPE_SECOND='NO_ERROR'
		elif [[ "$VIRTUALENVPROFILE_FIRST" != "VE"* ]]; then
			VIRTUALENVPROFILE_FIRST='NO_VALUE'
			VIRTUALENVPROFILE_SECOND='ERROR'
			HWVERSION_FIRST='NO_VALUE'
			HWVERSION_SECOND='ERROR'
			HWTYPE_FIRST='NO_VALUE'
			HWTYPE_SECOND='ERROR'
		elif [ "$VIRTUALENVPROFILE_FIRST" != "VE0" ]; then
			VIRTUALENVPROFILE_SECOND='NO_ERROR'
			HWVERSION_FIRST='NO_VALUE'
			HWVERSION_SECOND='NO_ERROR'
			HWTYPE_FIRST='NO_VALUE'
			HWTYPE_SECOND='NO_ERROR'
		elif [[ "$HWVERSION_FIRST" != "GEP"* ]]; then
			VIRTUALENVPROFILE_SECOND='NO_ERROR'
			HWVERSION_FIRST='NO_VALUE'
			HWVERSION_SECOND='ERROR'
			HWTYPE_FIRST='NO_VALUE'
			HWTYPE_SECOND='ERROR'			
		else
			VIRTUALENVPROFILE_SECOND='NO_ERROR'
			HWVERSION_SECOND='NO_ERROR'
			HWTYPE_SECOND='NO_ERROR'			
		fi
		
		if [ -z "$DISKSLOCATION_FIRST" ]; then
			DISKSLOCATION_FIRST='NO_VALUE'
			DISKSLOCATION_SECOND='ERROR'
		else
			DISKSLOCATION_SECOND='NO_ERROR'
		fi
		
		if [ -z "$DISKSNUMBER_FIRST" ]; then
			DISKSNUMBER_FIRST='NO_VALUE'
			DISKSNUMBER_SECOND='ERROR'
		else
			DISKSNUMBER_SECOND='NO_ERROR'
		fi
		
		if [ -z "$DISKSCAPACITY_FIRST" ]; then
			DISKSCAPACITY_FIRST='NO_VALUE'
			DISKSCAPACITY_SECOND='ERROR'
		else
			DISKSCAPACITY_SECOND='NO_ERROR'
		fi
		
	>${CACHE_FILE}
	echo "hwversion=$HWVERSION_FIRST;$HWVERSION_SECOND" >>${CACHE_FILE}
    echo "hwtype=$HWTYPE_FIRST;$HWTYPE_SECOND" >>${CACHE_FILE}
	echo "diskslocation=$DISKSLOCATION_FIRST;$DISKSLOCATION_SECOND" >>${CACHE_FILE}
	echo "disksnumber=$DISKSNUMBER_FIRST;$DISKSNUMBER_SECOND" >>${CACHE_FILE}
	echo "diskscapacity=$DISKSCAPACITY_FIRST;$DISKSCAPACITY_SECOND" >>${CACHE_FILE}
	echo "virtualenvprofile=$VIRTUALENVPROFILE_FIRST;$VIRTUALENVPROFILE_SECOND" >>${CACHE_FILE}
				
	if [ -w "${CACHE_FILE}" ]; then
		/bin/chown ${CACHE_FILE_OWNER} ${CACHE_FILE}
		/bin/chgrp ${CACHE_FILE_GROUP} ${CACHE_FILE}
		/bin/chmod ${CACHE_FILE_PERMISSIONS} ${CACHE_FILE}
	fi
}
function getCLIPInterface(){

		local INTERFACE_FLAG=$1
		local INTERFACE=$( "$CLUSTERCONF_CMD" mip -D | tail -n +2 |\
                awk '{print $4" "$5}' | sort | uniq | \
                grep "^$INTERFACE_FLAG[[:space:]]" | awk '{print $2}')
		[ -z "$INTERFACE" ] && exit $FALSE
		echo "$INTERFACE"
}

function getClusteIP1(){

		CLUSTERIP1_FIRST=''
		CLUSTERIP1_SECOND=''
		local MIP_NAME=''

		if is_vAPG; then
			isIPv4Stack && MIP_NAME='nbi'
			isIPv6Stack && MIP_NAME='nbi_v6'
			isDualStack && if [ -d "/etc/cluster/nodes/this/mip/nbi" ] && [ -d "/etc/cluster/nodes/this/mip/nbi_v6" ]; then
                                        MIP_NAME='nbi nbi_v6'
                               elif [ -d "/etc/cluster/nodes/this/mip/nbi" ]; then
                                        MIP_NAME='nbi'
                               elif [ -d "/etc/cluster/nodes/this/mip/nbi_v6" ]; then
                                        MIP_NAME='nbi_v6'
                               fi
		else
			MIP_NAME='nbi'
		fi
		

		for name in $MIP_NAME; do
			CLUSTERIP1_THIS="$(</etc/cluster/nodes/this/mip/$name/address)"
			CLUSTERIP1_PEER="$(</etc/cluster/nodes/peer/mip/$name/address)"
			if [ "$CLUSTERIP1_THIS" == "$CLUSTERIP1_PEER" ]; then
				if [ -n "$CLUSTERIP1_FIRST" ]; then
					CLUSTERIP1_FIRST="$CLUSTERIP1_FIRST,$CLUSTERIP1_THIS"
				else
					CLUSTERIP1_FIRST="$CLUSTERIP1_THIS"
				fi
			fi
		done

		if [ -z "$CLUSTERIP1_FIRST" ]; then
			CLUSTERIP1_FIRST='NO_VALUE'
			CLUSTERIP1_SECOND='ERROR'
		else
			CLUSTERIP1_SECOND='NO_ERROR'
		fi

}

function getClusteIP2(){

		CLUSTERIP2_FIRST=''
		CLUSTERIP2_SECOND=''
		LOCAL_IP=''
		INTERFACE_FLAG='nbi'

		if is_vAPG; then
			if isIPv4Stack; then
				CMD_IP='/sbin/ip -4'
				SCOPE_FLAG='scope global secondary'
				INTERFACE_FLAG='nbi'
			elif isIPv6Stack; then
				CMD_IP='/sbin/ip -6'
				SCOPE_FLAG='scope global deprecated'
				INTERFACE_FLAG='nbi_v6'
			elif isDualStack; then
                                if [ -d "/etc/cluster/nodes/this/mip/nbi" ] && [ -d "/etc/cluster/nodes/this/mip/nbi_v6" ]; then
                                                CMD_IP='/sbin/ip'
                                                SCOPE_FLAG='scope global deprecated'
						INTERFACE_FLAG='nbi nbi_v6'
                               elif [ -d "/etc/cluster/nodes/this/mip/nbi" ]; then
                                                CMD_IP='/sbin/ip -4'
                                                SCOPE_FLAG='scope global deprecated'
						INTERFACE_FLAG='nbi'
                               elif [ -d "/etc/cluster/nodes/this/mip/nbi_v6" ]; then
                                                CMD_IP='/sbin/ip -6'
                                                SCOPE_FLAG='scope global deprecated'
						INTERFACE_FLAG='nbi_v6'

                               fi
			fi
		else
			CMD_IP='/sbin/ip -4'
			SCOPE_FLAG='scope global secondary'
		fi

		IP_INTERFACE=$(getCLIPInterface $INTERFACE_FLAG)
		if [ -n "$IP_INTERFACE" ]; then
			LOCAL_IP=$(${CMD_IP} addr show dev $IP_INTERFACE ${SCOPE_FLAG} |\
			grep '^[[:space:]]*inet' | /usr/bin/tail -n -2 | /usr/bin/awk '{print $2}' |\
			/usr/bin/sed 's@\/[0-9]*$@@g')
		fi

		for IP in $LOCAL_IP; do
			if [ -n "$CLUSTERIP2_FIRST" ]; then
				CLUSTERIP2_FIRST="$CLUSTERIP2_FIRST,$IP"
			else
				CLUSTERIP2_FIRST="$IP"
			fi
		done

		if [ -z "$CLUSTERIP2_FIRST" ]; then
			CLUSTERIP2_FIRST='NO_VALUE'
			#it has to be handled on passive node.
			#CLUSTERIP2_SECOND='ERROR'
			CLUSTERIP2_SECOND='NO_ERROR'
		else
			CLUSTERIP2_SECOND='NO_ERROR'
		fi
}

function getHWInfo() {

	if [ "$HWVERSION_OPT" == $TRUE ] || [ "$ALL_OPT" == $TRUE ]; then
	
		HWVERSION="$(cat "$CACHE_FILE" | awk -F'hwversion=' '{print $2}' | tr -d '\n')"
		echo "hwversion=$HWVERSION"
	fi

	if [ "$HWTYPE_OPT" == $TRUE ] || [ "$ALL_OPT" == $TRUE ]; then
	
		HWTYPE="$(cat "$CACHE_FILE" | awk -F'hwtype=' '{print $2}' | tr -d '\n')"
		echo "hwtype=$HWTYPE"
	fi
    
	if [ "$DISKSLOCATION_OPT" == $TRUE ] || [ "$ALL_OPT" == $TRUE ]; then
	
		DISKSLOCATION="$(cat "$CACHE_FILE" | awk -F'diskslocation=' '{print $2}' | tr -d '\n')"
		echo "diskslocation=$DISKSLOCATION"
	fi

	if [ "$DISKSNUMBER_OPT" == $TRUE ] || [ "$ALL_OPT" == $TRUE ]; then
	
		DISKSNUMBER="$(cat "$CACHE_FILE" | awk -F'disksnumber=' '{print $2}' | tr -d '\n')"
		echo "disksnumber=$DISKSNUMBER"
	fi

	if [ "$DISKSCAPACITY_OPT" == $TRUE ] || [ "$ALL_OPT" == $TRUE ]; then
	
		DISKSCAPACITY="$(cat "$CACHE_FILE" | awk -F'diskscapacity=' '{print $2}' | tr -d '\n')"
		echo "diskscapacity=$DISKSCAPACITY"
	fi
	
	if [ "$VIRTUALENVPROFILE_OPT" == $TRUE ] || [ "$ALL_OPT" == $TRUE ]; then
	
		VIRTUALENVPROFILE="$(cat "$CACHE_FILE" | awk -F'virtualenvprofile=' '{print $2}' | tr -d '\n')"
		echo "virtualenvprofile=$VIRTUALENVPROFILE"
	fi
	
	if [ "$CLUSTERIP1_OPT" == $TRUE ] || [ "$ALL_OPT" == $TRUE ]; then
		getClusteIP1
		echo "clusterIP1=$CLUSTERIP1_FIRST;$CLUSTERIP1_SECOND"
	fi

	if [ "$CLUSTERIP2_OPT" == $TRUE ] || [ "$ALL_OPT" == $TRUE ]; then
		getClusteIP2
		echo "clusterIP2=$CLUSTERIP2_FIRST;$CLUSTERIP2_SECOND"
	fi
	if [ -e $CACHE_FILE ];then
       		 while read hwinfo_line;do
               	 	check_error=$(echo $hwinfo_line | awk -F'=' '{print $2}'| awk -F';' '{print $2}')
                	if [ "$check_error" != "NO_ERROR" ];then
                        	rm -f $CACHE_FILE
                        	break
                	fi
        	done < $CACHE_FILE
	fi
}


# Main

checkOPT $*

if [ "$CLEAN" ]; then
	if [ -f "${CACHE_FILE}" ]; then
		rm "${CACHE_FILE}"
		echo "Cache deleted"
	else
		echo "Cache already deleted/not present"
	fi
	exit $TRUE
fi

if [ "$DEBUG" ]; then
	echo "######################## DEBUG INFO #############################################"
fi
	
if [[ "$DEBUG" || ! -f "${CACHE_FILE}" ]]; then
	createHWInfoCache
fi

if [ "$DEBUG" ]; then
	echo "#################################################################################"
fi

getHWInfo

exit $TRUE

# End of file
