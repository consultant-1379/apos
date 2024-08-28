#!/bin/bash
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apg-auditd.sh
# Description:
#       A script to start the auditing subsystem.
# Note:
#       Auditd daemon providing core auditing services
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Thu Jan 22 2016 - Antonio Nicoletti (eantnic) - Crescenzo Malvone (ecremal)
#       First version.
##

# Check for missing binaries (stale symlinks should not happen)
AUDITD_BIN=/sbin/auditd
AUDITD_CONFIG=/etc/sysconfig/auditd

if [ ! -x $AUDITD_BIN ]; then
	echo -n "$AUDITD_BIN not existing"
	exit 5; 
fi

# Check for existence of needed config file and read it
if [ ! -r $AUDITD_CONFIG ]; then
	echo -n "$AUDITD_CONFIG not existing"
	exit 5; 
fi

# Read config	
. $AUDITD_CONFIG

# Return values acc. to LSB for all commands but status:
# 0	  - success
# 1       - generic or unspecified error
# 2       - invalid or excess argument(s)
# 3       - unimplemented feature (e.g. "reload")
# 4       - user had insufficient privileges
# 5       - program is not installed
# 6       - program is not configured
# 7       - program is not running
# 8--199  - reserved (8--99 LSB, 100--149 distrib, 150--199 appl)
# 
# Note that starting an already running service, stopping
# or restarting a not-running service as well as the restart
# with force-reload (in case signaling is not supported) are
# considered a success.

case "$1" in
    start)
	echo -n "Starting auditd "
	if [ "$AUDITD_DISABLE_CONTEXTS" == "yes" ] ; then 
		EXTRAOPTIONS="$EXTRAOPTIONS -s disable"
    fi

	## Start daemon with startproc(8). If this fails
	## the return value is set appropriately by startproc.
	/bin/bash -c "$AUDITD_BIN $EXTRAOPTIONS"
	test -f /etc/audit/audit.rules && /sbin/auditctl -R /etc/audit/audit.rules >/dev/null
	;;
    stop)
	echo -n "Shutting down auditd "
	## Stop daemon with monitord_killproc.	
	##$monitord_killproc

	# Remove watches so shutdown works cleanly
	if test "`echo $AUDITD_CLEAN_STOP | tr 'NO' 'no'`" != "no" ; then
		/sbin/auditctl -D >/dev/null
	fi
	;;
 
    *)
	echo "Usage: $0 {start|stop}"
	exit 1
	;;
esac
