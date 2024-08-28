#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_cleanup.sh
##
# Description:
#       A script implementing clean-up of apos directories according to
#       installation parameters.
##
# Changelog:

# - Fri 31 Aug 2018 -Suman Kumar Sahu (zsahsum)
#	Script has updated to fix BSC related issues.
# - Thu 23 Aug 2018 - Suman Kumar Sahu (zsahsum)
#       Script has updated to remove the ENM role xml
#       files from new enm_models directory.
# - Mon 30 July 2018 - Suman Kumar Sahu (zsahsum)
#       Updated to remove .xml files(Roles & Rules)
#	to handle ENM roles & rules accoring to 
#	Application type (MSC/HLR/IPSTP).
# - Thu Apr 12 2018 - Amit Varma (xamivar)
#       Removed the code for adhoc template solution.
# - Mon Jan 23 2017 - Franco D'Ambrosio (efradam)
#       Added the removal of apos_guest.sh script
# - Wed Sep 21 2016 - Raghavendra Koduri (XKODRAG)
# 			healing impacts.
# - Mon Sep 12 2016 - Pratap Reddy Uppada (xpraupp)
#       TR HV23454 Fix
# - Fri Jan 15 2016 - Francesco Rainone (EFRARAI)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

APOSDIR=/opt/ap/apos/
CONFDIR=${APOSDIR}/conf
ETCBASEDIR=${APOSDIR}/etc
STORAGE_PATHS="/usr/share/pso/storage-paths"
STORAGE_CONFIG_PATH="$STORAGE_PATHS/config"
ENM_MODELS_PATH="/opt/ap/apos/etc/enm_models/"
CLUSTER_MI_PATH="/cluster/mi/installation"
STORAGE_PATH_APT="/storage/system/config/apos"
PSO_FOLDER=$( apos_check_and_cat $STORAGE_CONFIG_PATH)
APOS_PSO_FOLDER="$PSO_FOLDER/apos"

if [ -f "$APOS_PSO_FOLDER/datadisk_replication_type" ]; then
  datadisk_replication_type=$( cat $APOS_PSO_FOLDER/datadisk_replication_type)
fi

# For troubleshooting purpose, here logging is enabled for datadisk_replication_type
[ -z "$datadisk_replication_type" ] && apos_log "datadisk replication type found NULL!!"

if [ -f "$APOS_PSO_FOLDER/installation_hw" ]; then
  hw_type=$( cat $APOS_PSO_FOLDER/installation_hw)
fi

# For troubleshooting purpose, here logging is enabled for hw_type
[ -z "$hw_type" ] && apos_log "installation hardware found NULL!!"

if [[ -z "$datadisk_replication_type" && -n "$hw_type" ]]; then
  datadisk_replication_type="DRBD"
  if [[ "$hw_type" == "GEP1" || "$hw_type" == "GEP2" ]]; then
    datadisk_replication_type="MD"
  fi
fi

if [ -f "$CONFDIR/apos_adhoc_template_mgr.sh" ]; then
  rm -f $CONFDIR/apos_adhoc_template_mgr.sh
fi

ADHOC_FILES_LIST="$APOS_PSO_FOLDER/HEAT_AP-A.yml
                  $APOS_PSO_FOLDER/HEAT_AP-B.yml"

for file in $ADHOC_FILES_LIST; do
  [ -f "$file" ] && rm -f $file
done

if [ "$datadisk_replication_type" == "MD" ]; then
  rm ${ETCBASEDIR}/deploy/usr/lib/systemd/scripts/apos-drbd.sh
  rm ${ETCBASEDIR}/deploy/usr/lib/systemd/system/apos-drbd.service
  mv ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-comgroup_md ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-comgroup
  mv ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-tsgroup_md ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-tsgroup
  mv ${ETCBASEDIR}/deploy/etc/services_md ${ETCBASEDIR}/deploy/etc/services
  rm ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-comgroup_drbd
  rm ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-tsgroup_drbd
  rm ${ETCBASEDIR}/deploy/etc/services_drbd
fi

