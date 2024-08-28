#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      gsnh_apg_upgrade.sh
#
# Changelog:
# - Feb 21 2022 - Siva Kumar Ganoz (XSIGANO)
#    - update cipher suite and protocol versions during upgrade to 4.3
##   - Add IP tables rules to allow traffic only on GSNH server port if GSNH server is running
##

. /opt/ap/apos/conf/apos_common.sh
apos_intro $0

TRUE=$(true; echo $?)
FALSE=$(false; echo $?)
EXIT_SUCCESS=$TRUE # 0
EXIT_FAILURE=$FALSE # 1

CMD_IMMCFG='/usr/bin/immcfg'
CMD_AWK='/usr/bin/awk'
CMD_GREP='/usr/bin/grep'
CMD_IMMLIST='/usr/bin/immlist'

STORAGE_CONFIG_PATH="/usr/share/pso/storage-paths/config"
CONFIG_PATH=$(< "$STORAGE_CONFIG_PATH")
HTTP_CONFIGURATION_FILE="$CONFIG_PATH/apos/http_config_file"
HTTP_STATUS_FROM_FILE=$(< "$CONFIG_PATH/apos/http_status")
GSNHSECDN="asecGsnhConfigDataId=GSNH,acsSecurityMId=1"
CIPHER_STRING="ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"
TLS_STRING="TLSv1.2 TLSv1.1 TLSv1"
ETC_APACHE2_LISTEN_CONF_PATH="/etc/apache2/listen.conf"
CMD_CLUSTER_CONF="/opt/ap/apos/bin/clusterconf/clusterconf"
SERVICEMGMT="/opt/ap/apos/bin/servicemgmt/servicemgmt"

cfgread_ciphers=$($CMD_IMMLIST -a enabledCiphersList asecGsnhConfigDataId=GSNH,acsSecurityMId=1 | cut -c 20-)
cfgread_tls=$($CMD_IMMLIST -a enabledTLSversion asecGsnhConfigDataId=GSNH,acsSecurityMId=1 | cut -c 19-)

function reload_IPtables_rules()
{
    $CMD_CLUSTER_CONF mgmt --cluster --verify > /dev/null
    if [ $? -ne 0 ]; then
	    apos_log "Failed to verify cluster conf"
    else
       apos_log "sleep(3): allow verify to settle down"
       sleep 3
       $CMD_CLUSTER_CONF mgmt --cluster --reload > /dev/null
       if [ $? -ne 0 ]; then
	      apos_log "Failed to verify cluster reload"
       fi
       $CMD_CLUSTER_CONF mgmt --cluster --commit > /dev/null
       if [ $? -ne 0 ]; then
	      apos_log "Failed to verify cluster commit"
       fi
       $SERVICEMGMT restart lde-iptables.service
       if [ $? -ne 0 ]; then
	     apos_log "Failed to restart iptables service"
       fi
   fi

}

function add_IPtables_rule()
{
    local server_address_port="$(grep "^\s*Listen\s*" "$ETC_APACHE2_LISTEN_CONF_PATH" | awk '{ $1=""; print $0 }' | sed -e 's/^ *//' -e 's/ *$//')"
    local server_address="$(echo "$server_address_port" | awk -F':' '{ print $1 }' | sed -e 's/^ *//' -e 's/ *$//')"
    local mip_interface=$($CMD_CLUSTER_CONF mip -D | $CMD_GREP  -E $server_address | $CMD_AWK '{print $5}'| cut -d : -f 1)
    local interface_name=$($CMD_CLUSTER_CONF mip -D | $CMD_GREP  -E $server_address | $CMD_AWK '{print $4}')
    local interface_type=$($CMD_CLUSTER_CONF mip -D | $CMD_GREP  -E $server_address | $CMD_AWK '{print $6}')

    if [ "$interface_name" != "nbi" ] && [ "$interface_type" != "public" ]; then
        local server_port="$(echo "$server_address_port" | awk -F':' '{ $1=""; print $0 }' | sed -e 's/^ *//' -e 's/ *$//')"
        NoOfRule=`${CMD_CLUSTER_CONF} iptables -D |grep "[[:space:]]$mip_interface" | grep -w "$server_port" | wc -l`

        #If IP table is present, do not apply any IPtable rules
        if [ "$NoOfRule" -eq 0 ]; then
       	   $( ${CMD_CLUSTER_CONF} iptables --m_add all -A INPUT -p tcp --dport $server_port -i $mip_interface -j ACCEPT > /dev/null)
           if [ $? -ne 0 ]; then
              apos_log "addRule: IPv4 iptable rule to acceppt add failed"
           fi

           $( ${CMD_CLUSTER_CONF} iptables --m_add all -A INPUT -i $mip_interface -j DROP > /dev/null)
           if [ $? -ne 0 ]; then
              apos_log "addRule: IPv4 iptable rule to drop add failed"
           fi

           reload_IPtables_rules
       else
          apos_log "addRule: IPtables rule already present no action is needed"
       fi
    else
       apos_log "addRule: Web server is listening on PUBLIC interface, no IPtables rule is added"
    fi

}


if ( [ "$cfgread_ciphers" == "<Empty>" ] && [ "$cfgread_tls" == "<Empty>" ] ) || ( [ "$cfgread_ciphers" == "" ] && [ "$cfgread_tls" == "" ] )  ; then
	$(kill_after_try 2 1 1 $CMD_IMMCFG -a enabledCiphersList="$CIPHER_STRING" $GSNHSECDN 2>/dev/null)
        if [ $? -ne 0 ]; then
              apos_log "Failed to set enabled ciphers"
        fi
	$CMD_IMMCFG -a enabledTLSversion="$TLS_STRING" $GSNHSECDN 2>/dev/null
        if [ $? -ne 0 ]; then
              apos_log "Failed to set protocol version"
        fi
fi

if [ $HTTP_STATUS_FROM_FILE == "start" ]; then
    add_IPtables_rule
else
    apos_log "webserver not running"
fi

apos_outro $0
