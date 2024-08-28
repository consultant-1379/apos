#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2014 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A01.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1A01.
# Note:
#	None.
##
# Changelog:
# - Wed Feb 11 2015 - Pratap Uppada(xpraupp)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# R1A01 -> R1A02
#------------------------------------------------------------------------------#

##
# BEGIN: Nothing to do
# END: Nothing to do
##

#------------------------------------------------------------------------------#

# R1A02 -> R1A03
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R1A02
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A02"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
