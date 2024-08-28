#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   apos_smartdisk.sh
##
# Description:
#   A script for configuring smartd daemon for system-disk monitoring.
##
# Changelog:
# - Mon Feb 27 2017 - Francesco Rainone (efrarai)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

APOS_DIR="${AP_HOME:-/opt/ap}/apos"
CONF_DIR="${APOS_DIR}/conf/"
SRC="${APOS_DIR}/etc/deploy/"
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
SMARTCTL_CMD=/usr/sbin/smartctl

pushd ${CONF_DIR} &>/dev/null || apos_abort "failure while entering ${CONF_DIR} directory"

[ ! -x "$SMARTCTL_CMD" ] && apos_abort "${SMARTCTL_CMD} not found or not executable"


# Handle smart in non-virtualized deployments only
if [ "$HW_TYPE" != 'VM' ]; then
  # Deployment of custom smartd-related files
  files_array=(
                'usr/lib/systemd/system/smartd.service'
                'etc/smartd.conf'
              )
  for file in "${files_array[@]}"; do
    ./apos_deploy.sh --from "${SRC}/${file}" --to "/${file}"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying ${file}"
    fi
  done

  # Enable smart on system disk
  system_disk=/dev/disk_boot
  SMART_AVAILABLE=$(${SMARTCTL_CMD} --info ${system_disk} 2>&1 | grep -Pq '^SMART support is:[[:space:]]+Available'; echo $?)
  if [ "$SMART_AVAILABLE" -eq $TRUE ]; then
    if [ ! -b ${system_disk} ]; then
      apos_abort "the expected block device ${system_disk} does not exist"
    fi
    ${SMARTCTL_CMD} --smart=on ${system_disk} || apos_abort "failure while enabling SMART on ${system_disk}"
  else
    apos_log "Skipping SMART enabling on device ${system_disk} ($(readlink ${system_disk}))"
    apos_log "output of \"${SMARTCTL_CMD} --info ${system_disk}\" below:"
    while read line; do
      apos_log "$line"
    done < <(${SMARTCTL_CMD} --info ${system_disk} 2>&1)
  fi

  # Enable and start the new daemon
  echo 'enabling and starting smartd daemon...' 
  apos_servicemgmt enable smartd.service --start &>/dev/null || apos_abort 'failure while enabling and starting smartd service'
  echo 'done'

  # Reloading the new daemon configuration (in the case the daemon was already started)
  echo 'reload smartd configuration...'
  apos_servicemgmt reload smartd.service --type=config &>/dev/null || apos_abort 'failure while reloading smartd configuration'
  echo 'done'
else
  # Disable and stop smartd service in virtualized deployments
  apos_log "Skipping SMART enabling (HW_TYPE=${HW_TYPE})"
  # Disable and stop the new daemon
  echo 'disabling and stopping smartd daemon...' 
  apos_servicemgmt disable smartd.service --stop &>/dev/null || apos_abort 'failure while disabling and stopping smartd service'
  echo 'done'
fi

popd &>/dev/null

apos_outro $0
exit $TRUE
