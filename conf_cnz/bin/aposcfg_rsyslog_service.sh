#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_rsyslog_service.sh
# Description:
#       A script to update description of rsyslog.service file delivered
#       by LDE
##
# Changelog:
# - Tue Mar 29 2016 - PratapReddy Uppada (xpraupp)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

SERVICE_FILE='/usr/lib/systemd/system/rsyslog.service'
if [ ! -f "$SERVICE_FILE" ]; then
  apos_abort 1 "$SERVICE_FILE not found"
fi

HOOK='Description=System[[:space:]]+Logging[[:space:]]+Service'
NEWROW='Description=rsyslog daemon'
if ! grep -q "$NEWROW" $SERVICE_FILE; then
  sed -i -r "s/$HOOK/$NEWROW/g" $SERVICE_FILE || \
    apos_abort 1 "failure while updating Description of service($SERVICE_FILE) file"
fi

apos_outro $0
exit $TRUE
