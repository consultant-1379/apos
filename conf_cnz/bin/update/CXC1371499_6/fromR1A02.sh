#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Mon Jan 16 2017 - Neeraj Kasula (XNEEKAS)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

SRC='/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts'
DEST='/usr/lib/systemd/scripts'
CFG_PATH="/opt/ap/apos/conf"

apos_intro $0

# R1A02 -> R1A03
#------------------------------------------------------------------------------#
##
# BEGIN: libcli_extension_subshell update 
if [ ! -x /opt/ap/apos/conf/aposcfg_libcli_extension_subshell.sh ]; then
  apos_abort 1 "\"aposcfg_libcli_extension_subshell.sh\" does not exist or does not have execute permission"
fi

#generate libcli_extension_subshell.cfg
pushd $CFG_PATH &> /dev/null
./aposcfg_libcli_extension_subshell.sh
if [ $? -ne 0 ]; then
  apos_abort 1 "\"aposcfg_libcli_extension_subshell.sh\" exited with non-zero return code"
fi
popd &> /dev/null
# END: libcli_extension_subshell update
##

##
# BEGIN: DHCP configuration update
ITEM='apg-dhcpd.sh'
pushd $CFG_PATH &> /dev/null

./apos_deploy.sh --from $SRC/$ITEM --to $DEST/$ITEM
[ ! $? = 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
popd &> /dev/null
# END: DHCP configuration update
##
#------------------------------------------------------------------------------#
##
#BEGIN Deployment of post-installation hooks
pushd $CFG_PATH &> /dev/null
[ ! -x /opt/ap/apos/conf/apos_deploy.sh ] && apos_abort 1 '/opt/ap/apos/conf/apos_deploy.sh not found or not executable'
./apos_deploy.sh --from "$SRC/cluster/hooks/post-installation.tar.gz" --to "/cluster/hooks/post-installation.tar.gz" --exlo
popd &>/dev/null

#END Deployment of post-installation hooks
##

#------------------------------------------------------------------------------#

# R1A03 -> R1A04
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_6 R1A03
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
