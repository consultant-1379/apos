#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A04.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1A04.
# Note:
#	None.
##
# Changelog:
# - Thu Apr 16 2015 - Yeswanth Vankayala(XYESVAN)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
SRC='/opt/ap/apos/etc/deploy'
CFG_PATH='/opt/ap/apos/conf'
# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)


# R1A04 --> R1A05
#------------------------------------------------------------------------------#

##
# BEGIN: lde-config script configuration
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_sshd-config" --to "/usr/lib/lde/config-management/apos_sshd-config" || apos_abort "failure while deploying lde-config file"
./apos_insserv.sh /usr/lib/lde/config-management/apos_sshd-config || apos_abort "failure while deploying lde-config file symlink"
popd &>/dev/null
# END: lde-config script configuration
##

##
# BEGIN: libcli_extension_subshell update
pushd $CFG_PATH &> /dev/null
if [ -x /opt/ap/apos/conf/apos_deploy.sh ]; then
  if [ -x /opt/com/util/com_config_tool ]; then
    DEST_DIR=$(/opt/com/util/com_config_tool location)
  else
    DEST_DIR='/storage/system/config/com-apr9010443'
  fi
  [ ! -d $DEST_DIR ] && apos_abort 1 'unable to retrieve COM configuration folder'
  # libcli_extension_subshell.cfg
  if [ "$AP2" == "$AP_TYPE" ]; then
    ./apos_deploy.sh --from /opt/ap/apos/conf/libcli_extension_subshell_ap2.cfg --to $DEST_DIR/lib/comp/libcli_extension_subshell.cfg
  else
    ./apos_deploy.sh --from /opt/ap/apos/conf/libcli_extension_subshell.cfg --to $DEST_DIR/lib/comp/libcli_extension_subshell.cfg
  fi
  if [ $? -ne 0 ]; then
    apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
  fi
fi
popd &> /dev/null
# END:  libcli_extension_subshell update
##

##
# BEGIN: fix for openldap server to run with sec-credu-users group
pushd $CFG_PATH &> /dev/null
  if [ "$AP_TYPE" != "$AP2" ]; then
    GRP_N=$(getent group sec-credu-users|wc -l)
    [ "$GRP_N" -ne 1 ] && apos_abort 'failure while checking for the group "sec-credu-users" existance'
    ./apos_deploy.sh --from /opt/ap/apos/etc/deploy/etc/sysconfig/openldap --to /etc/sysconfig/openldap
    if /sbin/service ldap status &>/dev/null; then
        apos_log "user.warning" "found ldap server running. Executing restart"
        /sbin/service ldap restart || apos_abort "failure while restarting ldap server"
    fi
  fi
popd
# END:   fix for openldap server to run with sec-credu-users group
##

#------------------------------------------------------------------------------#

# R1A05 -> R1A06
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R1A05
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A05"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
