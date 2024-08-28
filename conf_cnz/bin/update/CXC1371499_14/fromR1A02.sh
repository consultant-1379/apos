#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
#
# Changelog:
# Wed 07 Jul - Gnaneswara Seshu (zbhegna)
#      impcats for lde 4.18 and COM7.18 integrtion
# Tue Jul 07 - Rajeshwari Padavala (xcsrpad)
#      Creating new folder logm in /var/log for logm Export functionality
# Mon 28 June - Pravalika P(zprapxx)
#      Changes for RSYSLOG Adoption feature; added sftp logging in ssh configuration file
# Mon 24 June - Komal L (xkomala)
#        First Version

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"

##
# BEGIN: Deployment of sudoers
STORAGE_TYPE=$(get_storage_type)
pushd $CFG_PATH &> /dev/null

if [ "$STORAGE_TYPE" == "MD" ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
fi
popd &> /dev/null
# END: Deployment of sudoers

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null
# END: com configuration handling

#BEGIN: sftp logging for security_audit
pushd $CFG_PATH &> /dev/null
./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_22 --to /etc/ssh/sshd_config_22
if [ $? -ne 0 ]; then
  apos_abort 1 "failure while deploying \"sshd_config_22\" file"
fi
if systemctl -q is-active lde-sshd@sshd_config_22.service;then
  apos_log "Restarting lde-sshd@sshd_config_22.service.."
  systemctl restart lde-sshd@sshd_config_22.service || apos_abort "Failure while restarting lde-sshd@sshd_config_22.service"
else
  apos_log "Unable to restart lde-sshd@sshd_config_22.service"
fi
popd &>/dev/null
#END: sftp logging for security_audit

#Update the logm_info.conf file
logm_file="/opt/ap/apos/conf/logm_info.conf"
if [ -e $logm_file ]; then 
   sed -i 's/LOGM_FIRST_UPGRADE:NO/LOGM_FIRST_UPGRADE:YES/' $logm_file
   if [ $? -ne 0 ]; then
        apos_log "Failure setting the value in logm_info.conf file "
   else
        apos_log "Successfully modified the value in logm_info.conf file"
   fi
else
   apos_log "logm_info.conf file not present"
fi

##
# BEGIN: rsyslog configuration changes
apos_log 'Configuring Syslog Changes _14/fromR1A02 .....'
SYSLOG_CONFIG_FILE='usr/lib/lde/config-management/apos_syslog-config'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${SYSLOG_CONFIG_FILE}" --to "/${SYSLOG_CONFIG_FILE}" || \
  apos_abort "failure while deploying syslog configuration file"
  "/${SYSLOG_CONFIG_FILE}" config reload &>/dev/null || \
  apos_abort 'Failure while reloading syslog configuration file'
popd &>/dev/null
apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'
# END: rsyslog configuration changes


# R1A02 -> R1A03
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_14 R1A03
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

