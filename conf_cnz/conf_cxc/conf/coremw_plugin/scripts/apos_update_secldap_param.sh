#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_update_secldap_param.sh
# Description:
#       Set SEC ldap paramters in ldap_aa.conf file
# Note:
#       None.
##
# Usage:
#       apos_update_secldap_param.sh
##
# Output:
#       None.
##
# Changelog:
# - Mon 24 Feb 2020 - Swapnika Baradi ( xswapba )
#          Fix for the TR HY29027
# - Fri 27 Dec 2019 - Nazeema Begum ( xnazbeg )
#	   Fix for the TR HY20175
# - Thu 14 Feb 2019 - Nazeema Begum ( xnazbeg )
#          First Revision
##
. /opt/ap/apos/conf/apos_common.sh
apos_intro $0

SEC_LDAP_CONF="/storage/system/config/sec-apr9010539/ldap/etc/ldap_aa.conf"
SEC_CONFIG_FILE="/cluster/storage/clear/apos/sec_config_flag"

function update_ldap_config(){
        if [ -f ${SEC_CONFIG_FILE} ];then
                [ -f ${SEC_LDAP_CONF} ] || apos_abort "file \"${SEC_LDAP_CONF}\" not found"
                local ldap_network_timeout=$(grep "LDAP_NETWORK_TIMEOUT.*" ${SEC_CONFIG_FILE})
                local ldap_server_status_cache_timeout=$(grep "LDAP_SERVER_STATUS_CACHE_TIMEOUT.*" ${SEC_CONFIG_FILE})
                sed -i "s/LDAP_NETWORK_TIMEOUT=.*/${ldap_network_timeout}/g" ${SEC_LDAP_CONF} || apos_abort "failure while modifying LDAP_NETWORK_TIMEOUT parameter"
                sed -i "s/LDAP_SERVER_STATUS_CACHE_TIMEOUT=.*/${ldap_server_status_cache_timeout}/g" ${SEC_LDAP_CONF} || apos_abort "failure while modifying LDAP_SERVER_STATUS_CACHE_TIMEOUT parameter"
                rm -f $SEC_CONFIG_FILE 2> /dev/null
        fi
}

###MAIN####
update_ldap_config

apos_outro $0
exit $TRUE
