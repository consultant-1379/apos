#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_rsh.sh
# Description:
#       A script to set the rsh daemon.
# Note:
#	None.
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Sat Jan 23 2016 - Antonio Buonocunto (eanbuon)
#       Systemd adaptation.
# - Thu Oct 25 2012 - Francesco Rainone (efrarai)
#	Added "only_from" configuration item handling.
# - Mon Oct 16 2012 - Gerardo Petti (egerpet)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Main

apos_servicemgmt enable apg-rsh.socket --start &>/dev/null || apos_abort 'failure while configuring rsh'

apos_outro $0
exit $TRUE

# End of file
