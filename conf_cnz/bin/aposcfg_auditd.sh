#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_auditd.sh
# Description:
#       audit.rules file set up.
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
# - Tue Jan 26 2016 - Crescenzo Malvone (ecremal)
#	Removed the change of the file /etc/sysconfig/suditd since it's overwritten by deploy
# - Wed May 16 2012 - Francesco Rainone (efrarai)
#	Added handling of the /etc/audit/auditd.conf file.
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Wed Nov 16 2011 - Francesco Rainone (efrarai)
#	Changes to be update-compliant.
# - Thu Sep 08 2011 - Paolo Palmieri (epaopal)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Variables
FILE="/etc/audit/auditd.conf"
if [ -f "$FILE" ]; then
	# Set 'flush = NONE'
	sed -i '/^[[:space:]]*flush[[:space:]+]=/ s/=.*/= NONE/g' $FILE || apos_abort "failure while editing the $FILE file"
	
	# Set 'max_log_file = 50'
	sed -i '/^[[:space:]]*max_log_file[[:space:]+]=/ s/=.*/= 250/g' $FILE || apos_abort "failure while editing the $FILE file"
else
	apos_abort 1 "file \"$FILE\" not found"
fi


apos_outro $0
exit $TRUE

# End of file
