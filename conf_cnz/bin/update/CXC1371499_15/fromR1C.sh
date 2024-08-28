#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1C.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Wed 04 May - Rajeshwari Padavala (xcsrpad)
#        First Version 
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"
CMD_SED="/usr/bin/sed"
NTP_CONFIG_FILE="/usr/lib/lde/config-management/ntp-config"


# Function to configure chrony 
function config_ntpserver() {   
  if is_vAPG; then
    # cleanup of old entries 
    if grep 'ntp.conf.local' "$NTP_CONFIG_FILE" &> /dev/null; then
      $CMD_SED -i '/includefile \/etc\/ntp\.conf\.local/d' $NTP_CONFIG_FILE
      apos_log "removing entries of ntp.conf.local"
    fi
    if grep 'chrony.conf.local' "$NTP_CONFIG_FILE" &> /dev/null; then
      $CMD_SED -i '/include \/etc\/chrony\.conf\.local/d' $NTP_CONFIG_FILE
      apos_log "removing entries of chrony.conf.local"
    fi
    CONFIG_FILE='/usr/lib/lde/config-management/apos_ntp-config'

    apos_log "invoking apos_deploy $CONFIG_FILE"
    ./apos_deploy.sh --from "$SRC/$CONFIG_FILE" --to $CONFIG_FILE || apos_abort "failure while deploying $CONFIG_FILE file"

    # reload config to update ntp-config
    apos_log "$CONFIG_FILE config reload invoking"
    $CONFIG_FILE config reload  
    if [ $? -ne 0 ]; then
      apos_abort "Failure while executing $CONFIG_FILE"
    fi
fi
}

# Main

pushd $CFG_PATH &> /dev/null
config_ntpserver
popd &> /dev/null

# R1C -> R1D
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_15 R1D
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

