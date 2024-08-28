#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      apos_http_sec_impact.sh
#
# Description:
#       This script is used to perform clean up actions for GSNH apache during upgrade to APG43L3.8
#
# Changelog:
# - Feb 05 2020 - Gnaneswara Seshu (ZBHEGNA)
#    - First version
##

. /opt/ap/apos/conf/apos_common.sh
apos_intro $0

#Commands
CMD_RM='/usr/bin/rm'
###

STORAGE_CONFIG_PATH="/usr/share/pso/storage-paths/config"
CONFIG_PATH=$(< "$STORAGE_CONFIG_PATH")
NODE_CREDENTIAL_ID_FILE="$CONFIG_PATH/apos/https_cert_id"
TRUST_CATEGORY_ID_FILE="$CONFIG_PATH/apos/https_tcerts_id"
CERTM_PRIVATE_PATH="$CONFIG_PATH/apos/sec/var/db/"


function deletefiles(){
  local file="$1"
  if [[ -f $file || -d $file ]];then
    apos_log "Deleting $file "
    $CMD_RM -rf "$file"
    rcode=$?
    [[ $rcode -ne 0 ]] && apos_log "unable to remove $file"
  fi
}

#Deleting files that are not used by GSNH from 3.8 onwards
filearray="$NODE_CREDENTIAL_ID_FILE $TRUST_CATEGORY_ID_FILE $CERTM_PRIVATE_PATH"
for file in ${filearray[@]}
do
  deletefiles "$file"
done

apos_outro $0

