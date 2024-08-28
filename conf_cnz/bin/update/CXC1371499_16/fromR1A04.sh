#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A04.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Tue 02 Aug - Swapnika Baradi (xswapba)
#        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CACHE_DIR="/dev/shm/"
CACHE_FILE="${CACHE_DIR}/apos_hwtype.cache"
CACHE_FILE_VERBOSE="${CACHE_DIR}/apos_hwtype_verbose.cache"
CMD_RM="/usr/bin/rm"

[ -f "$CACHE_FILE" ] && $CMD_RM $CACHE_FILE
[ -f "$CACHE_FILE_VERBOSE" ] && $CMD_RM $CACHE_FILE_VERBOSE

# update ruleId=AxeApCmd_71 in imm for rpswrprint command
/usr/bin/cmw-utility immcfg -a userLabel='Execute permission to execute AP commands aehls, alist, alogfind, csadm, fqdndef, ldapdef, ipsecdef, ipsecls, ipsecrm, rpswrprint, sec-encryption-key-update, wssadm' -a ruleData='regexp:alogset|aloglist|alogpchg|alogpls|aehls|alist|alogfind|csadm|fqdndef|ldapdef|ipsec.*|rpswrprint|sec-encryption-key-update|wssadm.*' ruleId=AxeApCmd_71,roleId=SystemSecurityAdministrator,localAuthorizationMethodId=1
if [ $? -eq 0 ]; then
  apos_log "ruleId=AxeApCmd_71 is updated successfully"
else
  apos_log "Failed to update ruleId=AxeApCmd_71"
fi

# R1A04 -> R1B
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_16 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#
apos_outro $0
exit $TRUE
