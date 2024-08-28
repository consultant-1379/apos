#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1D.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Thu Mar 23 2017 -Dharma Teja (xdhatej)
#       Fix included for TR:HV69962.
# - Thu Feb 16 2017 -Swapnika Baradi (xswapba)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
# Common variables

CFG_PATH="/opt/ap/apos/conf"
SRC="/opt/ap/apos/etc/deploy"

# BEGIN: Add swmgr command in libcli_extension_subshell.cfg file
 pushd $CFG_PATH &> /dev/null
 [ ! -x /opt/ap/apos/conf/aposcfg_libcli_extension_subshell.sh ] && apos_abort 1 '/opt/ap/apos/conf/aposcfg_libcli_extension_subshell.sh not found or not executable'
 ./aposcfg_libcli_extension_subshell.sh
 popd &>/dev/null
# END: Add swmgr command in libcli_extension_subshell.cfg file

CMD_HWTYPE='/opt/ap/apos/conf/apos_hwtype.sh'
HW_TYPE=$($CMD_HWTYPE)

# BEGIN: Fix for TR HV50333
if [[ "$HW_TYPE" == "GEP2"  || "$HW_TYPE" == "GEP1" ]]; then
	pushd $CFG_PATH &> /dev/null
 	apos_check_and_call $CFG_PATH apos_udevconf.sh 
 	popd &>/dev/null
fi

# END: Fix for TR HV50333

# BEGIN: Fix for lde-boot label
 pushd $CFG_PATH &> /dev/null
./apos_deploy.sh --from $SRC/usr/lib/lde/config-management/apos_grub-config --to /usr/lib/lde/config-management/apos_grub-config
if [ $? -ne 0 ]; then
  apos_abort  "failure while deploying \"apos_grub-config\" file"
fi
# Reload the apos_gub-config file to apply the changes
/usr/lib/lde/config-management/apos_grub-config config reload
if [ $? -ne 0 ]; then
  apos_abort  "Reload of  \"apos_grub-config\" file got failed"
fi
 popd &>/dev/null
# END: Fix for lde-boot label

# R1E -> R1F
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_6 R1A01
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

