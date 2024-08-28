#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A06.sh
# Description:
#       A script to update APOS_OSCONFBIN from the last version.
# Note:
#	None.
##
# Changelog:
# - Mon Feb 4 2016 -  Debdutta C (XDEBDCH)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

SRC='/opt/ap/apos/etc/deploy'
CFG_PATH='/opt/ap/apos/conf'
# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)

apos_intro $0

# R1A06 -> R1A07
#------------------------------------------------------------------------------#
# BEGIN: lde-dhcpd update
if [ -x /opt/ap/apos/conf/apos_deploy.sh ]; then
  if [ "$AP_TYPE" == "AP1" ]; then
     pushd $CFG_PATH &> /dev/null
    ./apos_deploy.sh --from $SRC/etc/init.d/lde-dhcpd --to /etc/init.d/lde-dhcpd
     [ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
     popd &> /dev/null
     echo 'restarting dhcp daemon...'
     service dhcpd restart &>/dev/null || apos_abort 'failure while restarting dhcpd service' 
     echo 'done'
  fi
fi
# END:  lde-dhcpd update


#------------------------------------------------------------------------------#

# R1A06 -> R1A07
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1A07
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
