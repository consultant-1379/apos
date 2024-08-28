#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       uuid
# Description:
#	A script for fetch the VM uuid in an openstack based data center.
#
##
# Usage:
#       call: uuid
##
# Changelog:
# - Thu Nov 04 2016 - Antonio Buonocunto (eanbuon)
# First version

#source of common_functions
. "/opt/ap/apos/bin/gi/lib/common/common_functions"
if [ $? -ne 0 ];then
  apos_abort "Failure while loading common_functions"
fi

UUID_ALLOWED_FETCH_METHOD="configdrive"

if [ $# -ne 0 ];then
  apos_abort "Invalid usage"
fi

for FETCH_METHOD_ITEM in "$UUID_ALLOWED_FETCH_METHOD";do
  /opt/ap/apos/bin/gi/lib/fetch_method/$FETCH_METHOD_ITEM.sh | grep "UUID:" | awk -F'UUID:' '{print $2}'
  if [ $? -eq 0 ];then
    exit 0
  fi
done


