#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A01.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version 
# Note:
#       None.
##
# Changelog:
# - 22 Mar 2019 - Neelam Kumar (xneelku)
#       First Draft (LDE Integration)
##


# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
#Common variables
CFG_PATH="/opt/ap/apos/conf"
SRC="/opt/ap/apos/etc/deploy"

# BEGIN: deploying apos_grub-config
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
# END: deploying apos_grub-config



# R1A01 -> R1A02
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_10 R1A02
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

