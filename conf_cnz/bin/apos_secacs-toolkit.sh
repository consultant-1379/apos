#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   apos_secacs-toolkit.sh
##
# Description:
#   A script implementing settings for sssd.conf.
##
# Note:
#   This script is intended to be executed by acs-agent script (that is launched
#   by the ACS FW upon any configuration change). It is meant to be a patch to
#   the SEC ACS framework (the patching is done by apos_secacs-config).
##
# Changelog:
# - Fri May 11 2018 - Pratap Reddy Uppada (xpraupp)
#   remove case_sensitive setting from this script as 
#   sec-ldap is handling via ldap_aa.conf file.
# - Mon Jan 29 2018 - Yeswanth Vankayala (xyesvan)
#   Modified case_sensitive from false to Preserving.
# - Tue Oct 17 2017 - Furquan Ullah (xfurull)
#   Fix for the TR HW33600
# - Wed Jul 26 2017 - Pratap Reddy Uppada (xpraupp)
#   Extending script execution to AP2 also
# - Mon Apr 24 2017 - Neelam Kumar (xneelku)
#   Impacts for case sensitive for LDAP user
# - Thu Dec 01 2016 - Alessio Cascone (ealocae)
#   Impacts to change the acs-service-module-order file permissions. 
# - Thu May 05 2016 - Antonio Buonocunto (eanbuon)
#   Small rework. 
# - Wen Apr 06 2016 - Alessio Cascone (ealocae)
#   Modified to use common functions.
# - Mon Jan 20 2016 - Maurizio Cecconi (teimcec)
#   First draft.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CMD_SED="/usr/bin/sed"
CMD_CHMOD="/usr/bin/chmod"
SSSD_CONF_FILE="/etc/sssd/sssd.conf"
CACHED_CREDS_DURATION=0
CACHED_CREDENTIAL_OPTION="false"
SEC_ACS_PSO_CLEAR_FOLDER='/cluster/storage/clear/sec-apr9010539/acs'
SEC_ACS_METHOD_ORDER_FILE='acs-service-module-order'

function reduce_log_level() {
  local NEWROW='debug_level = 1'
  if ! grep -q '^[[:space:]]*debug_level[[:space:]]*=[[:space:]]*' $SSSD_CONF_FILE; then
    apos_log "adding \"$NEWROW\" to $SSSD_CONF_FILE..."
    sed -i "/\[domain\/LdapAuthenticationMethod\]/a ${NEWROW}" $SSSD_CONF_FILE || \
      apos_abort "failure while adding \"$NEWROW\" to $SSSD_CONF_FILE file after LdapAuthenticationMethod"
    sed -i "/\[domain\/LocalAuthenticationMethod\]/a ${NEWROW}" $SSSD_CONF_FILE || \
      apos_abort "failure while adding \"$NEWROW\" to $SSSD_CONF_FILE file after LocalAuthenticationMethod"
    apos_log "done"
  else
    apos_log "\"debug_level\" entry already present. Re-setting it to \"$NEWROW\" in $SSSD_CONF_FILE..."
    sed -r -i "s/^[[:space:]]*debug_level[[:space:]]*=[[:space:]]*.*/${NEWROW}/g" $SSSD_CONF_FILE || \
      apos_abort "failure while re-setting \"$NEWROW\" in $SSSD_CONF_FILE file"
    apos_log "done"
  fi
}

function change_sssd_conf() {
  # Configure attribute offline_credentials_expiration to the value configured with cdadm
  $CMD_SED -i -r "/^[[:space:]]*\[pam\][[:space:]]*\$/,/^[[:space:]]*\[.*\][[:space:]]*\$/ s/^[[:space:]]*offline_credentials_expiration[[:space:]]+=[[:space:]]+.*/offline_credentials_expiration = $CACHED_CREDS_DURATION/g" $SSSD_CONF_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failure while configuring attribute offline_credentials_expiration"
  fi
 
	# Setting of debug_level parameter to 1
  reduce_log_level

  if [ $CACHED_CREDS_DURATION -gt 0 ];then
    # Cached credentials feature enabled
    CACHED_CREDENTIAL_OPTION="true"
  fi
  $CMD_SED -i -r "/^[[:space:]]*\[domain\/LdapAuthenticationMethod\][[:space:]]*\$/,/^[[:space:]]*\[.*\][[:space:]]*\$/ s/^[[:space:]]*cache_credentials[[:space:]]+=[[:space:]]+.*/cache_credentials = $CACHED_CREDENTIAL_OPTION/g" $SSSD_CONF_FILE
  if [ $? -ne 0 ];then
    apos_abort "Failure while configuring attribute cache_credentials for LDAP domain"
  fi
}

function change_permissions_on_order_file() {
  local ORDER_FILE_PATH="${SEC_ACS_PSO_CLEAR_FOLDER}/${SEC_ACS_METHOD_ORDER_FILE}"
  $CMD_CHMOD o+r $ORDER_FILE_PATH
  if [ $? -ne 0 ]; then
    # In case the permissions change operation fails, log only.
    # Let's avoid to abort the script execution because the file is under 
    # SEC-ACS control and, since the acs-agent script is executed also during
    # failovers, aborting here would likely lead to system outage.
    apos_log "ERROR: Failed to set read permissions to others for order file $ORDER_FILE_PATH."
  fi
}

### Main
# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)

# AP2 CASE, cached credintials are disabled
# So, this part should be skipped when ap_type is AP2
if [ "$AP_TYPE" == 'AP1' ]; then
  change_permissions_on_order_file
  CACHED_CREDS_DURATION=$(apos_get_cached_creds_duration)
  # Sanity check on CACHED_CREDS_DURATION
  if [ -z "$CACHED_CREDS_DURATION" ];then
    apos_abort "Failure while fetching cached credentials duration"
  fi
  change_sssd_conf
elif [ "$AP_TYPE" == 'AP2' ]; then 
  # Setting of debug_level parameter to 1
  reduce_log_level 
else
  apos_abort "Unsupported AP_TYPE:[ $AP_TYPE ] received"
fi

apos_outro $0
exit $TRUE

# End of file
