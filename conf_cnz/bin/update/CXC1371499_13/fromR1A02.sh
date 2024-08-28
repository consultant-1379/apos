#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Mon 30 Nov - Yeswanth Vankayala (xyesvan)
# Fri 04 Dec - Sowjanya Medak (xsowmed)
# Fri 18 Sep - Swapnika Baradi (xswapba)
#        First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"
LDE_CONFIG_MGMT='usr/lib/lde/config-management'
CLU_HOOKS_PATH='/cluster/hooks/'


# BEGIN: updating DNR hooks for GEP5 board replacement
pushd $CFG_PATH &>/dev/null
    ./apos_deploy.sh --from "$SRC/$CLU_HOOKS_PATH/after-booting-from-disk.tar.gz" --to "$CLU_HOOKS_PATH/after-booting-from-disk.tar.gz"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying after-booting-from-disk.tar.gz file"
    fi
popd &>/dev/null
# END: DNR hooks deploy

# TR HY76007 fix
apos_log  'deleting apos_nbi_security.sh in lde-iptables.service file..'
sed -i '/apos_nbi_security.sh/d' /usr/lib/systemd/system/lde-iptables.service || apos_log  'apos_nbi_security.sh delete failed...'
apos_log  'done'

apos_log  'reloading lde-iptables daemon..'
systemctl daemon-reload || apos_log  'lde-iptables reload failed'
apos_log  'done'

apos_log  'restarting iptables..'
systemctl restart lde-iptables.service || apos_log  'restart lde-iptables failed'
apos_log  'done'

pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null

# R1A02 -> R1A03
#-----------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_13 R1A03
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

