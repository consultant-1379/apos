#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_ha_wa.sh
#
##
## Change Log:
#  Tue 22 Jul 2022 - Swapnika Baradi (xswapba) 
#      First Version
#  Fri 28 Jul 2023 - T Rajendra Prasad (zrjaapr)
#      Fix for TR IA49319
#  Fri 4 Aug 2023 - T Rajendra Prasad (zrjaapr)
#      Fix for TR IA50778

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

RPM_CMD=cmw-rpm-config-add
STORAGE_PATH="/storage/system/software/coremw/repository/"
NODE_ID=$(cat /etc/cluster/nodes/this/id)

# WA for HA BIN pre installation 
  apos_log "Applying HA WA..."

  # File containing RPM file/name list
  # In future if you need to include any other rpm you can extend the list
  RPM_LIST="APOS_HAAGENTBIN AES_CDHBIN AES_DDTBIN"
  for rpm in $RPM_LIST
  do
  	RPM_FILE=$(cmw-repository-list | grep -iw $rpm | grep -i NotUsed | awk -F ' ' '{print $1}' | awk -F '-' '{print $2"-"$3"-"$4}')

  	RPM_FILE=$(find $STORAGE_PATH -name $RPM_FILE.x86_64.rpm 2>/dev/null)
	if [ -z $RPM_FILE ]; then
        	continue
  	fi
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
done
# WA for HA: Unmount failed

apos_outro $0

exit $TRUE
