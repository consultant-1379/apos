#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   apos_failoverd_conf.sh
##
# Description:
#   A script to override LDE failoverd scripts with APG scripts
##
# Changelog:
# - Fri Jun 09 2017 - Pratap Reddy Uppada (xpraupp)
#   First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

APOS_DIR="${AP_HOME:-/opt/ap}/apos"
CONF_DIR="${APOS_DIR}/conf/"
SRC="${APOS_DIR}/etc/deploy"
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
BASEDIR='/usr/lib/lde/failoverd-helpers'
BASEFILE="${BASEDIR}/apg-defaults"
ACTIONS_ARRAY=(
                'disk-health'
                'split-brain-input'
              )

function get_symlink_file() {
  local ACTION="$1"
  local PRIORITY='10'
  # symbolic link file format for new failoverd framework:
  local LINK_NAME="${PRIORITY}-apg-${ACTION}"
  echo "$LINK_NAME"
}

pushd ${CONF_DIR} &>/dev/null || apos_abort "failure while entering ${CONF_DIR} directory"

# Handle new failoverd framework in non-virtualized deployments only
if [ "$HW_TYPE" != 'VM' ]; then
  # Deployment of custom failoverd-related files
  ./apos_deploy.sh --from "${SRC}/${BASEFILE}" --to "${BASEFILE}"
  if [ $? -ne $TRUE ]; then
    apos_abort "failure while deploying ${BASEFILE}"
  fi

  for OP in ${ACTIONS_ARRAY[@]}; do
    SYMLINK_FILE=$(get_symlink_file $OP)
    pushd ${BASEDIR}/$OP/ &>/dev/null || apos_abort "failure while entering ${BASEDIR}/$OP directory"
    # Creating symlink for disk-health and split-brain-input actions
    ln -s "../apg-defaults" "${SYMLINK_FILE}"
    if [ $? -ne 0 ]; then
      apos_abort 1 "failed to create symlink ${SYMLINK_FILE}"
    fi
    popd &>/dev/null
  done
fi
popd &>/dev/null

apos_outro $0
exit $TRUE

