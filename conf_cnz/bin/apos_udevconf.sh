#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# apos_udevconf.sh
# A script to set the disk naming rules for APG.
##
# Changelog:
# - Thu Mar 17 2016 - Antonio Buonocunto (eanbuon)
#       New logic for udevadm settle
# - Fri Jun 21 2013 - Francesco Rainone (efrarai)
#	Added priority independence.
# - Mon Apr 29 2013 - Francesco Rainone (efrarai)
#	Moved from "cp" to "apos_deploy.sh"
# - Mon Jan 23 2012 - Francesco Rainone (efrarai)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Copy the correct board-dependent file.
# Format: <HW_TYPE>_<PRIO>-apos_disks.rules
CONF_DIR='/opt/ap/apos/conf'
SUFFIX='-apos_disks.rules'
APOS_HW_TYPE=$(${CONF_DIR}/apos_hwtype.sh)

if [ ! -z "$APOS_HW_TYPE"  ]; then
	SRC_FILE=$(find ${CONF_DIR} -name "${APOS_HW_TYPE}_*${SUFFIX}" -exec basename {} \;)
	DEST_FILE="${SRC_FILE#${APOS_HW_TYPE}_}"
	if [ -r "$SRC_FILE" ]; then
		${CONF_DIR}/apos_deploy.sh --from "${CONF_DIR}/${SRC_FILE}" \
			--to "/etc/udev/rules.d/$DEST_FILE"
		if [ $? -ne 0 ]; then
			apos_abort 'apos-made udev rules deployment failed'
		fi
		/sbin/udevadm control --reload-rules || apos_abort '"udevadm control" ended with errors'
		/sbin/udevadm trigger --subsystem-match="block" || apos_abort '"udevadm trigger" ended with errors'
		/sbin/udevadm settle --timeout=120
		if [ $? -ne 0 ];then
			apos_log 'udevadm settle ended with errors'
		fi
	else
		apos_abort "file $SRC_FILE not found or not readable"
	fi
else
	apos_abort "found unsupported hardware type"
fi

apos_outro
exit 0
# End of file
