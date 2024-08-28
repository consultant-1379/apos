#!/bin/bash -u
# ------------------------------------------------------------------------
# copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_kernel_parameter_change.sh
# Description:
#       A script to configure the ipv6 external interfaces.
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
# - Mon Aug 08 2020 - Suryanarayana Pammi(xpamsur)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

INTERFACE_PATH='/proc/sys/net/ipv6/conf'

apos_log 'entering apos_kernel_parameter_change.sh script'

#configuring the interfaces
for cust_interface in eth1 eth7 eth8 eth9 eth10
do
  ## Check if a directory does not exist ###
  if [ ! -d $INTERFACE_PATH/$cust_interface ]; then
    apos_log "Directory $INTERFACE_PATH/$cust_interface DOES NOT exists."
  else
    apos_log "Directory $INTERFACE_PATH/$cust_interface exists."
    ## Configure the parameters if the directory exists
    sysctl -w net.ipv6.conf.$cust_interface.forwarding=0
    sysctl -w net.ipv6.conf.$cust_interface.autoconf=0
    sysctl -w net.ipv6.conf.$cust_interface.use_tempaddr=0
    sysctl -w net.ipv6.conf.$cust_interface.accept_ra=0
    sysctl -w net.ipv6.conf.$cust_interface.accept_redirects=0
 fi
done

apos_log 'apos_kernel_parameter_change.sh script execution completed'

apos_outro $0
exit $TRUE

# End of file
