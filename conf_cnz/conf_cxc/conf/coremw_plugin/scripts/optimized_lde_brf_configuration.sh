#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      optimized_lde_brf_configuration.sh
# Description:
#       This script is to enable optimized lde-brf functionality
#       during Upgrade 
#
##
# Changelog:
# - Wed 07 July 2021 - Sowjanya GVL (xsowgvl)
#      Added optimized lde-brf functionality configuration in cluster.conf file
#       First version.

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh 

CLU_FILE='/cluster/etc/cluster.conf'
[ ! -f $CLU_FILE ] && apos_abort 'cluster.conf file not found'
## BEGIN: Checking if optimizsed lde-brf backup folder configuration is present in cluster.conf file or not
if grep -q "backup-temp /var/log/lde-backup" "$CLU_FILE"; then
  apos_log 'Already optimized lde-brf backup folder configuration is present in cluster.conf file'
else
  sed -i '/node 2 control SC-2-2/a\backup-temp /var/log/lde-backup\' $CLU_FILE
  if [ $? -ne $TRUE ]; then
    apos_abort "failure while updating optimized lde-brf backup folder configuration in cluster.conf file"
  fi
  apos_log 'Sucessfully updated optimized lde-brf backup folder configuration in cluster.conf file'
fi
## END: Checking if optimizsed lde-brf backup folder configuration is present in cluster.conf file or not


## BEGIN: Checking if optimized lde-brf related configurations are present in cluster.conf file or not
if grep -q "optimized-backup on" "$CLU_FILE"; then
  apos_log 'Already optimized lde-brf configuration is present in cluster.conf file'
else
  sed -i 's/node 2 control SC-2-2/node 2 control SC-2-2\n\n#optimized backup configuration\noptimized-backup on/g' $CLU_FILE
  if [ $? -ne $TRUE ]; then
    apos_abort "failure while updating optimized lde-brf configuration in cluster.conf file"
  fi
  apos_log 'Sucessfully updated optimized lde-brf configuration in cluster.conf file'
fi
## END: Checking if optimized lde-brf related configurations are present in cluster.conf file or not

## BEGIN: Reload the cluster configuration on the current node
    cluster config -r -a &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
## END: Reload the cluster configuration

