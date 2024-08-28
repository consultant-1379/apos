#!/bin/bash 
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_axe_info.sh
# Description:
#       A script to configure the AxeInfo class.
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
# - Tue Jul 25 2017 - Yeswanth Vankayala (xyesvan)
#    Removed get_value function and included in apos_common
# - Thu Dec 1 2016 - Antonio Buonocunto (eanbuon)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Variables
CMD_APOSGETINFO='/opt/ap/apos/bin/gi/apos_getinfo'
CMD_HWTYPE='/opt/ap/apos/conf/apos_hwtype.sh'

# Get hypervisor
HYPERVISOR=$( $CMD_HWTYPE --verbose | grep "system-manufacturer" | awk -F"=" '{print $2}' | sed -e 's@^[[:space:]]*@@g' -e 's@^"@@g' -e 's@"$@@g' )
if [ -z "$HYPERVISOR" ];then
  apos_abort "Failure while fetching hypervisor"
fi

# Configuration item: apg_dhcp
# Description: This configuration item specifies if APG should act as DHCP server of the Network Function.
# Allowed Values: { "ON", "OFF" }
# Default value : { "OFF" }

AXEINFO_APG_DHCP=$(get_axe_toggle_value apg_dhcp "^ON$|^OFF$" "OFF")
if [ -z "$AXEINFO_APG_DHCP" ];then
  apos_abort "Failure while fetching apg_dhcp"
fi
kill_after_try 5 5 6 "/usr/bin/immcfg -c AxeInfo -a value="$AXEINFO_APG_DHCP" axeInfoId=apg_dhcp 2>/dev/null" || apos_abort 1 'Failure while creating AxeInfo apg_dhcp'

# Configuration item: cphw_env
# Description: This configuration item specifies the string reported in chainboot file used by cphw for the environment identification.
# Allowed Values: vapz-vmware, vapz
AXEINFO_CPHW_ENV=""
if [[ "$HYPERVISOR" =~ .*vmware.* ]];then
  AXEINFO_CPHW_ENV="vapz-vmware"
elif [[ "$HYPERVISOR" =~ .*openstack.* ]];then
  AXEINFO_CPHW_ENV="vapz"
else
  apos_abort "unsupported value: \"$AXEINFO_CPHW_ENV\""
fi
kill_after_try 5 5 6 "/usr/bin/immcfg -c AxeInfo -a value="$AXEINFO_CPHW_ENV" axeInfoId=cphw_env 2>/dev/null" || apos_abort 1 'Failure while creating AxeInfo cphw_env'
apos_log "AxeInfo CPHW env configured to $AXEINFO_CPHW_ENV"

# Configuration item: HardRecoveryMethod
# Description: This configuration item specifies the type of hard Recovery.
# Allowed Values: reinstallation, redeployment
AXEINFO_HARD_RECOVERY=""
if [[ "$HYPERVISOR" =~ .*vmware.* ]];then
  AXEINFO_HARD_RECOVERY="reinstallation"
elif [[ "$HYPERVISOR" =~ .*openstack.* ]];then
  AXEINFO_HARD_RECOVERY="redeployment"
else
  apos_abort "unsupported value: \"$AXEINFO_HARD_RECOVERY\""
fi
kill_after_try 5 5 6 "/usr/bin/immcfg -c AxeInfo -a value="$AXEINFO_HARD_RECOVERY" axeInfoId=HardRecoveryMethod 2>/dev/null" || apos_abort 1 'Failure while creating AxeInfo HardRecoveryMethod'
apos_log "AxeInfo HardRecoveryMethod configured to $AXEINFO_HARD_RECOVERY"

apos_outro $0
exit $TRUE

# End of file

