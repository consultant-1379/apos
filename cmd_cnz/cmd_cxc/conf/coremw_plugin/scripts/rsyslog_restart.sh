#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2023 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      rsyslog_restart.sh
#
# Changelog:
# - Jul 31 2023 - Pravalika P (ZPRAPXX)
#    - TR IA51135 Fix 
##
##
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

  rsyslog_file="/etc/rsyslog.conf"

  apos_log 'Restarting the rsyslog service from campaign to activate enhanced audit and command logging '

  if [ -f $rsyslog_file ]; then
 
    cmd_output=$(cat $rsyslog_file | grep "time-change")
    validation=$(rsyslogd -N1)
    if [ $? -eq 0 ] && [ ! -z "$cmd_output" ]; then
      apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting rsyslog service'
    else
      apos_log 'Skipping the rsyslog restart, either due to rsyslog validation errors or enhanced audit rules not available'
    fi

  fi

apos_outro $0
exit $TRUE


