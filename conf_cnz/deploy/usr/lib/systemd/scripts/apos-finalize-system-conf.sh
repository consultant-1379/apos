#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos-finalize-system-conf.sh
# Description:
#       A script to finalize system configuration during first deployment
#       only in case of vAPG
# Note:
#       The present script is executed during the start/stop phase of the
#       apos-finalize-system-config.service
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Fri Mar 25 2016 - PratapReddy Uppada (xpraupp)
#     First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)

function finalize_configuration() {
  apos_log "finalizing APG initial configuration"
  if [ -x /opt/ap/apos/conf/apos_finalize_system_conf.sh ]; then
    /opt/ap/apos/conf/apos_finalize_system_conf.sh
    return $?
  else
    apos_abort 1 "apos_finalize_system_conf.sh not found or not executable"
  fi
  return $TRUE
}

case $1 in
  start)
    if [[ "$HW_TYPE" == 'VM' ]]; then
      if is_system_configuration_allowed; then
        finalize_configuration
        return_code=$?
        if [ $return_code -ne $TRUE ] ; then
          apos_abort "failure while finalizing APG initial configuration (return code: $return_code)" >&2
        fi
      fi
    fi
   	;;
  stop|restart|status)
    # At present it does nothing
    apos_log "nothing to do"
  ;;
  *)
    apos_abort "unsupported command $1"
  ;;
esac

apos_log "APG initial configuration finalization successfully completed"
exit $TRUE
