#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1E.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Wed 04 July - Debdutta Chatterjee (xdebdch)
#        First Version 
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"

# BEGIN: Deployment of sudoers
STORAGE_TYPE=$(get_storage_type)
AP_TYPE=$(apos_get_ap_type)
pushd $CFG_PATH &> /dev/null
if [ "$STORAGE_TYPE" == "MD" ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_md" --to "/etc/sudoers.d/APG-comgroup" || apos_abort "failure while deploying APG-comgroup_md file"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_drbd" --to "/etc/sudoers.d/APG-comgroup" || apos_abort "failure while deploying APG-comgroup_drbd file"
fi

if [ "$STORAGE_TYPE" == "MD" ] ; then
    ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup" || apos_abort "failure while deploying APG-tsgroup_md file"
else
      ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup" || apos_abort "failure while deploying APG-tsgroup_drbd file"
fi

popd &> /dev/null
# END: Deployment of sudoers
##

# BEGIN: com configuration handling
#To create "aposcfg_libcli_extension_subshell.cfg" file and update#########
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null
# END: com configuration handling

# update ruleId=AxeApCmd_71 in imm for rpswrprint command
/usr/bin/cmw-utility immcfg -a userLabel='Execute permission to execute AP commands aehls, alist, alogfind, csadm, fqdndef, ldapdef, rpswrprint, ipsecdef, ipsecls, ipsecrm, sec-encryption-key-update, wssadm' -a ruleData='regexp:alogset|aloglist|alogpchg|alogpls|aehls|alist|alogfind|csadm|fqdndef|ldapdef|rpswrprint|ipsec.*|sec-encryption-key-update|wssadm.*' ruleId=AxeApCmd_71,roleId=SystemSecurityAdministrator,localAuthorizationMethodId=1
if [ $? -eq 0 ]; then
  apos_log "ruleId=AxeApCmd_71 is updated successfully"
else
  apos_log "Failed to update ruleId=AxeApCmd_71"
fi

# R1E -> R1A01
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_16 R1A01
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

