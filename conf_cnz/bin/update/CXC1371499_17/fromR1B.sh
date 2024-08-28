#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1B.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue Fe 21 2023 - Naveen Kumar G (ZGXXNAV)
#   SSH hardenening by configuring clientAlive parameters to handle unresponsive ssh sessions after 15 mins 
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC='/opt/ap/apos/etc/deploy'

# BEGIN: SSH hardenening by configuring clientAlive parameters to handle unresponsive ssh sessions after 15 mins, impacts in 
# sshd_config_4422 file

pushd $CFG_PATH &> /dev/null

./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_4422 --to /etc/ssh/sshd_config_4422
if [ $? -ne 0 ]; then
  apos_abort 1 "failure while deploying \"sshd_config_4422\" file"
fi


popd &>/dev/null

# R1B -> R1C
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_17 R1C
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
