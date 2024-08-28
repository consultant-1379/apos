#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_netconf.sh
# Description:
#       A script to enable netconf.
# Note:
#       None.
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Wed Jan 03 2024 - Surya Mahit (zsurjon)
#      Fix for TR IA69966
# - Thu Jan 21 2016 - Antonio Buonocunto (eanbuon)
#      Adaptation to systemd.
# - Thu Dec 04 2014 - Fabio Ronca (efabron)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CMD_GETENT="/usr/bin/getent"
CMD_USERMGMT='/opt/ap/apos/bin/usermgmt/usermgmt'

# Main

# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)
NETCONF_USER="netcc"

if [ $AP2 != $AP_TYPE ]; then
  $CMD_GETENT passwd $NETCONF_USER &> /dev/null
  RC="$?"
  if [ $RC -eq 2 ];then
    # Create a new User
    $CMD_USERMGMT "user add --gname=com-emergency --uid=\"random\" --uname=$NETCONF_USER --global --shell=/bin/false"
    
    if [ $? -ne 0 ]; then
      apos_abort "Failure while creating user $NETCONF_USER"
    else
      apos_log "User $NETCONF_USER successfully created"
    fi
  elif [ $RC -eq 0 ];then
    apos_log "User $NETCONF_USER already exists, skipping creation."
  else
    apos_abort "Failure while fetching info of user $NETCONF_USER"
  fi
fi

apos_outro $0
exit $TRUE

# End of file

