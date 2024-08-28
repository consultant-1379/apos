#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_syslog-conf.sh
# Description:
#       A script to set up the syslog.conf file.
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
# - Tue Aug 13 2013 - Francesco Rainone (efrarai)
#	Changes to disable syslog plugin.
# - Wed Feb 01 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Wed Nov 16 2011 - Francesco Rainone (efrarai)
#	Changes to be update-compliant.
# - Thu Sep 08 2011 - Paolo Palmieri (epaopal)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
FILE="/etc/audisp/plugins.d/syslog.conf"
STATEMENT=""
NEW_ROW=""

# Main

# Row search and replacement
if [ -f "$FILE" ]; then
	STATEMENT="active = "
	NEW_ROW="active = yes"
	if [ "`cat $FILE | grep \"^$STATEMENT.*\"`" ]; then	
		sed -i "s@^$STATEMENT.*@$NEW_ROW@g" "$FILE"
	else	
		echo -e "$NEW_ROW" >> "$FILE"
	fi
else
        apos_abort 1 "file \"$FILE\" not found"
fi

apos_outro $0
exit $TRUE

# End of file
