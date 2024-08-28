#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_motd.sh
# Description:
#       A script to configure /cluster/etc/motd file.
# Note:
#	None.
##
# Output:
#       None.
##
# Changelog:
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
WELCOME_MSG_FILE="/cluster/etc/motd"

# Main
# Default values
welcome_message=""

if [ -f "$WELCOME_MSG_FILE" ]; then
	# Welcome Message for SSH and Telnet
	echo $welcome_message > $WELCOME_MSG_FILE
else
	apos_abort 1 "file \"$WELCOME_MSG_FILE\" not found"
fi

apos_outro $0
exit $TRUE

# End of file
