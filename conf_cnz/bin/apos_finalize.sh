#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_finalize.sh
# Description:
#       A script to finalize the APOS configuration.
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
# - Thu Aug 30 2018 - Suman Kumar Sahu (zsahsum)
#   Renamed the function system_roles_enm to configure_enm_models (aposcfg_axe_sysroles.sh)
# - Mon July 30 2018 - Suman Kumar Sahu (zsahsum)
#   Updated to support new script (aposcfg_axe_sysroles.sh)
#   for configuring ENM roles & rules(MSC/HLR/IPSTP) during MI.
# - Wed Nov 29 2017 - Luisa Cioffi (teiclui)
#   Modified to support new SW upgrade procedure:
#   keep the default values (1) for automaticBackup 
#   and automaticRestore attributes
# - Thu Nov 23 2017 - Swetha Rambathini (xsweram)
#   	Modified symlink of sw_package
# - Fri Mar 04 2016 - Antonio Buonocunto (eanbuon)
#   New function configure_groups for SUGAR.
# - Fri Jan 29 2016 - Antonio Buonocunto (eanbuon)
#   fix in common_finalize for node SC-2-2.
# - Fri Aug 14 2015 - Dharma teja (xdhatej)
#   Added anew configure_ftpstate function.
# - Thu Feb 25 2014 - Antonio Buonocunto (eanbuon)
#   Added a new configure_com functions.
# - Tue Jul 16 2013 - Pratap Reddy (xpraupp)
#   Modified to support both MD and DRBD
# - Tue Jun 04 2013 - Pratap Reddy (xpraupp)
#	Replaced drbdmgr with ddmgr  
# - Mon Apr 29 2013 - Pratap Reddy (xpraupp)
#	APOS reduced: some configurations commented
# - Mon Apr 01 2013 - Tanu Aggarwal (xtanagg)
#  	Replaced RAID with DRBD.
# - Mon Mar 25 2013 - ealfatt, edaebao
#	APOS reduced: some configurations commented
# - Fri Jun 21 2013 - Francesco Rainone (efrarai)
#	Added libcom_cli_agent.cfg handling for both nodes.
# - Tue Jul 16 2013 - Pratap Reddy (xpraupp)
#   Modified to support both MD and DRBD
# - Tue Jun 04 2013 - Pratap Reddy (xpraupp)
#	Replaced drbdmgr with ddmgr  
# - Mon Apr 29 2013 - Pratap Reddy (xpraupp)
#	APOS reduced: some configurations commented
# - Mon Apr 01 2013 - Tanu Aggarwal (xtanagg)
#  	Replaced RAID with DRBD.
# - Mon Mar 25 2013 - ealfatt, edaebao
#	APOS reduced: some configurations commented
# - Wed Nov 14 2012 - Francesco Rainone (efrarai)
#	Moved some COM configuration parameters from here to apos_comconf.sh.
# - Tue Oct 09 2012 - Antonio Buonocunto (eanbuon)
#	Sec configuration without WA
# - Thu Oct 04 2012 - Antonio Buonocunto (eanbuon)
#	Adaptation to new LCT, for sw_package symlink
# - Mon Sep 17 2012 - Antonio Buonocunto (eanbuon)
#  	Script rework for single node execution 
# - Fri Aug 24 2012 - Antonio Buonocunto (eanbuon)
#  	New DNs for Axe Models adaptation
# - Tue Jul 17 2012 - Francesco Rainone (efrarai) & Antonio Buonocunto (eanbuon)
#	Moving libcli_extension_subshell.cfg and libcom_cli_agent.cfg from
#	apos_conf.sh to here.
# - Wed Jun 27 2012 - Alfonso Attanasio (ealfatt)
#	Adaptation to BRF.
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Tue Jan 31 2012 - Francesco Rainone (efrarai)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CFG_PATH="/opt/ap/apos/conf"

# parameters: $1=exit code
function check_exit_code(){
    if [ "$1" -ne 0 ]; then
        apos_abort 1 'unhandled error'
    fi
}

function isMD(){
     [ "$DD_REPLICATION_TYPE" == "MD" ] && return $TRUE
     return $FALSE
}

function isDRBD(){
    [ "$DD_REPLICATION_TYPE" == "DRBD" ] && return $TRUE
    return $FALSE
}

