#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A10.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version 
# Note:
#       None.
##
# Changelog:
# - Fri Mar 22 2019 - G V L SOWJANYA (XSOWGVL)
#   Uncommented calling of CXC1371499_10  R1A01 script  
# - Wed Feb 13 2019 - Nazeema Begum (xnazbeg)
#       First version.
##


# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
#Common variables
CFG_PATH="/opt/ap/apos/conf"
SRC='/opt/ap/apos/etc/deploy'
LDE_CONFIG_MGMT='usr/lib/lde/config-management'
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
SOCK_PATH='usr/lib/systemd/system/'
CMD_RM='/usr/bin/rm'


# nfs thread count change for gep1
# WORKAROUND FOR JOURNALD SOCKET MEMORY FIX: BEGIN
pushd $CFG_PATH &> /dev/null
if [ "$HW_TYPE"  == "GEP1" ] || [ "$HW_TYPE"  == "GEP2" ]; then
  apos_check_and_call $CFG_PATH apos_cba_workarounds.sh
  [ ! -f /etc/systemd/journald.conf ] && apos_abort 'journald.conf file not found'
  if grep -q '^#Storage=.*$' /etc/systemd/journald.conf 2>/dev/null; then
    sed -i 's/#Storage=.*/Storage=none/g' /etc/systemd/journald.conf 2>/dev/null || \
    apos_abort 'Failure while updating journald.conf file with Storage=none parameter'
    # Re-start the systemd-journald.service
    apos_servicemgmt restart systemd-journald.service &>/dev/null || apos_abort 'failure while restarting systemd-journald service'
  else
    apos_log 'WARNING: Storage value found different than auto. Skipping configuration changes'
  fi

        # Cleanup of Journal directory
        if [ -d /run/log/journal ]; then
                /usr/bin/rm -rf '/run/log/journal' 2>/dev/null || apos_log 'failure while cleaning up journal folder'
        fi
fi
popd &> /dev/null
# WORKAROUND FOR JOURNALD SOCKET MEMORY FIX: END 



# BEGIN: apos_ip-config script configuration
pushd $CFG_PATH &> /dev/null
[ ! -x ./apos_deploy.sh ] && apos_abort 1 "$CFG_PATH/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/$LDE_CONFIG_MGMT/apos_ip-config" --to "/$LDE_CONFIG_MGMT/apos_ip-config"
[ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of apos_ip-config file"
./apos_deploy.sh --from "$SRC/$SOCK_PATH/apg-vsftpd-nbi.socket" --to "/$SOCK_PATH/apg-vsftpd-nbi.socket"
[ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of apg-vsftpd-nbi.socket file"
popd &> /dev/null

# Reload the config file on the current node
/$LDE_CONFIG_MGMT/apos_ip-config config init
[ $? -ne 0 ] && apos_abort "Failure while executing apos_ip-config"

cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
# END: apos_ip-config script configuration
##

##
# BEGIN: Deployment of sudoers
STORAGE_TYPE=$(get_storage_type)
AP_TYPE=$(apos_get_ap_type)
pushd $CFG_PATH &> /dev/null
if [ "$STORAGE_TYPE" == "MD" ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_md" --to "/etc/sudoers.d/APG-comgroup"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_drbd" --to "/etc/sudoers.d/APG-comgroup"
fi

if [ "$STORAGE_TYPE" == "MD" ] ; then
    ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup"
else
      ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
fi

popd &> /dev/null
# END: Deployment of sudoers
##


# BEGIN: Add sec-encryption-key-update command in libcli_extension_subshell.cfg file
 pushd $CFG_PATH &> /dev/null
 [ ! -x /opt/ap/apos/conf/aposcfg_libcli_extension_subshell.sh ] && apos_abort 1 '/opt/ap/apos/conf/aposcfg_libcli_extension_subshell.sh not found or not executable'
 ./aposcfg_libcli_extension_subshell.sh
 popd &>/dev/null
# END: Add sec-encryption-key-update command in libcli_extension_subshell.cfg file


# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
# END: com configuration handling



# R1A10 -> R1A01
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_9 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

