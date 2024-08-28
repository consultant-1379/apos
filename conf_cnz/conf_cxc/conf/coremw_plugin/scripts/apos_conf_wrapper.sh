#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2013 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_conf_wraqpper.sh
# Description:
#       This is a wrapper script for apos_conf.sh and apos_cleanup.sh to make sure they are executed only in virtual environment via plugin
# Note:
#       None.
##
# Output:
#       None.
##
# Changelog:
#
# - Thu July 19 2018 - Pranshu Sinha (xpransi)
#       First version.
##

FACTORY_FILE='/cluster/storage/system/config/lde/csm/templates/config/initial/ldews.os/factoryparam.conf'
CMD_GREP='/usr/bin/grep'
CMD_AWK='/usr/bin/awk'
if [ -f $FACTORY_FILE ];  then
  is_vm=$(cat $FACTORY_FILE | $CMD_GREP -i installation_hw | $CMD_AWK -F "=" '{print $2}')
  if [ "$is_vm" == "VM" ];  then
    /opt/ap/apos/conf/apos_conf.sh
    if [ $? -ne 0 ]; then
      echo "Failed to execute apos_conf.sh" > /tmp/apos_wrapup.log
      exit 1
    else
      echo "apos_conf.sh executed successfully" >> /tmp/apos_wrapup.log
    fi
    /opt/ap/apos/conf/apos_cleanup.sh
    if [ $? -ne 0 ]; then
      echo "Failed to execute apos_cleanup.sh" >> /tmp/apos_wrapup.log
      exit 1
    else
      echo "apos_cleanup.sh executed successfully" >> /tmp/apos_wrapup.log
    fi
  fi
fi
exit 0
