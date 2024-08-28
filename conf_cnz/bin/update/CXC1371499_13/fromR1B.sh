#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A12.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Thrusday Feb 04 - Sowjanya Medak (xsowmed)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
CFG_PATH='/opt/ap/apos/conf'

#BEGIN: Fix for TR HY83225
pushd $CFG_PATH &>/dev/null
apos_log 'subscribing dhcp service pid removal .....'
apos_servicemgmt subscribe "apg-dhcpd.service" "ExecStartPre" /usr/bin/rm -f /var/run/dhcpd.pid || apos_abort 'failure subscribing pid removal.'

apos_servicemgmt restart apg-dhcpd.service || apos_abort 'failure while restarting apg-dhcpd.service'
apos_log 'Done'
popd &>/dev/null
# END



# R1B -> R1C
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_13 R1C
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

