#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      gsnh_apg_maideninstall.sh
#
# Changelog:
# - Feb 25 2021 - Rajendra Prasad T (ZRJAAPR)
#    - Update ciphers and tlsversion during Maiden Installation
##
##

. /opt/ap/apos/conf/apos_common.sh
apos_intro $0

TRUE=$(true; echo $?)
FALSE=$(false; echo $?)
EXIT_SUCCESS=$TRUE # 0
EXIT_FAILURE=$FALSE # 1

CMD_IMMCFG='/usr/bin/immcfg'
CMD_AWK='usr/bin/awk'
CMD_GREP='usr/bin/grep'
CMD_IMMLIST='/usr/bin/immlist'

GSNHSECDN="asecGsnhConfigDataId=GSNH,acsSecurityMId=1"
CIPHER_STRING="ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384"
TLS_STRING="TLSv1.2"

cfgread_ciphers=$($CMD_IMMLIST -a enabledCiphersList asecGsnhConfigDataId=GSNH,acsSecurityMId=1 | cut -c 20-)
cfgread_tls=$($CMD_IMMLIST -a enabledTLSversion asecGsnhConfigDataId=GSNH,acsSecurityMId=1 | cut -c 19-)

if ([ "$cfgread_ciphers" == "<Empty>" ] && [ "$cfgread_tls" == "<Empty>" ]) || ([ "$cfgread_ciphers" == "" ] && [ "$cfgread_tls" == "" ]); then
        $(kill_after_try 2 1 1 $CMD_IMMCFG -a enabledCiphersList="$CIPHER_STRING" $GSNHSECDN 2>/dev/null)
	if [ $? -ne 0 ]; then
              apos_log "Failed to set enabledCiphersList"
        fi
	$CMD_IMMCFG -a enabledTLSversion="$TLS_STRING" $GSNHSECDN 2>/dev/null
	#$CMD_IMMCFG -a enabledTLSversion="$TLS_STRING" $GSNHSECDN
        if [ $? -ne 0 ]; then
              apos_log "Failed to set enabled version"
        fi
fi

apos_outro $0
