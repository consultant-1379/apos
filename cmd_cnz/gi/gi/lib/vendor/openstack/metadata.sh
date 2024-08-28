#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       metadata
# Description:
#	A script to fetch the metadata information in an openstack based data center.
#
##
# Usage:
#       call: metadata
##
# Changelog:
# - Tue Jan 23 2018 - Rajashekar Narla (xcsrajn)
# First version

#source of common_functions
. "/opt/ap/apos/bin/gi/lib/common/common_functions"
if [ $? -ne 0 ];then
  apos_abort "Failure while loading common_functions"
fi

META_ALLOWED_FETCH_METHOD="configdrive"

if [ $# -ne 0 ];then
  apos_abort "Invalid usage"
fi

for FETCH_METHOD_ITEM in "$META_ALLOWED_FETCH_METHOD";do
  /opt/ap/apos/bin/gi/lib/fetch_method/$FETCH_METHOD_ITEM.sh | grep "METADATA:" | awk -F'METADATA:' '{print $2}'
  if [ $? -eq 0 ];then
    exit 0
  fi
done


