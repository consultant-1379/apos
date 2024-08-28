#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2013 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       drbdmgr_testsuite_bt.sh
# Description:
#   A script to perform basic test for the drbdmgr command in APG43L.
#       
##
# Usage:
#       call: drbdmgr_testsuite_bt.sh
##
# Changelog:
# - Wed Apr 03 2013 - Tanu Aggarwal (xtanagg)
#       First version.
##

TRUE=$(true;echo $?)
FALSE=$(false;echo $?)
CMD_NAME="shcov drbdmgr"
CURR_NODE_ID=0
NODE1=1
NODE2=2
CMD_OPTION=''
IS_LONG_OPTION=''
CMD_OPERAND_REMOTE_DISK=''
CMD_OPERAND_CURRENT_DISK=''
CMD_RM=rm
OUT_TMP='/tmp/drbdmgr_out'
ERR_TMP='/tmp/drbdmgr_err'
LUSER="C_USER=ldap-user"
DUSER="C_USER=dummy-user"



#Find remote and current disk.
function find_current_remote_disks() {

    CURR_NODE_ID=`cat /etc/opensaf/slot_id`
    if [ $CURR_NODE_ID -eq $NODE1 ]
    then
        CMD_OPERAND_REMOTE_DISK="diskB"
        CMD_OPERAND_CURRENT_DISK="diskA"
    else
        CMD_OPERAND_REMOTE_DISK="diskA"
        CMD_OPERAND_CURRENT_DISK="diskB"
    fi
}

