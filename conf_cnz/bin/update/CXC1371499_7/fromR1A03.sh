#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A03.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Wed Jun 21 2017 - Suryanarayana Pammi(xpamsur)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
##
# BEGIN: com configuration handling
##
#apos_check_and_call $CFG_PATH apos_comconf.sh
COM_CLUSTER_PATH="/cluster/storage/system/config/com-apr9010443/lib/comp/coremw-com-sa.cfg"
COM_CONFIG_PATH="/opt/com/lib/comp/coremw-com-sa.cfg"
sed -i 's#\(<lockMoForConfigChange>\)false\(</lockMoForConfigChange>\)#\1'true'\2#g' $COM_CLUSTER_PATH
if [ $? -ne 0 ]; then
  apos_abort 1  "Failed to Configure LockMO attribute in $COM_CLUSTER_PATH"
fi

sed -i 's#\(<lockMoForConfigChange>\)false\(</lockMoForConfigChange>\)#\1'true'\2#g' $COM_CONFIG_PATH
if [ $? -ne 0 ]; then
  apos_abort 1  "Failed to Configure LockMO attribute in $COM_CONFIG_PATH"
fi
##
# END: com configuration handling
##

# R1A03 -> R1A04
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_7 R1A04
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0

exit $TRUE
# End of file

