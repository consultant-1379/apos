#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   apos_sec-ldapconf.sh
# Description:
#   A script to disable LDAP user case sensitivity 
# Note:
#   None.
##
# Usage:
#      
##
# Changelog:
# - Fri May 11 2018 - Pratap Reddy (xpraupp)
#   Added logging messages and removed the 'case-insensitive-ldap' 
#   file creation as sec 2.7 is handling internally.
# - Wed Apr 18 2018 - Yeswanth Vankayala (xyesvan)
#   SEC 2.6 Adaptations
# - Fri Jul 21 2017 - Pratap Reddy Uppada (xpraupp)
#   First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

# log script starting
apos_intro $0

STORAGE_PATHS="/usr/share/pso/storage-paths"
STORAGE_CONFIG_PATH="$STORAGE_PATHS/config"
PSO_FOLDER=$( apos_check_and_cat $STORAGE_CONFIG_PATH)
SEC_PERSISTENT_ROOT="$PSO_FOLDER/sec-apr9010539"
LDAP_PERSISTENT_DIR=${SEC_PERSISTENT_ROOT}/ldap
LDAP_AA_CONF_FILE="$LDAP_PERSISTENT_DIR/etc/ldap_aa.conf"
APOS_LDAP_AA_CONF_FILE='/opt/ap/apos/conf/ldap_aa.conf'

# Verify if both owner and group or exist in the system 
/usr/bin/getent passwd sec-ldap &>/dev/null || apos_abort 1 "sec-ldap user doesn't exist"
/usr/bin/getent group sec-ldap &>/dev/null || apos_abort 1 "sec-ldap group doesn't exist"

###########################################
# SEC Ldap dual server Fallback issue fix:
###########################################
# Check the existance of ldap persistent directory.
# Code to create LDAP persistant directory and assigning
# the permissions are taken from below sec-ldap script
# i.e '/opt/eric/sec-ldap-cxp9028981/etc/oi.d/30defaults'
if [ ! -d "$LDAP_PERSISTENT_DIR/etc" ]; then
  # create the LDAP persistant directories if not present
  mkdir -p ${LDAP_PERSISTENT_DIR}/etc
  # change owner and group permissions for parent and child directories
  chown root:root ${LDAP_PERSISTENT_DIR}
  chown -R sec-ldap:sec-ldap ${LDAP_PERSISTENT_DIR}/etc
  # change the permissions for parent and  child directories
  chmod 755 ${LDAP_PERSISTENT_DIR}
  chmod 750 ${LDAP_PERSISTENT_DIR}/etc
else
  apos_log "LDAP persistant directroy [$LDAP_PERSISTENT_DIR/etc] exist, skipping the creation"
fi

# sec-ldap-oi reads the content of ldap_aa.conf file and sets the parameters during startup.
# In case of MI, sec-ldap starts first and then APOS will be installed.if ldap_aa.conf file 
# not found by the time sec-ldap starts, sec-ldap stores the default vlaues of all parameters. 
# Even though APOS deploy this file, parameters will not reflect in ldap db.To reflect these 
# parameters, sec-ldap restart required. In order to avoid sec-ldap restart this ldap_aa.conf 
# file creation is done from '001_ah_prologue_blade1'. Below code will be triggered only during 
# UP and restore scenarios.
if [ ! -f "$LDAP_AA_CONF_FILE" ]; then
  pushd '/opt/ap/apos/conf/' >/dev/null
  ./apos_deploy.sh --from "${APOS_LDAP_AA_CONF_FILE}" --to "${LDAP_AA_CONF_FILE}" || \
    apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code for ldap_aa.conf"
  popd &>/dev/null
else
  apos_log "file[$LDAP_AA_CONF_FILE]  already present, skiiping the deployment"
fi
 
apos_log "Done"

# log succesful script execution 
apos_outro $0
  
# END 
