#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apg-clearchipwdog.sh
# Description:
#       A script to clear CHIPSET_WDOG_TIMEOUT_FOUND bit in RAM GPR Register 0.
# Note:
#       The present script is executed during the start phase of the 
#       apg-clearchipwdog.service
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Thu Jan 21 2016 - Antonio Nicoletti (eantnic) - Crescenzo Malvone (ecremal)
#       First version.
##

# Load the APOS common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# VARIABLES
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)

function chipwdog_status() {
	# Return codes are built after the following pattern:
	# 0 - service up and running
	# 1 - service dead, but /var/run/  pid  file exists
	# 2 - service dead, but /var/lock/ lock file exists
	# 3 - service not running (unused)
	# 4 - service status unknown :-(
	# 5--199 reserved (5--99 LSB, 100--149 distro, 150--199 appl.)

	local GPR=$(/usr/sbin/eri-ipmitool rgpr ram 0 2>/dev/null| /usr/bin/tail -n -1 | /usr/bin/tr -d '[:space:]')
	if [ -z "$GPR" ]; then
		apos_log "Not able to fetch RAM GPR 0 configuration"
		return 4
	fi
	local MASK='08000000'
	local DECRES=$(( 0x${GPR} & 0x${MASK} ))
	local HEXRES=$(/usr/bin/printf "%08x" "$DECRES")
	if [ "$HEXRES" == "$MASK" ]; then
		apos_log "CHIPSET_WDOG_TIMEOUT_FOUND bit is set in RAM GPR 0"
		return 0
	else
		return 3
	fi
}

function chipwdog_clear() {
	local MASK='08000000'
	apos_log "Clearing CHIPSET_WDOG_TIMEOUT_FOUND bit"
	local OUT=""
	if ! OUT=$(/usr/sbin/eri-ipmitool wgpr ram 0 "$MASK" '00000000' 2>&1); then
		apos_log "failure while clearing CHIPSET_WDOG_TIMEOUT_FOUND bit in RAM GPR 0"
		while read line; do
			apos_log "eri-ipmitool: $line"
		done < <(echo "$OUT")
		return $FALSE
	fi
	return $TRUE
}

if [ "$HW_TYPE" != "VM" ];then
	echo -n "Starting CHIPSET_WDOG_TIMEOUT_FOUND clearance service "
	chipwdog_status
	CHIPWDOG_S=$?
	if [ "$CHIPWDOG_S" -eq 0 ]; then
		if ! chipwdog_clear; then
			exit 1
		else
			chipwdog_status
			CHIPWDOG_S=$?
			if [ "$CHIPWDOG_S" -eq 3 ]; then
				apos_log "CHIPSET_WDOG_TIMEOUT_FOUND bit successfully cleared in RAM GPR 0"
			elif [ "$CHIPWDOG_S" -eq 0 ]; then
				apos_log "WARNING: CHIPSET_WDOG_TIMEOUT_FOUND bit still set after clearance attempt!"
			fi
    fi
	fi
fi

apos_outro $0
exit $TRUE