if [ "$datadisk_replication_type" == "DRBD" ]; then
  mv ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-comgroup_drbd ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-comgroup
  mv ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-tsgroup_drbd ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-tsgroup
  mv ${ETCBASEDIR}/deploy/etc/services_drbd ${ETCBASEDIR}/deploy/etc/services
  rm ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-comgroup_md
  rm ${ETCBASEDIR}/deploy/etc/sudoers.d/APG-tsgroup_md
  rm ${ETCBASEDIR}/deploy/etc/services_md
fi

if [ "$hw_type" != "VM" ]; then
  rm ${ETCBASEDIR}/deploy/usr/lib/systemd/scripts/apos-system-conf.sh
  rm ${ETCBASEDIR}/deploy/usr/lib/systemd/scripts/apos-finalize-system-conf.sh
  rm ${ETCBASEDIR}/deploy/usr/lib/systemd/system/apos-system-config.service
  rm ${ETCBASEDIR}/deploy/usr/lib/systemd/system/apos-finalize-system-config.service
  rm ${ETCBASEDIR}/deploy/usr/lib/systemd/scripts/apos-recovery-conf.sh
  rm ${ETCBASEDIR}/deploy/usr/lib/systemd/system/apos-recovery-conf.service
  rm ${CONFDIR}/enlarged_ddisk_impacts.sh
  rm ${CONFDIR}/apos_guest.sh
  rm ${CONFDIR}/apos_system_conf.sh
  rm ${CONFDIR}/apos_finalize_system_conf.sh
  rm ${CONFDIR}/apos_snrinit_rebuild.sh
  rm ${ETCBASEDIR}/deploy/etc/dhcpd.conf.local_vm
elif [ "$hw_type" == 'VM' ]; then 
  rm ${ETCBASEDIR}/deploy/etc/dhcpd.conf.local
fi


  app_type=$( $CMD_PARMTOOL get --item-list apt_type 2>/dev/null | \
  awk -F'=' '{print $2}')
    if [ -z "$app_type" ]; then
      app_type=$( cat $CLUSTER_MI_PATH/apt_type)
        [ -z "$app_type" ] && apos_abort 1 "axe_application parameter not found!"
    fi
    if   [ "$app_type" == "MSC" ] || [ "$app_type" == "TSC" ];then
      if [ "$app_type" == "MSC" ] ;then
        echo "=====================MSC============================="
      else
        echo "=====================TSC============================="
      fi
    if [ -f "${ENM_MODELS_PATH}/HLR_ENM_Roles_Rules.xml" ]; then
      rm -f ${ENM_MODELS_PATH}/HLR_ENM_Roles_Rules.xml
    fi
    if [ -f "${ENM_MODELS_PATH}/IPSTP_ENM_Roles_Rules.xml" ]; then
      rm -f ${ENM_MODELS_PATH}/IPSTP_ENM_Roles_Rules.xml
    fi
    elif  [ "$app_type" == "HLR" ];then
      echo "=====================HLR============================="
    if [ -f "${ENM_MODELS_PATH}/MSC_ENM_Roles_Rules.xml" ]; then
      rm -f ${ENM_MODELS_PATH}/MSC_ENM_Roles_Rules.xml
    fi
    if [ -f "${ENM_MODELS_PATH}/IPSTP_ENM_Roles_Rules.xml" ]; then
      rm -f ${ENM_MODELS_PATH}/IPSTP_ENM_Roles_Rules.xml
    fi
    elif  [ "$app_type" == "IPSTP" ];then
      echo "=====================IPSTP============================="
    if [ -f "${ENM_MODELS_PATH}/MSC_ENM_Roles_Rules.xml" ]; then
      rm -f ${ENM_MODELS_PATH}/MSC_ENM_Roles_Rules.xml
    fi
    if [ -f "${ENM_MODELS_PATH}/HLR_ENM_Roles_Rules.xml" ]; then
      rm -f ${ENM_MODELS_PATH}/HLR_ENM_Roles_Rules.xml
    fi
    else 
      rm -rf ${ENM_MODELS_PATH}

fi

apos_outro $0
exit $TRUE

# End of file
