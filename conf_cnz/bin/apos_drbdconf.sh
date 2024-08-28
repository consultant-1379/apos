#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_drbdconf.sh
# Description:
#       A script for the APOS installation in APG43L.
# Note:
#	None.
##
# Usage:
#	apos_drbdconf.sh
##
# Output:
#       None.
##
# Changelog:
# - Fri Aug 23 2013 - Malangsha Shaik (xmalsha)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

function configure(){
	echo -n 'Configuring apos-drbd.service: '
	CFG_PATH='/opt/ap/apos/conf'
	SERV_PATH='/opt/ap/apos/etc/deploy/usr/lib/systemd/system'
	SERV_FILE="$SERV_PATH/apos-drbd.service"
	SCRIPT_PATH='/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts'
	SCRIPT_FILE="$SCRIPT_PATH/apos-drbd.sh"
	SUPPORT_FILE="$SCRIPT_PATH/apg-drbd-meta-convert"

	[ ! -x $CFG_PATH/apos_deploy.sh ] && apos_abort 1 "\"$CFG_PATH/apos_deploy.sh\" not found or not executable"
	[ ! -f $SERV_FILE ] && apos_abort 1 "\"$SERV_FILE\" not found"
	[ ! -f $SCRIPT_FILE ] && apos_abort 1 "\"$SCRIPT_FILE\" not found"
	
  chmod 644 $SERV_FILE
	chmod 755 $SCRIPT_FILE

	$CFG_PATH/apos_deploy.sh --from $SERV_FILE --to /usr/lib/systemd/system/apos-drbd.service
	[ $? -ne $TRUE ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"

	$CFG_PATH/apos_deploy.sh --from $SCRIPT_FILE --to /usr/lib/systemd/scripts/apos-drbd.sh
	[ $? -ne $TRUE ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
	
	$CFG_PATH/apos_deploy.sh --from $SUPPORT_FILE --to /usr/lib/systemd/scripts/apg-drbd-meta-convert
	[ $? -ne $TRUE ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"

  apos_servicemgmt enable apos-drbd.service &>/dev/null
  [ $? -ne $TRUE ] && apos_abort 1 "Failure while enabling \"apos-drbd.service\""

	apos_servicemgmt start apos-drbd.service
  [ $? -ne $TRUE ] && apos_abort 1 "Failure while starting \"apos-drbd.service\""
	echo '...done'
}

configure

apos_outro $0
exit $TRUE
