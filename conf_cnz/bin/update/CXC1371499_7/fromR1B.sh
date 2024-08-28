#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
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
# - Thu Oct 18 2017 - Anjali M (xanjali)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH="/opt/ap/apos/conf"

##
# BEGIN: SEC debug level handling and sshd configuration
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_secacs-toolkit.sh
apos_check_and_call $CFG_PATH aposcfg_sshd_config.sh
popd &>/dev/null
# END:  SEC debug level handling and sshd configuration
##


# BEGIN: Restart the ssh target
apos_servicemgmt restart lde-sshd.target &>/dev/null || apos_abort 'failure while restarting lde-sshd target'
# END: Restart the ssh target


# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling


#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_7 R1C
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
