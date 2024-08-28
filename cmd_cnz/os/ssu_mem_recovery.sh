#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       ssu_mem_recovery.sh
# Description:
#       A script which will be invoked by SSU to check memory and restart the service consuming high memory beyond threshold.
#
# Note:
#       None.
##
# Usage:
#       ssu_mem_recovery.sh
##
# Output:
#       None.
##
# Changelog:
# - Fri Sep 17 2021 - Dharma Theja(xdhatej)
#       First version.
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Variables
THRESHOLD=195312

MEM_USAGE=$(top -b -n1 | grep rsyslog |awk '{print $6 }')

if [ $MEM_USAGE -gt $THRESHOLD ];then
    apos_log 'Restarting rsyslog service'
    systemctl restart rsyslog.service
    if [ $? == 0 ];then
        apos_log 'rsyslog service restart success'
    else
        apos_log 'rsyslog service restart fail'
    fi
fi

apos_outro $0
exit $TRUE
#EOF
