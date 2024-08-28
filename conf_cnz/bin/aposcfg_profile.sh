#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_profile.sh
# Description:
#       A script to configure /etc/profile file.
# Note:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Fri Fre 12 2016 - Alfonso Attanasi (ealfatt) - Fabio Ronca (efabron)
#	CTRL-C handling.
# - Tue May 08 2012 - Fabio Ronca (efabron)
#	Configuration scripts rework.
# - Tue Jan 31 2012 - Satya Deepthi Gopisetti (xsatdee)
#	First version.
##
 
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
TRUE=$( true; echo $? )
FALSE=$( false; echo $? )

# Common commands
SED=`which sed`
GREP=`which grep`
TOUCH=`which touch`
CHMOD=`which chmod`

# Config files
INACTIVITY_TIMER_FILE="/etc/profile"

# Default values
inactivity_timer=1800

# Inactivity Timer 
timeout="TMOUT=$inactivity_timer"
firstLine="if test -f \/proc\/mounts \; then"
blockToAdd="function exit_func() {\n  exit 1\n}\ntrap exit_func SIGINT SIGTERM SIGHUP\n"

# Main
if [ -f "$INACTIVITY_TIMER_FILE" ]; then
	if [ $(cat $INACTIVITY_TIMER_FILE | $GREP -c "function exit_func") -lt 1 ]; then
		$SED -i "/$firstLine/i $blockToAdd" $INACTIVITY_TIMER_FILE
		if [ $? -ne 0 ]; then
			apos_abort 1 "CTRL-C disabling failed in \"$INACTIVITY_TIMER_FILE\""
		fi
	fi	
	if [ $(cat $INACTIVITY_TIMER_FILE | $GREP -c "$timeout") != 1 ]
	then
		$SED -i "/TMOUT/ s/^/#/g" $INACTIVITY_TIMER_FILE
		$SED -i "/End/ i$timeout" $INACTIVITY_TIMER_FILE
	fi
else
	apos_abort 1 "file \"$INACTIVITY_TIMER_FILE\" not found"
fi

apos_outro $0
exit $TRUE

# End of file
