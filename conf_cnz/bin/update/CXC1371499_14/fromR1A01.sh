#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A01.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Fri Jun 18 - Amrutha Padi (zpdxmrt)
#        Fix for HY86304
# Fri Jun 18 - Dharma Theja (xdhatej)
#	 Introducing the apg customized rule for log rotation HZ10718
# Fri 11 June - Suryanarayana Pammi(xpamsur)
#      Changes in from script for Syslog Adaptation
# Wed 16 Jun - zbhegna
#        First Version
##Thu 17 Jun - xsravan
##       Update tge script with APG-tsadmin file change for SecurityEnhancement Feature

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"

##
# BEGIN: Deployment of sudoers
pushd $CFG_PATH &> /dev/null
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsadmin" --to "/etc/sudoers.d/APG-tsadmin"
popd &> /dev/null
##
# BEGIN: rsyslog configuration changes
apos_log 'Configuring Syslog Changes _14/fromR1A01 .....'
SYSLOG_CONFIG_FILE='usr/lib/lde/config-management/apos_syslog-config'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${SYSLOG_CONFIG_FILE}" --to "/${SYSLOG_CONFIG_FILE}" || \
  apos_abort "failure while deploying syslog configuration file"
  "/${SYSLOG_CONFIG_FILE}" config reload &>/dev/null || \
  apos_abort 'Failure while reloading syslog configuration file'
popd &>/dev/null
apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'
# END: rsyslog configuration changes

# BEGIN: deploying apos_grub-config
 pushd $CFG_PATH &> /dev/null
./apos_deploy.sh --from $SRC/usr/lib/lde/config-management/apos_grub-config --to /usr/lib/lde/config-management/apos_grub-config
if [ $? -ne 0 ]; then
  apos_abort  "failure while deploying \"apos_grub-config\" file"
fi
# Reload the apos_gub-config file to apply the changes
/usr/lib/lde/config-management/apos_grub-config config reload
if [ $? -ne 0 ]; then
  apos_abort  "Reload of  \"apos_grub-config\" file got failed"
fi

# BEGIN: set up /ets/syncd.conf with AP2 file
apos_check_and_call $CFG_PATH aposcfg_syncd-conf.sh
# END: set up /ets/syncd.conf with AP2 fil

popd &>/dev/null
# END: deploying apos_grub-config

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling

# BEGIN updating apos_hwinfo command cache file
pushd $CFG_PATH &>/dev/null
./apos_hwinfo.sh --cleancache
./apos_hwinfo.sh --all &>/dev/null
popd &> /dev/null
# END

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


# R1A01 -> R1A02
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_14 R1A02
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

