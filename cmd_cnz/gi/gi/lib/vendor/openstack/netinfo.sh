#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       netinfo
# Description:
#	A script for fetch the network information properties in an openstack based data center.
#
##
# Usage:
#       call: netinfo.sh
##
# Changelog:
# - Thu Nov 04 2016 - Antonio Buonocunto (eanbuon)
# First version

#source of common_functions
. "/opt/ap/apos/bin/gi/lib/common/common_functions"
if [ $? -ne 0 ];then
  apos_abort "Failure while loading common_functions"
fi
NETINFO_SUBCOMMAND=""
NETINFO_ALLOWED_FETCH_METHOD="configdrive"



if [ $# -eq 1 ];then
  NETINFO_SUBCOMMAND="$1"
elif [ $# -ne 0 ];then
  apos_abort "Invalid usage"
fi

for FETCH_METHOD_ITEM in "$NETINFO_ALLOWED_FETCH_METHOD";do
  if [ -z $NETINFO_SUBCOMMAND ];then
    /opt/ap/apos/bin/gi/lib/fetch_method/$FETCH_METHOD_ITEM.sh | grep "NETINFO:" | awk -F'NETINFO:' '{print $2}'
    if [ $? -eq 0 ];then
      exit 0
    fi
  else
    for NETWORK_FOUND_ITEM in $(/opt/ap/apos/bin/gi/lib/fetch_method/$FETCH_METHOD_ITEM.sh | grep "NETINFO:" | awk -F'NETINFO:' '{print $2}');do
      NETWORK_FOUND_ITEM_NAME="$(echo $NETWORK_FOUND_ITEM|awk -F';' '{print $1}')"
      if [ "$NETWORK_FOUND_ITEM_NAME" = "$NETINFO_SUBCOMMAND" ];then
        echo $NETWORK_FOUND_ITEM
        if [ $? -eq 0 ];then
          exit 0
        fi
      fi
    done
  fi
done

