#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_prc_fix.sh
# Description:
#       A script to update the rules IMMFIND_RULE_EVENT before upgrade and reset the rule after upgrade.
# Usage:
#       Used during APG upgrade installation.
##
# Output:
#       None.
##
# Changelog:
# - Thu Oct 10 2019 - Nazeema Begum (XNAZBEG)
#   First version.


# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh
#set -x

apos_intro $0

IMMCFG_CMD="/usr/bin/immcfg"
IMMLIST_CMD="/usr/bin/immlist"
IMMFIND_RULE_EVENT="eventMatrixId=2,processControlId=1"

# _____________________
#|    _ _   _  .  _    |
#|   | ) ) (_| | | )   |
#|_____________________|
# Here begins the "main" function...

case "$1" in

  set)
        # setting dummy eventid
	apos_log "Setting the specificproblem to 9999 for $IMMFIND_RULE_EVENT ..."
	$IMMLIST_CMD $IMMFIND_RULE_EVENT &> /dev/null
	if [ $? -eq 0 ] ; then
        	kill_after_try 3 3 4 "$IMMCFG_CMD -a specificProblem=9999 $IMMFIND_RULE_EVENT"
		[ $? -ne 0 ] && apos_log "Failed to set specificproblem to 9999 for $IMMFIND_RULE_EVENT ..."
	else
        	apos_log '$IMMFIND_RULE_EVENT  not found '
	fi
   ;;

  reset)
   	# Resetting to old eventid
        apos_log "Resetting the specificproblem to 9030 for $IMMFIND_RULE_EVENT ..."
	$IMMLIST_CMD $IMMFIND_RULE_EVENT &> /dev/null
        if [ $? -eq 0 ] ; then
                kill_after_try 3 3 4 "$IMMCFG_CMD -a specificProblem=9030 $IMMFIND_RULE_EVENT"
                [ $? -ne 0 ] && apos_log "Failed to reset the specificProblem to 9030 for $IMMFIND_RULE_EVENT ..."
        else
                apos_log '$IMMFIND_RULE_EVENT  not found '
        fi
   ;;

   *)
     exit 1
   ;;
esac

apos_outro $0

exit 0
