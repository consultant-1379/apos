#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_login-defs.sh
# Description:
#       A script to configure /etc/login.defs file.
# Note:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Tue May 02 2023 - Pravalika P (zprapxx)
#   Changing umask to 0027 for CISCAT improvements feature
# - Thu Feb 11 2016 - Alessio Cascone (ealocae)
#   Added impacts for SLES12 adaptation (removal of UID_MIN and UID_MAX setting).
# - Mon Jan 25 2016 - Antonio Nicoletti (eantnic)
#   Remove handling of LASTLOG_ENAB for SLES12
# - Mon Oct 01 2012 - Francesco Rainone (efrarai)
#	Added UID_MIN and UID_MAX configuration.
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
GREP=$(which grep)
ECHO=$(which echo)
CMD_CHMOD="/usr/bin/chmod"


# Config files
LOGIN_FILE="/etc/login.defs"

# Default values
max_pswd_age=-1
min_pswd_age=0

# Main
if [ -f "$LOGIN_FILE" ]; then
	# Maximum Password Age
	line=$(cat $LOGIN_FILE | $GREP ^PASS_MAX_DAYS)
	$SED -i "s/$line/PASS_MAX_DAYS   $max_pswd_age/" $LOGIN_FILE

	# Minimum Password Age
	line=$(cat $LOGIN_FILE | $GREP ^PASS_MIN_DAYS)
	$SED -i "s/$line/PASS_MIN_DAYS   $min_pswd_age/" $LOGIN_FILE

	# Restriction for chfn command
	CHFN_LINE="#CHFN_RESTRICT          rwh"
	$SED -i "s@^CHFN_RESTRICT.*@$CHFN_LINE@g" $LOGIN_FILE || apos_abort 'failure while setting CHFN_RESTRICT in login.defs'	

        #As part of CIS-CAT improvements feature changing the umask to 027 instead of 022 
        line=$(cat $LOGIN_FILE | $GREP -v "^\#" | $GREP -w "UMASK")
        apos_log "The current umask value : $line" 
        $SED -i "s/$line/UMASK 027/g" $LOGIN_FILE
        if [ $? -ne 0 ];then
          apos_log "Failure while changing umask value"
        fi
        umask_value=$(cat $LOGIN_FILE | $GREP -v "^\#" | $GREP -w "UMASK")
        apos_log "Changed umask value : $umask_value"
     
else
	apos_abort 1 "file \"$LOGIN_FILE\" not found"
fi

# Create file /etc/hushlogins, adding the Bash shell as its value (to ask login to not print information about last login)
$ECHO -e "/bin/bash\n/bin/sh" > /etc/hushlogins
if [ $? -ne 0 ];then
  apos_abort "Failure while creating file /etc/hushlogins"
fi

$CMD_CHMOD 777 /etc/hushlogins
if [ $? -ne 0 ];then
  apos_abort "Failure while changing permission to file /etc/hushlogins"
fi

apos_outro $0
exit $TRUE

# End of file
