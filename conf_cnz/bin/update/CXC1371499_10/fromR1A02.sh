#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version 
# Note:
#       None.
##
# Changelog:
# - 18 Apr 2019 - Pratap Reddy (xpraupp)
#       LDEwS microcode impacts
# - 29 Mar 2019 - Suman Sahu
#        FTP over TLS feature 
# - 29 Mar 2019 - Prasanna (xlplplp)
#       First Draft (rsyslog changes for alog tls)
# - 28 Mar 2019 - Pravalika P (zprapxx)
#       First Draft (ANSII - Linux file permissions )
# - 22 Mar 2019 - G V L SOWWJANYA (xsowgvl)
#       First Draft 
##


# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
#Common variables
CFG_PATH="/opt/ap/apos/conf"
SRC="/opt/ap/apos/etc/deploy"


# BEGIN: deploying acs-apg-session-heading
 pushd $CFG_PATH &> /dev/null

./apos_deploy.sh --from "/opt/ap/apos/etc/deploy/etc/pam.d/acs-apg-session-heading" --to "/etc/pam.d/acs-apg-session-heading" \
      || apos_abort "Failure during the update of acs-apg-session-heading"

 popd &>/dev/null
# END: deploying acs-apg-session-heading

##
# BEGIN: rsyslog configuration changes
SYSLOG_CONFIG_FILE='/usr/lib/lde/config-management/apos_syslog-config'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${SYSLOG_CONFIG_FILE}" --to "${SYSLOG_CONFIG_FILE}" || \
  apos_abort "failure while deploying syslog configuration file"
  ${SYSLOG_CONFIG_FILE} config reload &>/dev/null || \
  apos_abort 'failure while restarting syslog service'
popd &>/dev/null
# END: rsyslog configuration changes
##

#Start of ANSII linux file permission impacts
pushd $CFG_PATH &> /dev/null
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_syslog-config" --to "/usr/lib/lde/config-management/apos_syslog-config"
/usr/lib/lde/config-management/apos_syslog-config config reload
if [ $? -ne 0 ];then
  apos_abort "Failure while executing apos_syslog-config"
fi
popd &> /dev/null
apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'
#End of ANSII linux file permission impacts

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling

# BEGIN: Sudoers file handling
STORAGE_TYPE=$(get_storage_type)
pushd $CFG_PATH &>/dev/null
if [ "$STORAGE_TYPE" == 'MD' ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup" || \
     apos_abort "failure while deploying APG-tsgroup sudoers file"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup" || \
     apos_abort "failure while deploying APG-tsgroup sudoers file"
fi
popd &>/dev/null
# END: Sudoers file handling

# R1A02 -> R1A03
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_10 R1A03
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

