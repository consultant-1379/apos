#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      apos_http_sec_impact.sh
#
# Changelog:
# - Feb 06 2020 - Gnaneswara Seshu (ZBHEGNA)
#    - updated TRUST_CATEGORY_ID value
##
##

. /opt/ap/apos/conf/apos_common.sh
apos_intro $0

TRUE=$(true; echo $?)
FALSE=$(false; echo $?)
EXIT_SUCCESS=$TRUE # 0
EXIT_FAILURE=$FALSE # 1

CMD_IMMCFG='/usr/bin/immcfg'

STORAGE_CONFIG_PATH="/usr/share/pso/storage-paths/config"
CONFIG_PATH=$(< "$STORAGE_CONFIG_PATH")
HTTP_CONFIGURATION_FILE="$CONFIG_PATH/apos/http_config_file"
HTTP_STATUS_FROM_FILE=$(< "$CONFIG_PATH/apos/http_status")
GSNHSECDN="asecGsnhConfigDataId=GSNH,acsSecurityMId=1"

HTTPS_STATUS=""
NODE_CREDENTIAL_ID=""
TRUST_CATEGORY_ID=""
HTTPS_NODE_CREDENTIAL_FILENAME=""
HTTPS_TRUSTCATEGORY_FILENAME=""
HTTPS_PRIVATE_KEY_FILE=""


if [ $HTTP_STATUS_FROM_FILE == "start" ]; then
	HTTPS_STATUS=$(< "$CONFIG_PATH/apos/https_status")
	NODE_CREDENTIAL_ID=$(< "$CONFIG_PATH/apos/https_cert_id")
	TRUST_CATEGORY_ID=$(< "$CONFIG_PATH/apos/https_cert_id")

	if [[ -n "$NODE_CREDENTIAL_ID" && -n "$TRUST_CATEGORY_ID" ]];then
	       apos_log "updating gsnh DN with CId=$NODE_CREDENTIAL_ID and TId=$TRUST_CATEGORY_ID"
               $CMD_IMMCFG -a nodeCredentialId="$NODE_CREDENTIAL_ID" $GSNHSECDN 2>/dev/null
               rCode=$?
               if [ $rCode == $EXIT_FAILURE ]; then
                  apos_log "Failed to store nodecredential ID in IMM "
               fi
               $CMD_IMMCFG -a trustCategoryId="$TRUST_CATEGORY_ID" $GSNHSECDN 2>/dev/null
               rCode=$?
               if [ $rCode == $EXIT_FAILURE ]; then
                  apos_log "Failed to store Trust Category ID in IMM "
               fi
	       if [ "$HTTPS_STATUS" == "on" ]; then
	      	  apos_log "updating gsnh DN with security enabled"
                  $CMD_IMMCFG -a security=enabled $GSNHSECDN 2>/dev/null
		  if [ $rCode == $EXIT_FAILURE ]; then
                      apos_log "Failed to store security enable in IMM "
                  fi	
               fi		
        else
           apos_log "Both node credential and trustcategory or any one  not installed"
	fi
else
apos_log "webserver not running"
fi
apos_outro $0
