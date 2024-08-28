#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_update.sh
# Description:
#       A script to handle the APOS_OSCONFBIN rpm update paths.
# Note:
#	None.
##
# Usage:
#	apos_update.sh <OLD_VERSION>
#
#	<OLD_VERSION> being the APOS_OSCONFBIN release (in the r-state format)
#	to upgrade from (e.g. R1B03).
##
# Output:
#       None.
##
# Changelog:
# - Wed Feb 11 2015 - Uppada Pratapreddy(xpraupp)
# Updated with CXC number approach to avoid issues if the
# upgrade from one relase to another
# - Mon Nov 12 2012 - Francesco Rainone (efrarai)
#	The script will not abort anymore in the case of an unsupported upgrade
#	path (to support downgrade/rollback scenarios).
# - Tue Sep 11 2012 - Francesco Rainone (efrarai)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
CFG_PATH="/opt/ap/apos/conf"
UPDATE_SCRIPTS_PATH="${CFG_PATH}/update"
[ ! -d ${CFG_PATH} ] && apos_abort "the folder $CFG_PATH cannot be found!"
[ ! -d ${UPDATE_SCRIPTS_PATH} ] && apos_abort "the folder $UPDATE_SCRIPTS_PATH cannot be found!"

# Parameter check (any uppercase string matching the R-State format)
[ $# -ne 2 ] && apos_abort "wrong number of parameter"
[[ ! ${2} =~ ^R[0-9]+[A-Z]{1}[0-9]*$ ]] && apos_abort "parameter in the wrong format: ${2}"

# Upgrade routines
OLD_APOS_CXC="${1}"
OLD_APOS_RELEASE="${2}"
PREFIX='from'
CXC_PATH="${UPDATE_SCRIPTS_PATH}/${OLD_APOS_CXC}"
[ ! -d ${CXC_PATH} ] && apos_abort "the folder $CXC_PATH cannot be found!"

pushd ${CXC_PATH} &>/dev/null
UPDATE_SCRIPT="./${PREFIX}${OLD_APOS_RELEASE}.sh"
if [ -f "${UPDATE_SCRIPT}" ]; then
	if [ -x "${UPDATE_SCRIPT}" ]; then
		${UPDATE_SCRIPT} || apos_abort "failure while executing ${UPDATE_SCRIPT}"
	else
		apos_abort "missing executing permissions to ${UPDATE_SCRIPT_PATH}/${UPDATE_SCRIPT}"
	fi
else
	apos_log "WARNING! Unsupported upgrade path: from ${OLD_APOS_RELEASE}"
fi

popd &>/dev/null
apos_outro $0
exit $TRUE

# End of file
