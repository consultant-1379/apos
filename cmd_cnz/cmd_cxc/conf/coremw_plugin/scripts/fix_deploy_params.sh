#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fix_deploy_params.sh
# Description:
#       A script to modify depoly configurations
#
# Note:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Mon Jul 15 2019 - xpraupp
#       First version.
##

# Load apos common functions
. /opt/ap/apos/conf/apos_common.sh 

function move_factoryparam() {
  apos_log "--- move_factoryparam() begin"

  local STORAGE_CONFIG='/cluster/storage/system/config'
  local LDEWS_OS_CONFIG='config/initial/ldews.os'
  local LDE_CSM_TEPLATES_DIR='lde/csm/templates'
  local LDE_CSM_FINALIZED_DIR='lde/csm/finalized'
  local CMW_CSM_CONFIG_BASE_DIR='coremw/csm/config-base/CSM'

  # templates DIR:  /cluster/storage/system/config/lde/csm/templates/config/initial/ldews.os/
  local TEPLATES_DIR="$STORAGE_CONFIG/$LDE_CSM_TEPLATES_DIR/$LDEWS_OS_CONFIG"

  # Finalized DIR:  /cluster/storage/system/config/lde/csm/finalized/config/initial/ldews.os/
  local FINALIZED_DIR="$STORAGE_CONFIG/$LDE_CSM_FINALIZED_DIR/$LDEWS_OS_CONFIG"

  # Config-base DIR: /cluster/storage/system/config/coremw/csm/config-base/CSM/config/initial/ldews.os
  local CMW_CONFIG_BASE_DIR="$STORAGE_CONFIG/$CMW_CSM_CONFIG_BASE_DIR/$LDEWS_OS_CONFIG"

  for DIR in $CMW_CONFIG_BASE_DIR $TEPLATES_DIR $FINALIZED_DIR
  do
    if [ -d "$DIR" ]; then
      if [ -f "$DIR/factoryparam.conf" ]; then
        # Re-name the factoryparam.conf to factoryparam_applied.conf in all DIR's
        apos_log "Moving the factoryparam.conf file in $DIR to factoryparam_applied.conf..."
        /usr/bin/mv $DIR/factoryparam.conf $DIR/factoryparam_applied.conf || \
          apos_abort "Failed to move the factoryparam.conf file in $DIR"
         apos_log " done"
      else
        apos_log "INFO: factoryparam.conf file not found."
      fi
    else
      apos_log "INFO: $DIR does not exist in the system"
    fi
  done

  apos_log "--- move_factoryparam() end"
}

#### M A I N #####

apos_intro "$0"

move_factoryparam

apos_outro "$0"

exit $TRUE

#END
