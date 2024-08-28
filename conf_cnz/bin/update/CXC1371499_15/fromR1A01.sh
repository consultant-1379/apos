#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A01.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
##Thu 03 Mar - SOWJANYA GVL (xsowgvl)
##       Update the script for CBA Q1/2022 Integration in APG4.3
# Mon 07 March - SOWJANYA MEDAK (xsowmed)
#        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling

# BEGIN: deploying telnet client configuration
apos_log 'Configuring telnet client Changes _15/fromR1A01 .....'
pushd $CFG_PATH &> /dev/null
./apos_deploy.sh --from $SRC/etc/services_md --to /etc/services
if [ $? -ne 0 ]; then
  apos_abort  "failure while deploying telnet client configuration"
fi

./apos_deploy.sh --from $SRC/etc/services_drbd --to /etc/services
if [ $? -ne 0 ]; then
  apos_abort  "failure while deploying telnet client configuration"
fi
popd &>/dev/null
# END:deploying telnet client configuration

# R1A01 -> R1A02
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_15 R1A02
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