function common_finalize(){
  echo "stopping drbd, mips and (t)ftp on node ${NODE_THIS}..."
  /opt/ap/apos/bin/apos_operations --failover ACTIVE &>/dev/null || apos_abort 1 'failure during apos_operation --failover ACTIVE command execution'
  /opt/ap/apos/bin/apos_operations --cleanup &>/dev/null || apos_abort 1 'failure during apos_operation --cleanup command execution'
  isMD && {
    /opt/ap/apos/bin/raidmgmt -M &>/dev/null
    if [ $? -eq 0 ];then
      apos_log "RAID is mounted, unmounting..."   
      /opt/ap/apos/bin/raidmgmt --unmount &>/dev/null || apos_abort 1 'failure during raidmgmt --disable --unmount command execution'
    else
      apos_log "RAID not mounted, skipping..."
    fi
    if [ "$(/opt/ap/apos/bin/raidmgmt --status)" = "UP" ];then
      apos_log "RAID is enabled, disabling..."
      /opt/ap/apos/bin/raidmgmt --disable &>/dev/null || apos_abort 1 'failure during raidmgmt --disable --unmount command execution'
    else
      apos_log "RAID not enabled, skipping..."
    fi
  }
  isDRBD && {
    /opt/ap/apos/bin/raidmgr --disable --unmount &>/dev/null || apos_abort 1 'failure during raidmgr --disable --unmount command execution'
  }
  echo 'done'
  echo
}

function configure_welcomemessage(){
    pushd '/opt/ap/apos/conf/' >/dev/null
    DEST_DIR=$(apos_create_brf_folder config)		
    [ ! -d $DEST_DIR ] && apos_abort 1 'unable to retrieve welcomemessage configuration folder'
    welcome_file_temp='/opt/ap/apos/conf/welcomemessage.conf'
    if [ -f $welcome_file_temp ];then
        local MESSAGE=$(./apos_deploy.sh --from /opt/ap/apos/conf/welcomemessage.conf --to $DEST_DIR/welcomemessage.conf 2>&1)
        if [ $? -ne 0 ]; then
            apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code. Error: \"${MESSAGE}\""
        fi
    else
        apos_abort 1 'unable to retrieve welcomemessage configuration file'
    fi
    popd >/dev/null
}

function configure_ftpstate(){
    pushd '/opt/ap/apos/conf/' >/dev/null
    DEST_DIR=$(apos_create_brf_folder config)
    [ ! -d $DEST_DIR ] && apos_abort 1 'unable to retrieve ftpstate configuration folder'
    ftpstate_file_temp='/opt/ap/apos/conf/apos_ftp_state.conf'
    if [ -f $ftpstate_file_temp ];then
        local MESSAGE=$(./apos_deploy.sh --from /opt/ap/apos/conf/apos_ftp_state.conf --to $DEST_DIR/ftp_state.conf 2>&1)
        if [ $? -ne 0 ]; then
            apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code. Error: \"${MESSAGE}\""
        fi
    else
        apos_abort 1 'unable to retrieve ftpstate configuration file'
    fi
    popd >/dev/null
}

function configure_models(){
    pushd '/opt/ap/apos/conf/' >/dev/null
    # NetworkConfiguration object configuration in IMM
    if [ -x /opt/ap/apos/conf/apos_models_conf.sh ]; then
        ./apos_models_conf.sh
        if [ $? -ne 0 ]; then
            apos_abort 1 "\"apos_models_conf.sh\" exited with non-zero return code"
        fi
    else
        apos_abort 1 'apos_models_conf.sh not found or not executable'
    fi
    popd >/dev/null
}

function configure_groups(){
    pushd '/opt/ap/apos/conf/' >/dev/null
    if [ -x /opt/ap/apos/conf/aposcfg_appendgroup.sh ]; then
        ./aposcfg_appendgroup.sh
        if [ $? -ne 0 ]; then
            apos_abort 1 "\"aposcfg_appendgroup.sh\" exited with non-zero return code"
        fi
    else
        apos_abort 1 'aposcfg_appendgroup.sh not found or not executable'
    fi
    popd >/dev/null
}


function configure_vdir(){
    pushd '/opt/ap/apos/conf/' >/dev/null
    echo 'performing vdir configuration...'
    if [ -x "/opt/ap/apos/conf/apos_vdirconf.sh" ]; then
        ./apos_vdirconf.sh &>/dev/null || apos_abort 1 "failure while executing apos_vdirconf.sh"	
    else
        apos_abort 1 "file \"apos_vdirconf.sh\" not found or not executable"
    fi
    echo 'done'
    echo
    popd >/dev/null
}

