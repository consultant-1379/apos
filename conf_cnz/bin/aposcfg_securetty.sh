#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_securetty.sh
# Description:
#       A script to configure /etc/securetty file.
# Note:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Thu Jan 21 2016 - Gianluca Santoro (eginsan)
#	Remove unused variables and back thicks.
# - Tue May 08 2012 - Fabio Ronca (efabron)
#	Configuration scripts rework.
# - Tue Jan 31 2012 - Satya Deepthi Gopisetti (xsatdee)
#	First version.
##
 
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common commands
SED=$(which sed)

# Config files
TTY_FILE="/etc/securetty"

# Main
if [ -f "$TTY_FILE" ]; then
	# To remove unneeded terminals (all TTYs except TTYS0)
	if [ $(cat $TTY_FILE | grep -c "^tty[1-9]") -gt 0 ]
	then
        	$SED -i "/^tty[1-9]/ s/^/#/g" $TTY_FILE
	fi
else
	apos_abort 1 "file \"$TTY_FILE\" not found"
fi

apos_outro $0
exit $TRUE

# End of file
