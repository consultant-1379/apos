#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A11.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Fri Jul 30 - Anjali M (xanjali)
#        Updated TR HY56862 changes
# Thu Jul 30 - Sravanthi (xsravan)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# BEGIN : TR HY56862 
# Get the AP type
AP_TYPE=$(apos_get_ap_type)
[ -z "$AP_TYPE" ] && apos_abort "AP_TYPE not found"

if [ "$AP_TYPE" == 'AP1' ]; then
  # BEGIN: Fix for hcstart issue
  apos_servicemgmt disable apg-vsftpd-APIO_1.socket &>/dev/null || apos_abort 'Failure while disabling apg-vsftpd-APIO_1.socket'

  apos_servicemgmt disable apg-vsftpd-APIO_2.socket &>/dev/null || apos_abort 'Failure while disabling apg-vsftpd-APIO_2.socket'

fi
# END : TR HY56862 

apos_log 'subscribing ExecStartPost in lde-iptables.service file..'
apos_servicemgmt subscribe "lde-iptables.service" "ExecStartPost" /opt/ap/apos/conf/apos_nbi_security.sh ||\
 apos_abort 'failure subscribing NBI rules..'
apos_log 'done'

apos_log 'restarting iptables daemon...'
apos_servicemgmt restart lde-iptables.service &>/dev/null || apos_abort 'failure while restarting iptables service'
apos_log 'done'

# R1A10 -> R1A11
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_12 R1A12
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