function configure_ecim_swm(){
    local cluster_swm_folder="/storage/no-backup/coremw/SoftwareManagement"
    echo 'performing cmw-swm configuration...'
    if [ -x "/opt/coremw/bin/cmw-swm-config-set" ]; then
        /opt/coremw/bin/cmw-swm-config-set -l $cluster_swm_folder &>/dev/null || apos_abort 1 "failure while executing \"cmw-swm-config-set -l  $cluster_swm_folder\""
        /opt/coremw/bin/cmw-swm-config-set -f -1 &>/dev/null || apos_abort 1 "failure while executing \"cmw-swm-config-set -f 2147483647\""    
    else
        apos_abort 1 "file \"cmw-swm-config-set\" not found or not executable"
    fi
    echo 'done'
}

function configure_apos_verconf(){
    echo 'adding install time to apos_ver.conf...'
    APOS_CONF_FOLDER=$(apos_create_brf_folder config)
    if [ -f /opt/ap/apos/conf/apos_ver.conf ] ; then
        cp /opt/ap/apos/conf/apos_ver.conf $APOS_CONF_FOLDER || apos_abort 1 'failure while copying apos_ver.conf'
    else
        apos_abort 1 'file apos_ver.conf not found'
    fi 
    echo -e "Install Time:\t$(date --utc)" >> $APOS_CONF_FOLDER/apos_ver.conf
    echo 'done'
}

function configure_sec(){
    echo 'setting-up sec.conf...'
    isMD   && STATUS=$(/opt/ap/apos/bin/raidmgmt)
    isDRBD && STATUS=$(/opt/ap/apos/bin/raidmgr --status)
    if [ "$STATUS" != 'DOWN' ]; then
        /opt/ap/apos/conf/aposcfg_sec-conf.sh
        EXIT_C=$?
        check_exit_code $EXIT_C
        echo 'done'		
    fi
}

function configure_ldap(){
    echo 'setting-up initial ldap configuration...'
    if [ -x /opt/ap/apos/conf/apos_ldapconf.sh ] ; then
        /opt/ap/apos/conf/apos_ldapconf.sh
        EXIT_C=$?
        check_exit_code $EXIT_C
        echo 'done'
    else
        apos_abort 1 'file apos_ldapconf.sh not found or not executable'
    fi
}

function configure_enm_models(){
  if [ -x /opt/ap/apos/conf/aposcfg_axe_sysroles.sh ]; then
      /opt/ap/apos/conf/aposcfg_axe_sysroles.sh
      if [ $? -ne 0 ]; then
        apos_abort 1 "\"aposcfg_axe_sysroles.sh\" exited with non-zero return code"
      fi
  else
      apos_abort 1 'aposcfg_axe_sysroles.sh not found or not executable'
  fi
}

# M A I N

HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
[ -z "$HW_TYPE" ] && apos_abort 1 'HW_TYPE not found'

# fetching data storage type varaible
DD_REPLICATION_TYPE=$(get_storage_type)

NODE_THIS=$(/bin/hostname)

case $NODE_THIS in
    SC-2-1)
        apos_log "configure_welcomemessage..."
        configure_welcomemessage 
        apos_log "done" 

        apos_log "configure_ftpstate..."
        configure_ftpstate
        apos_log "done"

        apos_log "configure_models..."
        configure_models
        apos_log "done"

        apos_log "configure_vdir..."
        configure_vdir
        apos_log "done"

        apos_log "configure_ecim_swm..."
        configure_ecim_swm
        apos_log "done"

        apos_log "configure_apos_verconf..."
        configure_apos_verconf
        apos_log "done"

        apos_log "configure_sec..."
        configure_sec
        apos_log "done"

        apos_log "configure_groups..."
        configure_groups
        apos_log "done"

        apos_log "common_finalize..."
        common_finalize
        apos_log "done"
	
        apos_log "configure_enm_models..."
        configure_enm_models
        apos_log "done"
    ;;
    SC-2-2)
        apos_log "configure_groups..."
        configure_groups
        apos_log "done"

        apos_log "common_finalize..."
        common_finalize
        apos_log "done"
    ;;
    *)
        apos_abort "Invalid NODE NAME found"
esac

apos_outro $0
exit $TRUE

# End of file
