#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_guest.sh
# Description:
#       A script to customize the vmware tools service unit file.
# Note:
#	The script is called by apos_conf.sh and executed - only for vAPG - 
#       during the installation phase
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Mon Jan 23 2017 - Franco D'Ambrosio (efradam)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
CFG_PATH="/opt/ap/apos/conf"

function update_vmtoolsd_service_unit() {
  local HOOK='\[Service\]'
  local NEWROW='Restart=always'
  local SERVICE_DIR='/usr/lib/systemd/system'
  local SERVICE_FILE='vmtoolsd.service'
  local VMWARE_TOOLS='open-vm-tools'

  pushd $SERVICE_DIR > /dev/null 2>&1

  if [ ! -f "$SERVICE_FILE" ]; then
    apos_abort 1 "file $SERVICE_FILE not found"
  fi

  if ! grep -q "$NEWROW" $SERVICE_FILE; then
    sed -i -r "/$HOOK/a$NEWROW" $SERVICE_FILE || \
    apos_abort 1 "failure while updating $SERVICE_FILE file"
  fi

  apos_log 'enabling vmtoolsd daemon...'
  apos_servicemgmt enable vmtoolsd.service &>/dev/null || apos_abort 'failure while enabling vmtoolsd service'

  apos_log 'restarting vmtoolsd daemon...'
  apos_servicemgmt restart vmtoolsd.service &>/dev/null || apos_abort 'failure while restarting vmtoolsd service'

  popd > /dev/null 2>&1
  return $TRUE
}

update_vmtoolsd_service_unit

apos_outro $0
exit $TRUE
