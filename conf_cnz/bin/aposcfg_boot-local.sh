#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_boot-local.sh
# Description:
#       A script to configure the /etc/init.d/boot.local file.
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
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Mon Mar 14 2011 - Francesco Rainone (efrarai)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

DEST="/etc/init.d/boot.local"
TOKEN="if [ -x /opt/ap/acs/bin/acs_nsfbiostimerecovery ]; then /opt/ap/acs/bin/acs_nsfbiostimerecovery; fi"
if [ -f "$DEST" ]; then
	if [ -z "`cat $DEST | grep \"$TOKEN\"`" ]; then
		echo "$TOKEN" >> $DEST
	fi
else
	echo "$TOKEN" > $DEST
fi

apos_outro $0
exit $TRUE

# End of file