#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_store_secldap_param.sh
# Description:
#       Create a temporary file if SEC config contains contains
#       non default parameters
# Note:
#       None.
##
# Usage:
#       apos_store_secldap_param.sh
##
# Output:
#       None.
##
# Changelog:
# - Mon 24 Feb 2020 - Swapnika Baradi ( xswapba )
#          Fix for the TR HY29027
# - Fri 27 Dec 2019 - Nazeema Begum ( xnazbeg )
# 	   Fix for TR HY20175 
# - Thu 14 Feb 2019 - Nazeema Begum ( xnazbeg )
#          First Revision
##

SEC_LDAP_FILE="/opt/eric/sec-ldap-cxp9028981/etc/sm-ldap-connection.ini"
SEC_LDAP_CONF="/storage/system/config/sec-apr9010539/ldap/etc/ldap_aa.conf"
SEC_CONFIG_FILE="/cluster/storage/clear/apos/sec_config_flag"

function log() {
    /bin/logger -t apos_store_secldap_param.sh "$1"
}

function check_ldap_config(){
        if [ -f ${SEC_LDAP_FILE} ];then
                touch ${SEC_CONFIG_FILE}
        elif [ -f ${SEC_LDAP_CONF} ]; then
                    grep -e "LDAP_NETWORK_TIMEOUT=\|LDAP_SERVER_STATUS_CACHE_TIMEOUT=" ${SEC_LDAP_CONF} | grep -v '^ *#' >> ${SEC_CONFIG_FILE}
        else
                log "nothing to do with sec configuration file..."
        fi
}

###MAIN####
log "Started execution of script apos_store_secldap_param.sh..."
check_ldap_config
log "execution of script apos_store_secldap_param.sh done successfully..."

exit 0

