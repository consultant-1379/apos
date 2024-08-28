#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A04.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Wed Apr 21 - Sravanthi ( xsravan)
# FirstDraft
#
###

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"

##
# BEGIN: Deployment of sudoers and watchdog
STORAGE_TYPE=$(get_storage_type)
pushd $CFG_PATH &> /dev/null

if [ "$STORAGE_TYPE" == "MD" ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup"
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_md" --to "/etc/sudoers.d/APG-comgroup"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_drbd" --to "/etc/sudoers.d/APG-comgroup"
fi

sed -i '/ExecStartPre=-\/usr\/bin\/wdctl $WATCHDOG_DAEMON_OPTIONS/d' /usr/lib/systemd/system/lde-watchdogd.service
 echo 'subscribing watchdog timeout value in lde-watchdog.service file..'
 WATCHDOG_INTERVAL="-s 180"
 apos_servicemgmt subscribe "lde-watchdogd.service" "ExecStartPre" /usr/bin/wdctl $WATCHDOG_INTERVAL || apos_abort 'failure subscribing watchdog timeout..'
 apos_servicemgmt restart lde-watchdogd.service &>/dev/null || apos_abort 'failure while restarting lde-watchdog service'
 echo 'done'
popd &> /dev/null
# END: Deployment of sudoers adn watchdog
##

# R1A02 -> R1A03
#------------------------------------------------------------------------------#
########BEGIN: To create "aposcfg_libcli_extension_subshell.cfg" file with the changes and update####################
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null
# END: Deployment of sudoers
##


# R1A03 -> R1A04
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_12 R1A04
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
