#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A05.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Fri 27 Aug - Neelam Kumar (xneelku)
#        Changes for vBSC: RP-VM ssh keys management
# Sat 21 Aug - Sowjanya Medak (xsowmed)
#        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"

# BEGIN: rsyslog configuration changes
apos_log 'Configuring Syslog Changes _14/fromR1A05 .....'
SYSLOG_CONFIG_FILE='usr/lib/lde/config-management/apos_syslog-config'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${SYSLOG_CONFIG_FILE}" --to "/${SYSLOG_CONFIG_FILE}" || \
  apos_abort "failure while deploying syslog configuration file"
  "/${SYSLOG_CONFIG_FILE}" config reload &>/dev/null || \
  apos_abort 'Failure while reloading syslog configuration file'
popd &>/dev/null
apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'
# END: rsyslog configuration changes


#BEGIN : vBSC : RP-VM SSH KEYS MANAGEMENT
if isvBSC; then
##
# BEGIN: Deployment of sudoers
# vBSC: keymgmt command
  pushd $CFG_PATH &> /dev/null
    ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsadmin" --to "/etc/sudoers.d/APG-tsadmin"
  popd &> /dev/null
##
fi
#END : vBSC : RP-VM SSH KEYS MANAGEMENT


# BEGIN: PAM configuration changes for systemd module start
apos_log 'Configuring systemd module Changes _14/fromR1A05 .....'
PAM_SESSION_SUCCESS_FILE="etc/pam.d/acs-apg-session-success"
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${PAM_SESSION_SUCCESS_FILE}" --to "/${PAM_SESSION_SUCCESS_FILE}" || \
apos_abort "failure while deploying /${PAM_SESSION_SUCCESS_FILE}"
popd &>/dev/null
# END: PAM configuration changes for systemd module end


#BEGIN:PAM configuration changes for password hardening feature
apos_log 'Configuring APG PAM changes _14/fromR1A05 .....'
APG_PAM_CONFIG_FILE='/etc/pam.d/acs-apg-password-local'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${APG_PAM_CONFIG_FILE}" --to "/${APG_PAM_CONFIG_FILE}" || \
  apos_abort "failure while deploying APG pam configuration file" \
  "/${APG_PAM_CONFIG_FILE}"
popd &>/dev/null
#END:PAM configuration changes for password hardening feature

# R1A05 -> R1A06
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_14 R1A06
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

