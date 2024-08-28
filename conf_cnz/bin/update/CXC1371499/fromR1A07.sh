#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A07.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1A06.
# Note:
#	None.
##
# Changelog:
# - Tue Jul 07 2015 - Pratap Reddy Uppada(XPRAUPP)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

SRC='/opt/ap/apos/etc/deploy'
CFG_PATH='/opt/ap/apos/conf'

#------------------------------------------------------------------------------#

# R1A06 --> R1A07
#------------------------------------------------------------------------------#

##
# BEGIN: Update of sshd in case of cache
pushd $CFG_PATH &> /dev/null
if [ "$CACHE_DURATION" != "0" ];then
 ./apos_deploy.sh --from "$SRC/etc/pam.d/sshd_cache" --to "/cluster/etc/pam.d/sshd"
  if [ "$?" != "0" ]; then
    apos_abort "Failure during the update of sshd"
  fi
fi
popd &>/dev/null
# END: Update of sshd in case of cache
##

#------------------------------------------------------------------------------#

# R1A07 -> <NEXT REVISION>
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R1A08
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A08"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
