#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1E.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Fri 18 Sep - Yeswanth Vankayala (xyesvan)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CFG_PATH="/opt/ap/apos/conf"
SRC="/opt/ap/apos/etc/deploy"

pushd $CFG_PATH &> /dev/null
#for generating audit.rules file dynamically using file present under /etc/audit/rules.d folder
echo "Deploying APG audit rules file 901-apg-users.rules "
./apos_deploy.sh --from "$SRC/etc/audit/rules.d/901-apg-users.rules"  --to "/etc/audit/rules.d/901-apg-users.rules"
[ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of 901-apg-users.rules file"

popd &> /dev/null

echo "Loading augenrules"
/sbin/augenrules --load 
[ $? -ne 0 ] && apos_abort 1 "failed to load augenrules"

pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null


# R1E -> R1A01
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_13 R1A01
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