#Add options
function do_add_invalid(){
	local IS_LONG_OPTION=$FALSE

    local rCode=0
	CMD_OPTION="$1"
	if [ "$1"  == "--add" ]; then
		IS_LONG_OPTION=$TRUE
	fi

    echo -e "Checking DRBD add with invalid option"
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION -s >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION -s >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD add with invalid option...failed"
        rCode=1
    else
        echo -e "Checking DRBD add with invalid option...success"
    fi

    echo -e "Checking DRBD add with invalid disk"
	if [ $IS_LONG_OPTION -eq 0 ]; then
		$CMD_NAME $CMD_OPTION diskC >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION diskC >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD add with invalid disk...failed"
        rCode=1
    else
        echo -e "Checking DRBD add with invalid disk...success"
    fi

	if [ $IS_LONG_OPTION -eq 0 ]; then 
		echo -e "Checking DRBD add with long option for LDAP user"
		$CMD_NAME $LUSER $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
		if [ $? -eq 0 ]
		then
			echo -e "Checking DRBD add with long option for LDAP user...failed"
			rCode=1
		else
			echo -e "Checking DRBD add with long option for LDAP user...success"
		fi
	fi

    echo -e "Checking DRBD add with invalid user"
    $CMD_NAME $DUSER $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD add with invalid user...failed"
        rCode=1
    else
        echo -e "Checking DRBD add with invalid user...success"
	fi

    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_add_disk(){

	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION=$1
    echo -e "Checking DRBD add "
	if [ "$1"  == "--add" ]; then
		IS_LONG_OPTION=$TRUE
	fi
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD add...failed"
        rCode=1
    else
        echo -e "Checking DRBD add...success"
    fi
	 $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_assemble_invalid(){

	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION=$1

    echo -e "Checking DRBD assemble with invalid option"
	
    $CMD_NAME $CMD_OPTION -s >$OUT_TMP 2>$ERR_TMP
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD assemble with invalid option...failed"
        rCode=1
    else
        echo -e "Checking DRBD assemble with invalid option...success"
    fi

    echo -e "Checking DRBD assemble for LDAP user"
    $CMD_NAME $LUSER $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD assemble for LDAP user...failed"
        rCode=1
    else
        echo -e "Checking DRBD assemble for LDAP user...success"
    fi

    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_assemble(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
	CMD_OPTION_ASSEMBLE="$1"
    echo -e "Checking DRBD assemble"
    $CMD_NAME $CMD_OPTION_ASSEMBLE >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD assemble...failed"
		rCode=1
    else
        echo -e "Checking DRBD assemble...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
	return $rCode
}

function do_assemble_mount(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
	CMD_OPTION_ASSEMBLE="$1"
	CMD_OPTION_MOUNT="$2"
    echo -e "Checking DRBD assemble with mount"
    $CMD_NAME $CMD_OPTION_ASSEMBLE $CMD_OPTION_MOUNT >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD assemble with mount ...failed"
		rCode=1
    else
        echo -e "Checking DRBD assemble with mount ...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
	return $rCode
}
function do_disable_invalid(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"

    echo -e "Checking DRBD disable with invalid option"
    $CMD_NAME $CMD_OPTION -d >$OUT_TMP 2>$ERR_TMP
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD disable with invalid option...failed"
        rCode=1
    else
        echo -e "Checking DRBD disable with invalid option...success"
    fi

    echo -e "Checking DRBD disable for LDAP user"
    $CMD_NAME $LUSER $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD disable for LDAP user...failed"
        rCode=1
    else
        echo -e "Checking DRBD disable for LDAP user...success"
    fi

    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_disable(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
    echo -e "Checking DRBD disable"
	CMD_OPTION_DISABLE="$1"

	
    $CMD_NAME $CMD_OPTION_DISABLE &>/dev/null <<EOF
y

EOF
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD disable...failed"
		rCode=1
    else
        echo -e "Checking DRBD disable...success"
    fi
    #$CMD_RM $OUT_TMP $ERR_TMP
	return $rCode
}

function do_disable_unmount(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
	CMD_OPTION_DISABLE="$1"
	CMD_OPTION_UMOUNT="$2"
	umount "/var/cpftp/APZ"
	umount "/var/cpftp/cpa"
	umount "/var/cpftp/cpb"
	umount "/var/cpftp/CPSDUMP"
	umount "/var/cpftp/CPSLOAD"
	umount "/var/cpftp/tracelog"
    echo -e "Checking DRBD disable with unmount"
    $CMD_NAME $CMD_OPTION_DISABLE $CMD_OPTION_UMOUNT >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD disable and unmount...failed"
		rCode=1
    else
        echo -e "Checking DRBD disable and unmount...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
	return $rCode
}

function do_ismounted(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION_IS_MOUNTED="$1"
    echo -e "Checking DRBD mount status"
    $CMD_NAME $CMD_OPTION_IS_MOUNTED &>/dev/null <<EOF
y

EOF
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD mount status...Disk is not Mounted"
        rCode=1
    else
        echo -e "Checking DRBD mount status...success"
    fi
    #$CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_mount(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION_MOUNT="$1"
    echo -e "Checking DRBD mount "
    $CMD_NAME $CMD_OPTION_MOUNT &>/dev/null <<EOF
y

EOF
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD mount ...failed"
        rCode=1
    else
        echo -e "Checking DRBD mount ...success"
    fi
    #$CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}


#Create methods
function do_create(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
    echo -e "Checking DRBD create"
	CMD_OPTION="$1"
	if [ "$1"  == "--create" ]; then
        IS_LONG_OPTION=$TRUE
    fi
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD create...failed"
        rCode=1
    else
        echo -e "Checking DRBD create...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_create_invalid(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
	if [ "$1"  == "--create" ]; then
		IS_LONG_OPTION=$TRUE
	fi
	echo -e "Checking DRBD create with invalid options"
	CMD_OPTION="$CMD_OPTION -h"
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	fi
	if [ $? -ne 0 ];then
		echo -e "Checking DRBD create with verbose...success"
	else
		echo -e "Checking DRBD create with verbose...failed"
		rCode=1
	fi
	$CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_deactivate(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
    echo -e "Checking DRBD deactivate"
    CMD_OPTION="$1"
    $CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD deactivate...failed"
        rCode=1
    else
        echo -e "Checking DRBD deactivate...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_deactivate_force(){
	local IS_LONG_OPTION=$FALSE

	umount "/var/cpftp/APZ"
	umount "/var/cpftp/cpa"
	umount "/var/cpftp/cpb"
	umount "/var/cpftp/CPSDUMP"
	umount "/var/cpftp/CPSLOAD"
	umount "/var/cpftp/tracelog"

    local rCode=0
	CMD_OPTION="$1"
    echo -e "Checking DRBD deactivate with force"
    CMD_OPTION="$CMD_OPTION $2"
    $CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD deactivate with force...failed"
        rCode=1
    else
        echo -e "Checking DRBD deactivate with force...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}
function do_deactivate_verbose(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
    echo -e "Checking DRBD deactivate with verbose"
    CMD_OPTION="$CMD_OPTION $2"
    $CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD deactivate with verbose...failed"
        rCode=1
    else
        echo -e "Checking DRBD deactivate with verbose...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_activate(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
    echo -e "Checking DRBD activate"
    $CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD activate...failed"
        rCode=1
    else
        echo -e "Checking DRBD activate...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_activate_force(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
    echo -e "Checking DRBD activate with force"
    CMD_OPTION="$CMD_OPTION $2"
    $CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD activate with force...failed"
        rCode=1
    else
        echo -e "Checking DRBD activate with force...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_activate_verbose(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
    echo -e "Checking DRBD activate with verbose"
    CMD_OPTION="$CMD_OPTION $2"
    $CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD activate with verbose...failed"
        rCode=1
    else
        echo -e "Checking DRBD activate with verbose...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_folder_invalid(){
	local IS_LONG_OPTION=$FALSE

    #Don't specify any operand with --folder option.
    local rCode=0
	CMD_OPTION="$1"
	if [ "$1"  == "--folder" ]; then
		 IS_LONG_OPTION=$TRUE
	fi
	
    echo -e "Checking DRBD folder with other invalid options"
    CMD_INVALID_OPTION="-k"
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION $CMD_INVALID_OPTION >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION $CMD_INVALID_OPTION >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD folder with invalid option...success"
    else
        echo -e "Checking DRBD folder with invalid option...failed"
        rCode=1
    fi

    #Sepecify a operand with --folder option.

    echo -e "Checking DRBD folder with invalid operand"
    local CMD_OPERAND="invalid"
    $CMD_NAME $CMD_OPTION $CMD_OPERAND >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD folder with invalid operand...success"
    else
        echo -e "Checking DRBD folder with invalid operand...failed"
        rCode=1
    fi

    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_folder(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
	if [ "$1"  == "--folder" ]; then
		 IS_LONG_OPTION=$TRUE
	fi
    echo -e "Checking DRBD folder "
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION &>/dev/null <<EOF
y

EOF
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD folder ...failed"
        rCode=1
    else
        echo -e "Checking DRBD folder ...success"
    fi
    return $rCode
}


function do_part(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
    echo -e "Checking DRBD partition"
	CMD_OPTION_PART="$1"
    CMD_OPERAND_PART=$2
    $CMD_NAME $CMD_OPTION_PART $CMD_OPERAND_PART >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD part...failed"
		rCode=1
    else
        echo -e "Checking DRBD part...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
	return $rCode
}

function do_part_format(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
    echo -e "Checking DRBD part and format"
	CMD_OPTION_PART="$1"
	CMD_OPTION_PART="$2"
    CMD_OPERAND_PART=$3
    $CMD_NAME $CMD_OPTION_PART $CMD_OPERAND_PART $CMD_OPTION_FORMAT  >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD part + format ...failed"
		rCode=1
    else
        echo -e "Checking DRBD part + format...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
	return $rCode
}

function do_part_force_verbose(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
    echo -e "Checking DRBD part, with force and verbose"
	CMD_OPTION_PART="$1"
	CMD_OPTION_FORCE="$2"
	CMD_OPTION_VERBOSE="$3"
    CMD_OPERAND_PART=$4
    $CMD_NAME $CMD_OPTION_PART "diskB"  $CMD_OPERAND_PART $CMD_OPTION_FORCE $CMD_OPTION_VERBOSE >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD part with force and verbose...failed"
		rCode=1
    else
        echo -e "Checking DRBD part with force and verbose...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
	return $rCode
}
function do_part_format_mount_force_verbose(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
    echo -e "Checking DRBD part, format, mount, with force and verbose"
	CMD_OPTION_PART="$1"
	CMD_OPTION_FORMAT="$2"
	CMD_OPTION_FORCE="$3"
	CMD_OPTION_VERBOSE="$4"
	CMD_OPTION_MOUNT="$5"
    CMD_OPERAND_PART=$6
    $CMD_NAME $CMD_OPTION_PART $CMD_OPERAND_PART $CMD_OPTION_FORMAT $CMD_OPTION_MOUNT $CMD_OPTION_FORCE $CMD_OPTION_VERBOSE >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD part, format, mount with force and verbose...failed"
		rCode=1
    else
        echo -e "Checking DRBD part, format, mount with force and verbose...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
	return $rCode
}


function do_part_invalid(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
	CMD_OPTION_PART="$1"
	CMD_OPTION_FORMAT="$2"
	CMD_OPTION_FORCE="$3"
	CMD_OPTION_VERBOSE="$4"
	CMD_OPTION_MOUNT="$5"
    echo -e "Checking DRBD part with invalid options"
    CMD_OPERAND_PART=$1
    $CMD_NAME $CMD_OPTION_PART $CMD_OPERAND_PART -s $CMD_OPTION_FORMAT $CMD_OPTION_MOUNT $CMD_OPTION_FORCE $CMD_OPTION_VERBOSE >$OUT_TMP 2>$ERR_TMP
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD part with invalid options...failed"
		rCode=1
    else
        echo -e "Checking DRBD part with invalid options...success"
    fi

    echo -e "Checking DRBD part with invalid operand"
    CMD_OPERAND_PART=dummy
    $CMD_NAME $CMD_OPTION_PART $CMD_OPERAND_PART $CMD_OPTION_FORMAT $CMD_OPTION_MOUNT $CMD_OPTION_FORCE $CMD_OPTION_VERBOSE >$OUT_TMP 2>$ERR_TMP
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD part with invalid options...failed"
		rCode=1
    else
        echo -e "Checking DRBD part with invalid options...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
	return $rCode
}

function do_recover_invalid(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
	if [ "$1"  == "--recover" ]; then
		IS_LONG_OPTION=$TRUE
	fi
    echo -e "Checking DRBD recover with invalid option"
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION -l >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION -l >$OUT_TMP 2>$ERR_TMP 
	fi
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD recover with invalid option...failed"
        rCode=1
    else
        echo -e "Checking DRBD recover with invalid option...success"
    fi

    echo -e "Checking DRBD recover with invalid operand"
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION diskC >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION diskC >$OUT_TMP 2>$ERR_TMP 
	fi
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD recover with invalid operand...failed"
        rCode=1
    else
        echo -e "Checking DRBD recover with invalid operand...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_recover(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
	if [ "$1"  == "--recover" ]; then
		IS_LONG_OPTION=$TRUE
	fi
    echo -e "Checking DRBD recover"
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION &>/dev/null <<EOF
y

EOF
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD recover...failed"
        rCode=1
    else
        echo -e "Checking DRBD recover...success"
    fi
    #$CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_remove_invalid(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
	if [ "$1"  == "--remove" ]; then
		IS_LONG_OPTION=$TRUE
	fi
    echo -e "Checking DRBD remove with invalid option"
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION -l >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION -l &>/dev/null <<EOF
y

EOF
	fi
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD remove with invalid option...failed"
        rCode=1
    else
        echo -e "Checking DRBD remove with invalid option...success"
    fi


    echo -e "Checking DRBD remove with invalid disk Name"
    $CMD_NAME $CMD_OPTION diskC >$OUT_TMP 2>$ERR_TMP
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD remove with invalid disk Name...failed"
        rCode=1
    else
        echo -e "Checking DRBD remove with invalid disk Name...success"
    fi
    return $rCode
}

function do_remove_remote_disk(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
	if [ "$1"  == "--remove" ]; then
		IS_LONG_OPTION=$TRUE
	fi

    echo -e "Checking DRBD remove to remove remote disk "
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION >/dev/null <<EOF
y

EOF
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD remove ...failed"
        rCode=1
    else
        echo -e "Checking DRBD remove ...success"
    fi
    return $rCode
}

function do_remove_remote_disk_force(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
	CMD_OPTION="$1"
	CMD_OPTION_FORCE="$2"
	if [ "$1"  == "--remove" ]; then
		IS_LONG_OPTION=$TRUE
	fi
	echo -e "Checking DRBD remove $CMD_OPERAND_REMOTE_DISK with force"
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION $CMD_OPTION_FORCE >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION $CMD_OPTION_FORCE >$OUT_TMP 2>$ERR_TMP
	fi
	if [ $? -ne 0 ];then
	        echo -e "Checking DRBD remove with force...failed"
        	rCode=1
    	else
        	echo -e "Checking DRBD remove with force...success"
    	fi
    	$CMD_RM $OUT_TMP $ERR_TMP
    	return $rCode
}

function do_remove_current_disk(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
	CMD_OPTION="$1"
    echo -e "Checking DRBD remove $CMD_OPERAND_CURRENT_DISK"
	if [ "$1"  == "--remove" ]; then
		IS_LONG_OPTION=$TRUE
	fi
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION $CMD_OPERAND_CURRENT_DISK >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION $CMD_OPERAND_CURRENT_DISK &>/dev/null <<EOF
y

EOF
	fi
    if [ $? -eq 0 ]
    then
        echo -e "Checking DRBD remove $CMD_OPERAND_CURRENT_DISK...success"
    else
        echo -e "Checking DRBD remove $CMD_OPERAND_CURRENT_DISK...failed"
        rCode=1
    fi
    return $rCode
}

function do_role_invalid(){
	local IS_LONG_OPTION=$FALSE

    #Don't specify any operand with --role option.
    local rCode=0
    echo -e "Checking DRBD role with no role"
	CMD_OPTION="$1"
    $CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD role...success"
    else
        echo -e "Checking DRBD role...failed"
        rCode=1
    fi

    #Sepecify a operand other than primary/secondary with --role option.

    echo -e "Checking DRBD role with invalid role"
    local CMD_OPERAND="invalid"
    $CMD_NAME $CMD_OPTION $CMD_OPERAND >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD role...success"
    else
        echo -e "Checking DRBD role...failed"
        rCode=1
    fi

    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}
function do_role_primary(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
    echo -e "Checking DRBD role primary"
	CMD_OPTION=$1
    $CMD_NAME $CMD_OPTION primary >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD role primary...failed"
        rCode=1
    else
        echo -e "Checking DRBD role primary...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}

function do_role_secondary(){
	local IS_LONG_OPTION=$FALSE
    local rCode=0
    echo -e "Checking DRBD role secondary"
	CMD_OPTION=$1
    $CMD_NAME $CMD_OPTION secondary >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD role secondary...failed"
        rCode=1
    else
        echo -e "Checking DRBD role secondary...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}
function do_speedup(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0
    CMD_SYNC_RATE=$2
    echo -e "Checking DRBD speedup with sync rate $CMD_SYNC_RATE"
	CMD_OPTION="$1"
    $CMD_NAME $CMD_OPTION $CMD_SYNC_RATE >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD speedup with sync rate $CMD_SYNC_RATE...failed"
		rCode=1
    else
        echo -e "Checking DRBD speedup with sync rate $CMD_SYNC_RATE...success"
    fi

    echo -e "Checking DRBD speedup with no sync rate"
	CMD_OPTION="-U"
    $CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD speedup with no sync rate...failed"
		rCode=1
    else
        echo -e "Checking DRBD speedup with no sync rate...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
    return $rCode
}


function do_speedup_invalid(){
	local IS_LONG_OPTION=$FALSE
	local rCode=0

    echo -e "Checking DRBD speedup with invalid options"
	CMD_OPTION="$1"
    CMD_SYNC_RATE="-s"
    $CMD_NAME $CMD_OPTION $CMD_SYNC_RATE -s >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD speedup with invalid options...success"
    else
        echo -e "Checking DRBD speedup with invalid options...failed"
		rCode=1
    fi

    echo -e "Checking DRBD speedup with invalid operand starting with alphabets"
    CMD_SYNC_RATE="a10278K"
    $CMD_NAME $CMD_OPTION $CMD_SYNC_RATE >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD speedup with invalid operand...success"
    else
        echo -e "Checking DRBD speedup with invalid operand...failed"
		rCode=1
    fi

    echo -e "Checking DRBD speedup with invalid operand containing invalid alphabets"
    CMD_SYNC_RATE="10278Q"
    $CMD_NAME $CMD_OPTION $CMD_SYNC_RATE >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD speed-up with invalid operand...success"
    else
        echo -e "Checking DRBD speed-up with invalid operand...failed"
		rCode=1
    fi

    $CMD_RM $OUT_TMP $ERR_TMP
	return $rCode
}

function show_role(){
	local IS_LONG_OPTION=$FALSE
    echo -e "Checking DRBD status(role)"
	CMD_OPTION="$1"
	CMD_ROLE="role"
	if [ "$1"  == "--status" ]; then
		IS_LONG_OPTION=$TRUE
	fi
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION $CMD_ROLE >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION $CMD_ROLE >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD status(role)...failed"
    else
        echo -e "Checking DRBD status(role)...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
}

function show_cstate(){
    echo -e "Checking DRBD status(cstate)"
	local IS_LONG_OPTION=$FALSE
	CMD_OPTION="$1"
	CMD_CSTATE="cstate"
	if [ "$1"  == "--status" ]; then
		IS_LONG_OPTION=$TRUE
	fi
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION $CMD_CSTATE >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION $CMD_CSTATE >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD status(cstate)...failed"
    else
        echo -e "Checking DRBD status(cstate)...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
}


function show_dstate(){
	local IS_LONG_OPTION=$FALSE
    echo -e "Checking DRBD status(dstate)"
	CMD_OPTION="$1"
	CMD_DSTATE="dstate"
	if [ "$1"  == "--status" ]; then
		IS_LONG_OPTION=$TRUE
	fi
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION $CMD_DSTATE >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION $CMD_DSTATE >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD status(dstate)...failed"
    else
        echo -e "Checking DRBD status(dstate)...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
}

function show(){
	local IS_LONG_OPTION=$FALSE
    echo -e "Checking DRBD status"
	CMD_OPTION="$1"
	if [ "$1"  == "--status" ]; then
		IS_LONG_OPTION=$TRUE
	fi
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD status(all)...failed"
    else
        echo -e "Checking DRBD status(all)...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
}

function show_invalid(){
	local IS_LONG_OPTION=$FALSE
    echo -e "Checking DRBD status with invalid options"
	CMD_OPTION="$1"
	if [ "$1"  == "--status" ]; then
		IS_LONG_OPTION=$TRUE
	fi
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION -S >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION -S >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD status with invalid option...success"
    else
        echo -e "Checking DRBD status with invalid option...failed"
    fi

    echo -e "Checking DRBD status with no operand"
    $CMD_NAME $CMD_OPTION >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD status with no operand...failed"
    else
        echo -e "Checking DRBD status with no operand...success"
    fi


    echo -e "Checking DRBD status with invalid operand"
    $CMD_NAME $CMD_OPTION state >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD status with invalid operand...success"
    else
        echo -e "Checking DRBD status with invalid operand...failed"
    fi

    $CMD_RM $OUT_TMP $ERR_TMP
}

function do_start(){
	local IS_LONG_OPTION=$FALSE
    	echo -e "Checking DRBD synch start"
	CMD_OPTION="$1"
	CMD_START_OPERAND="$2"
	if [ "$1"  == "--sync" ]; then
		IS_LONG_OPTION=$TRUE
	fi
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION $CMD_START_OPERAND >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION $CMD_START_OPERAND >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD sync start...failed"
    else
        topcho -e "Checking DRBD synch start...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
}

function do_stop(){
	local IS_LONG_OPTION=$FALSE
    echo -e "Checking DRBD synch pause"
	CMD_OPTION="$1"
	CMD_PAUSE_OPERAND="$2"
	if [ "$1"  == "--sync" ]; then
        IS_LONG_OPTION=$TRUE
    fi
	if [ $IS_LONG_OPTION -eq $TRUE ]; then
		$CMD_NAME $CMD_OPTION $CMD_PAUSE_OPERAND >$OUT_TMP 2>$ERR_TMP
	else
		$CMD_NAME $LUSER $CMD_OPTION $CMD_PAUSE_OPERAND >$OUT_TMP 2>$ERR_TMP
	fi
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD sync pause...failed"
    else
        echo -e "Checking DRBD synch pause...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
}

function do_help(){
    echo -e "Checking help for $1"
CMD_OPTION="-h"
	CMD_USER_OPERAND="C_USER=$1"
    $CMD_NAME $CMD_USER_OPERAND $CMD_OPTION  >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking DRBD help for $1...failed"
    else
        echo -e "Checking DRBD help for $1...success"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
}

function do_help_invalid(){
    echo -e "Checking help with invalid option"
	CMD_OPTION="$1"
    $CMD_NAME $CMD_OPTION  -a >$OUT_TMP 2>$ERR_TMP
    if [ $? -ne 0 ]
    then
        echo -e "Checking help with invalid option...success"
    else
        echo -e "Checking help with invalid option...failed"
    fi
    $CMD_RM $OUT_TMP $ERR_TMP
}

function invoke(){

	#First, find the current and remote disks
	find_current_remote_disks

	do_help "ldap-user"

	do_help "ts-user"

	do_help "user1"

	do_help_invalid "--help"

	#Deactivate drbd
	do_deactivate "--deactivate" 
	[ $? -ne 0 ] && do_deactivate_force "--deactivate" "--force"

	do_activate  "--activate"
	[ $? -ne 0 ] &&	do_activate_force "--activate" "--force"

	do_role_invalid  "--role" 

	do_role_secondary "--role" 

	do_role_primary "--role" 
	
	# to check the status of drbd
	show_invalid "--status" 

	show "--status" 
	
	# To mount the drdb1 folder 
	do_mount  "--mount" 

	do_folder_invalid "--folder" 

	# To create folder structure inside /data
	do_folder "--folder" 

	do_ismounted  "--is-mounted" 

	do_disable_invalid  "--disable" 

	do_disable_unmount  "--disable" "--unmount" 

	do_assemble_invalid "--assemble" 

	do_assemble "--assemble" 

	do_disable "--disable" 

	do_assemble_mount "--assemble" "--mount"

	do_remove_invalid "--remove" 

	do_remove_remote_disk "--remove" 
	[ $? -ne 0 ] && do_remove_remote_disk_force "--remove" "--force"

	do_part_force_verbose "--part" "--force" "--verbose" 

	do_recover_invalid "--recover" 

	# To recover diskB
	do_recover "--recover" 

	do_speedup_invalid "--sync-speed" 

	do_speedup "--sync-speed" 2G

	do_add_invalid "--add" 

	do_remove_remote_disk "--remove" 
	[ $? -ne 0 ] && do_remove_remote_disk_force "--remove" "--force" 

	do_add_disk "--add" 

	#  pause and start the synchronozation
	do_stop "--sync" pause
	[ $? == 0 ] && do_start "--sync" resume

	do_create_invalid "--create" 

	#Invoke again with small options.

	do_help  "ldap-user"

	do_help "ts-user"

	do_help "user1"

	#Deactivate drbd
	do_deactivate "-T" 
	[ $? -ne 0 ] && do_deactivate_force "-T" "-f" 

	do_activate  "-t" 
	[ $? -ne 0 ] &&	do_activate_force "-t" "-f" 

	do_role_invalid "-o" 

	do_role_secondary "-o" 

	do_role_primary "-o" 
	
	# to check the status of drbd
	show_invalid "-s" 

	show "-s" 
	
	# To mount the drdb1 folder 
	do_mount "-m"

	do_folder_invalid "-D"

	# To create folder structure inside /data
	do_folder "-D"

	do_ismounted "-M"

	do_disable_invalid "-d"

	do_disable_unmount "-d" "-u"

	do_assemble_invalid "-A"

	do_assemble "-A"

	do_disable "-d"

	do_assemble_mount "-A" "-m"

	do_remove_invalid "-R"

	do_remove_remote_disk "-R"
	[ $? -ne 0 ] && do_remove_remote_disk_force "-R" "-f"

	do_part_force_verbose "-p" "-f" "-v"

	do_recover_invalid "-r -f"

	# To recover diskB
	do_recover "-r"

	do_speedup_invalid "-U"

	do_speedup "-U" 2G

	do_add_invalid "-a" 

	do_remove_remote_disk "-R"
	[ $? -ne 0 ] && do_remove_remote_disk_force "-R" "-f"

	#do_remove_current_disk "-R"

	do_add_disk "-a -f"

	#  pause and start the synchronozation
	do_stop "-S" "pause -f"
	[ $? == 0 ] && do_start "-S"  "resume -f"

	do_create_invalid "-c -f"

}


## M A I N

# calling all possible scenarios
invoke















