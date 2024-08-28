#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_sec-conf.sh
# Description:
#       A script to configure the sec.conf file.
# Note:
#	None.
##
# Usage:
#       aposcfg_sec-conf.sh MUST be executed after the script that sets-up the
#	APOS' backed-up version of internal_filem_root.conf (i.e.
#	apos_fuseconf.sh)
##
# Changelog:
# - Tue Jan 24 2017 - Praveen Rathod (xprarat)
#       Adaptation to SEC 2.2
# - Wed Jan 08 2014 - Antonio Buonocunto (eanbuon)
#	New configuration approach for SEC 1.2
# - Mon Dec 23 2013 - Antonio Buonocunto (eanbuon)
#	Adaptation to SEC 1.2
# - Tue Oct 09 2012 - Antonio Buonocunto (eanbuon)
#	Move from WA to final solution
# - Mon Aug 06 2012 - Francesco Rainone (efrarai)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

# log script starting
apos_intro $0

SEC_DIR='/storage/system/config/sec-apr9010539/etc'
SEC_CONF="$SEC_DIR/sec.conf"

# A requirement for Offline Image Creation and that is why sec can not support creating
# directories under PSO area during installation.
# They can only be created during software startup
if [ ! -d $SEC_DIR ]; then
 mkdir -p $SEC_DIR
 [ $? -ne 0 ] && apos_abort "Failed to create directory:$SEC_DIR"
fi

# Apply permissions as per JIRA (CC-13042)
# directories as root:root 755
chown root:root $SEC_DIR || apos_abort "Failed to change owner and group"
chmod 755 $SEC_DIR || apos_abort "Failed to change permission for directory:$SEC_DIR"

SEC_CONF_TEMPLATE='/opt/ap/apos/conf/sec.conf'
[ ! -f ${SEC_CONF_TEMPLATE} ] && apos_abort "the file \"${SEC_CONF_TEMPLATE}\" doesn't exist"

FILEM_ROOT_FILE="$(apos_create_brf_folder config)/internal_filem_root.conf"
[ ! -r ${FILEM_ROOT_FILE} ] && apos_abort "the file \"${FILEM_ROOT_FILE}\" doesn't exist and/or isn't readable"

INTERNAL_ROOT=$(<${FILEM_ROOT_FILE})
[ ! -d ${INTERNAL_ROOT} ] && apos_abort "the directory \"${INTERNAL_ROOT}\" doesn't exist"

pushd '/opt/ap/apos/conf/' >/dev/null
./apos_deploy.sh --from $SEC_CONF_TEMPLATE --to $SEC_CONF
if [ $? -ne 0 ]; then
  apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
fi
popd &>/dev/null

# Alternative approach based on a SEARCH&REPLACE mechanism.
sed -i "s@SEC_USER_ROOT=.*\$@SEC_USER_ROOT=\"${INTERNAL_ROOT}\"@g" ${SEC_CONF}
[ $? -ne 0 ] && apos_abort "Failure while configuring SEC_USER_ROOT in \"${SEC_CONF}\""
# Configuration applied only on SEC >= 1.2
if grep -q "SEC_ENABLE_FILE_BASED_CERT_STORE" ${SEC_CONF}; then
  sed -i "s@SEC_ENABLE_FILE_BASED_CERT_STORE=.*\$@SEC_ENABLE_FILE_BASED_CERT_STORE=\"true\"@g" ${SEC_CONF}
  [ $? -ne 0 ] && apos_abort "Failure while configuring SEC_ENABLE_FILE_BASED_CERT_STORE in \"${SEC_CONF}\""
else
  apos_log "FILE BASE CERT STORE successfully configured!"
fi

# Apply permissions as per JIRA (CC-13042)
# files as root:root 640
chmod 640 $SEC_DIR/* || apos_abort "Failed to change permission for files under directory[$SEC_DIR]"

# log succesful script execution 
apos_outro $0

exit $TRUE
# End of file
