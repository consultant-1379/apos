#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
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
# - Wed Aug 09 2017 - Pratap Reddy Uppada (xpraupp)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CFG_PATH='/opt/ap/apos/conf'
##
# BEGIN: Watchdog handling
pushd $CFG_PATH &>/dev/null
apos_log 'subscribing watchdog timeout value in lde-watchdog.service file..'
apos_servicemgmt subscribe "lde-watchdogd.service" "ExecStartPre" /usr/bin/wdctl \$WATCHDOG_DAEMON_OPTIONS
if [ $? -ne 0 ]; then 
  apos_abort 'failure while subscribing watchdog timeout in lde-watchdog.service file'
fi
apos_servicemgmt restart lde-watchdogd.service || apos_abort 'failure while restarting lde-watchdogd.service'
apos_log 'Done'
popd &>/dev/null
# END: Watchdog handling
##

# R1A05 -> R1A06
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_7 R1A06
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0

exit $TRUE
# End of file

