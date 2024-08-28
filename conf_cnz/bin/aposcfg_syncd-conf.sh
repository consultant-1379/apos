#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#   aposcfg_syncd-conf.sh
# Description:
#   A script to feed /etc/syncd.conf with APG-specific entries.
##
# Changelog:
# - Thu May 27 2021 - Yeswanth Vankayala (xyesvan)
#   Logic to replace the grub user files in synd.conf
# - Fri Apr 17 2020 - Swapnika Baradi (xswapba)
#   Fix for TR HY37574
# - Tue Feb 28 2017 - Francesco Rainone (efrarai)
#   Added cached_creds_duration for improving troubleshooting users login phase.
# - Tue Jul 26 2016 - Alessio Cascone (EALOCAE)
#   Rework to avoid issues with SSSD restarts.
# - Mon May 30 2016 - Alessio Cascone (EALOCAE)
#   Rework to avoid sync of credentials cache
#   when cached credentials feature is not enabled.
# - Mon Mar 21 2016 - Alessio Cascone (EALOCAE)
#   Added impacts for Cached Credentials feature on SLES12.
# - Fri Nov 27 2015 - Antonio Buonocunto (EANBUON)
#   apos servicemgmt adaptation
# - Thu Aug 06 2015 - Dharma Teja (xdhatej)
#   Added ftp mode status file
# - Wed Mar 04 2015 - Furquan Ullah (xfurull)
#   Added sshcbc state file
# - Thu Jun 11 2014 - Antonio Buonocunto (eanbuon)
#   First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

SYNCD_PATH="/etc/"
SYNCD_CONF="$SYNCD_PATH/syncd.conf"

#Create clear folder for APSO under PSO
APOS_CLEAR_PATH=$(apos_create_brf_folder clear)
APOS_CONFIG_PATH=$(apos_create_brf_folder config)
CONFIGURATION_HAS_CHANGED=$FALSE
LDE_GRUB_UPDATE_FILE="/usr/lib/lde/grub_update_users.sh"
APG_GRUB_UPDATE_FILE="/opt/ap/apos/conf/apos_grub_update_users.sh"
IS_AP2=$FALSE
AP_TYPE=$(apos_get_ap_type)
if [ "$AP_TYPE" == "AP2" ]; then
        IS_AP2=$TRUE
fi

# In order to include a new file under syncd control_only
# a new item should be added in the below list using the following syntax
#
# <absolute path of the local file>:<absolute path of the remote file>:<update remote>:<only AP1>
# i.e.
#   /etc/nscd.conf:/cluster/etc/nscd.conf:true:true
#

APOS_SYNCD_FILE_LIST="/etc/welcomemessage.conf:$APOS_CONFIG_PATH/welcomemessage.conf:false:false
                      /opt/ap/acs/conf/acs_asec_sshcbc.conf:$(</$STORAGE_CONFIG_PATH)/asec/sshcbc_state.conf:false:false
                      /var/home/cached_creds_duration:${APOS_CONFIG_PATH}/cached_creds_duration:false:true
                      /etc/apos_ftp_state.conf:$APOS_CONFIG_PATH/ftp_state.conf:false:false
		      /boot/aptype.conf:/cluster/storage/system/config/apos/aptype.conf:false:false
                      /var/home/ts_users/.ssh/id_rsa:/storage/system/config/apos/ssh_keys/id_rsa:false:false"

for ITEM in $APOS_SYNCD_FILE_LIST; do
  ITEM_LOCAL=$(echo $ITEM | awk -F':' '{print $1}')
  ITEM_REMOTE=$(echo $ITEM | awk -F':' '{print $2}')
  ITEM_NAME=$(basename $ITEM_LOCAL)
  ITEM_UPDATE_REMOTE=$(echo $ITEM | awk -F':' '{print $3}')
  ITEM_LOCAL_FOLDER=$(dirname $ITEM_LOCAL)
  ITEM_ONLY_AP1=$(echo $ITEM | awk -F':' '{print $4}')

  if [ ! -d "$ITEM_LOCAL_FOLDER" ];then
    mkdir -p "$ITEM_LOCAL_FOLDER"
  fi

  if [ $IS_AP2 -eq $TRUE ] && [ "$ITEM_ONLY_AP1" == "true" ] ; then
    apos_log "Skipping item '$ITEM_NAME' on AP2."
    continue
  fi

  if ! grep -q "$ITEM_NAME" $SYNCD_CONF; then
    cat >> $SYNCD_CONF << HEREDOC

file {
        description    = "APG $ITEM_NAME",
        local          = "$ITEM_LOCAL",
        remote         = "$ITEM_REMOTE",
        update_remote  = $ITEM_UPDATE_REMOTE,
        control_only   = true,
}

HEREDOC
    if [ $? -ne 0 ]; then
      apos_abort 1  "Failed to configure $ITEM_NAME in syncd"
    fi
    CONFIGURATION_HAS_CHANGED=$TRUE
    apos_log "Configuration for $ITEM_NAME added in syncd"
  else
    apos_log "Configuration for $ITEM_NAME already present in syncd"
  fi
done

#Replacing LDE update_grub file with APG solution
apos_log "Changing the configuration file"
if grep -q "${APG_GRUB_UPDATE_FILE}" $SYNCD_CONF; then
   apos_log "APG customized grub update file is present. Skip Changes .... "
else
  sed -i "s@$LDE_GRUB_UPDATE_FILE@$APG_GRUB_UPDATE_FILE@" $SYNCD_CONF 
  if [ $? -eq 0 ]; then
    apos_log "Replace of the file success"
    CONFIGURATION_HAS_CHANGED=$TRUE
  else
    apos_abort 1 "Failed to replace grub"
  fi 
fi

if [ $CONFIGURATION_HAS_CHANGED -eq $TRUE ]; then
  apos_log "restarting lde-syncd daemon..."
  apos_servicemgmt restart lde-syncd.service &> /dev/null || apos_abort "failure while restarting lde-syncd daemon"
  apos_log "done"
fi

apos_outro $0
exit $TRUE

# End of file
