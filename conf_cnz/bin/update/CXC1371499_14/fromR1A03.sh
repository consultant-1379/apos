#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A03.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
#
# Changelog:
# Fri 06 Aug - Anjireddy D(xdakanj)
#      Changes for RSYSLOG Adoption feature; redeploy of APG-comgroup_md and APG-comgroup_drbd files
# Thu 05 Aug - Anjali M (xanjali)
#      Changes for vBSC: RP-VM ssh keys management
# Mon 26 July - Pravalika P(zprapxx)
#      Changes for RSYSLOG Adoption feature; redeploy of apos_syslog-config file
# Mon 19 Jul - Sowjanya Gvl
#	Impacts for Password and brf features
#        First Version

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"

##
# BEGIN: rsyslog configuration changes
apos_log 'Configuring Syslog Changes _14/fromR1A03 .....'
SYSLOG_CONFIG_FILE='usr/lib/lde/config-management/apos_syslog-config'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${SYSLOG_CONFIG_FILE}" --to "/${SYSLOG_CONFIG_FILE}" || \
  apos_abort "failure while deploying syslog configuration file"
  "/${SYSLOG_CONFIG_FILE}" config reload &>/dev/null || \
  apos_abort 'Failure while reloading syslog configuration file'
popd &>/dev/null
apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'
# END: rsyslog configuration changes

#BEGIN:PAM configuration changes for password hardening feature
apos_log 'Configuring APG PAM changes .....'
APG_PAM_CONFIG_FILE='/etc/pam.d/acs-apg-password-local'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${APG_PAM_CONFIG_FILE}" --to "/${APG_PAM_CONFIG_FILE}" || \
  apos_abort "failure while deploying APG pam configuration file" \
  "/${APG_PAM_CONFIG_FILE}"
popd &>/dev/null
#END:PAM configuration changes for password hardening feature

# BEGIN: Update of aposcfg_syslog-conf.sh for SSH events from LDE
apos_log 'Configuring audispd Changes _14/fromR1A03 .....'
pushd $CFG_PATH &>/dev/null
 apos_check_and_call $CFG_PATH aposcfg_syslog-conf.sh
popd &> /dev/null
apos_servicemgmt restart auditd.service &>/dev/null ||  apos_log 'failure while restarting auditd service'
# END: Update of aposcfg_syslog-conf.sh for SSH events from LDE


#BEGIN : vBSC : RP-VM SSH KEYS MANAGEMENT
if isvBSC; then

  pushd $CFG_PATH &>/dev/null
    apos_check_and_call $CFG_PATH aposcfg_rp_sshkey_mgmt.sh
  
    # BEGIN: set up /etc/syncd.conf 
    apos_check_and_call $CFG_PATH aposcfg_syncd-conf.sh

  popd &>/dev/null

# Update the permissions for id_rsa file
  storage_home_dir="/storage/system/config/apos/ssh_keys"
  if [ -f $storage_home_dir/id_rsa ];then
    chmod 640 $storage_home_dir/id_rsa
    if [ $? -ne 0 ];then
      apos_log " ERROR: Failed to apply 640 permissions to id_rsa file"
    else
      apos_log "INFO: Applied 640 permissions to id_rsa file"
    fi
    chown tsadmin:tsgroup $storage_home_dir/id_rsa
    if [ $? -ne 0 ];then
       apos_log "ERROR: Failed to change the ownership tsadmin:tsgroup ssh-keys"
    else
       apos_log "Changed the ownership to tsadmin:tsgroup for ssh keys"
    fi
  fi

##
# BEGIN: Deployment of sudoers
# vBSC: keymgmt command
  pushd $CFG_PATH &> /dev/null
    ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsadmin" --to "/etc/sudoers.d/APG-tsadmin"
  popd &> /dev/null
##
fi
#END : vBSC : RP-VM SSH KEYS MANAGEMENT

# BEGIN: Deployment of sudoers
STORAGE_TYPE=$(get_storage_type)
pushd $CFG_PATH &> /dev/null

if [ "$STORAGE_TYPE" == "MD" ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_md" --to "/etc/sudoers.d/APG-comgroup"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_drbd" --to "/etc/sudoers.d/APG-comgroup"
fi
popd &> /dev/null
# END: Deployment of sudoers

# BEGIN: Updating cluster configuration file for host entry related to ldap fallback server(replacing "control" target with "all" one)
pushd /opt/ap/apos/bin/clusterconf/ &>/dev/null
NUM_HOSTS_ROW="$(./clusterconf host -D | grep " control " | wc -l)"
if [ $NUM_HOSTS_ROW -gt 0 ]; then
  for ((i=0;i<$NUM_HOSTS_ROW;i++)); do
    # to retrieve latest snapshot from cluster configuration file
    HOSTS_ROWS="$(./clusterconf host -D | grep " control ")"
    # to retrieve the index in the row at first position
    idx=$(echo "$HOSTS_ROWS" | awk 'NR == 1' | awk -F ' ' '{print $1}')
    fallback_server_ip_address=$(echo "$HOSTS_ROWS" | awk 'NR == 1' | awk -F ' ' '{print $4}')
    fallback_server_name=$(echo "$HOSTS_ROWS" | awk 'NR == 1' | awk -F ' ' '{print $5}')
    # to delete the row accordingly
    ./clusterconf host -d $idx &>/dev/null
    if [ $? -ne 0 ];then
      echo -e "Error while executing cluster conf update, entry removal (general fault)\n"
      exit 1
    fi

    # to replace the entry with same one, but having now "all" as target
    ./clusterconf host --add all $fallback_server_ip_address $fallback_server_name &>/dev/null
    if [ $? -ne 0 ];then
      echo -e "Error while executing cluster conf update executing, entry update (general fault)\n"
      exit 1
    fi
  done
fi
popd &>/dev/null
# END: Updating cluster configuration file for host entry related to ldap fallback server


# R1A03 -> R1A04
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_14 R1A04
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

