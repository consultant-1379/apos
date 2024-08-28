#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       properties
# Description:
#	A script for fetch the deployment properties in a simulated environment.
#
##
# Usage:
#       call: properties.sh
##
# Changelog:
# - Thu Nov 04 2016 - Antonio Buonocunto (eanbuon)
# First version

#source of common_functions
. "$(dirname $0)/../../common/common_functions"
if [ $? -ne 0 ];then
  apos_abort "Failure while loading common_functions"
fi
PROPERTIES_SUBCOMMAND=""
PROPERTIES_ALLOWED_FETCH_METHOD="simuconfigdrive"

if [ $# -eq 1 ];then
  PROPERTIES_SUBCOMMAND="$1"
elif [ $# -ne 0 ];then
  apos_abort "Invalid usage"
fi

for FETCH_METHOD_ITEM in "$PROPERTIES_ALLOWED_FETCH_METHOD";do
  if [ -z $PROPERTIES_SUBCOMMAND ];then
    $(dirname $0)/../../fetch_method/$FETCH_METHOD_ITEM.sh | grep "PROPERTIES:" | awk -F'PROPERTIES:' '{print $2}'
    if [ $? -eq 0 ];then
      exit 0
    fi
  else
    for PROPERTIES_FOUND_ITEM in $($(dirname $0)/../../fetch_method/$FETCH_METHOD_ITEM.sh | grep "PROPERTIES:" | awk -F'PROPERTIES:' '{print $2}');do
      PROPERTIES_FOUND_ITEM_NAME="$(echo $PROPERTIES_FOUND_ITEM|awk -F'=' '{print $1}')"
      if [ "$PROPERTIES_FOUND_ITEM_NAME" = "$PROPERTIES_SUBCOMMAND" ];then
        echo $PROPERTIES_FOUND_ITEM
        if [ $? -eq 0 ];then
          exit 0
        fi
      fi
    done
  fi
done

