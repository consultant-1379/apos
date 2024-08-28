#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_apache_wa.sh
#
##
## Change Log:
#  Tue 25 Jul 2023 - Naveen Kumar G (zgxxnav)
#      First Version
#  With new apache revision (apache2-2.4.51-35.32.1.x86_64) "apache2-MPM" macro was removed so APOS_OSCONFBIN failed to install in  upgrade or deployment . To remove #  "apache2-MPM" macro dependency a fix was provided to install APOS_OSCONFBIN before APOS_OSEXTBIN installed (i..e, which is installing new apache version).
#  Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

RPM_CMD=cmw-rpm-config-add
STORAGE_PATH="/storage/system/software/coremw/repository/"
NODE_ID=$(cat /etc/cluster/nodes/this/id)

# WA for OSCONF BIN pre installation 
  apos_log "Applying OSCONF BIN WA..."

  # File containing RPM file/name list
  # In future if you need to include any other rpm you can extend the list
  RPM_LIST='APOS_OSCONFBIN'
  RPM_FILE=$(cmw-repository-list | grep -iw $RPM_LIST | grep -i NotUsed | awk -F ' ' '{print $1}' | awk -F '-' '{print $2"-"$3"-"$4}')

  RPM_FILE=$(find $STORAGE_PATH -name $RPM_FILE.x86_64.rpm 2>/dev/null)
  apos_log "Upgrading $RPM_FILE... "
  $RPM_CMD $RPM_FILE &>/dev/null
  if [ $? -ne 0 ]; then
    apos_log "Upgrading $RPM_FILE... Failed"
  else
    apos_log "Upgrading $RPM_FILE... Done"
  fi 

  #ACTIVATING RPMS
  apos_log "Cluster rpm Activation Started... "
  cluster rpm -A -n ${NODE_ID} &>/dev/null
  if [ $? -ne 0 ]; then
    apos_log "Cluster rpm Activation... Failed"
  else
    apos_log "Cluster rpm Activation... Success"
  fi 



apos_outro $0

exit $TRUE
