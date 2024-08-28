#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A07.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version for PRCBOOT issue
# Note:
#	None.
##
# Changelog:
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Restart the VSFTPD APIO_1 and APIO_2 sockets
/usr/bin/systemctl restart apg-vsftpd-APIO_1.socket &>/dev/null || apos_abort "failure while restarting apg-vsftpd-APIO_1 socket"
/usr/bin/systemctl restart apg-vsftpd-APIO_2.socket &>/dev/null || apos_abort "failure while restarting apg-vsftpd-APIO_2 socket"

# R1A07 -> R1A08
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_9 R1A08
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
