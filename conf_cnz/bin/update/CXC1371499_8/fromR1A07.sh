#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A07.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue 27 Feb 2018 - Avinash Gundlapally (xavigun)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

CFG_PATH='/opt/ap/apos/conf'
SRC='/opt/ap/apos/etc/deploy'

# R1A07 -> R1A08
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_8 R1A08
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0

exit $TRUE
# End of file

