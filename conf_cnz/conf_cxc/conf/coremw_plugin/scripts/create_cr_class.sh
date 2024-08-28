#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       create_cr_slass.sh
# Description:
#       A script to create crmgmt object for virtual environment.
# Note:
#       Invoked by apos_conf plugin on both the Nodes of vAPG.
##
# Usage:
#       Used during vAPG maiden installation.
##
# Output:
#       None.
##
# Changelog:
# - Tue Oct 2 2018 - Pratap Reddy Uppada (XPRAUPP)
#   Rework to use existing functions
# - Thu Aug 9 2018 - Pranshu Sinha (XPRANSI)
#   First version.

# In case of MI, installation_type parameter is set to MI and configuration
# changes will be skipped. Where as installation_type parameter is not
# set on virtual and configuration settings are applied.
installation_type=$(cat /cluster/mi/installation/installation_type 2>/dev/null)
if [[ -n "$installation_type" && "$installation_type" == 'MI' ]]; then
  echo -e 'Skipping configuration changes, not applicable on Native!'
  exit 0
fi

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#-------------------------------------------------------------------------------
function is_compute_resource_class_exist(){
  local CMD_RESULT=$( kill_after_try 1 1 2 /usr/bin/immfind crMgmtId=1,AxeEquipmentequipmentMId=1 2>/dev/null)
  local RCODE=$?
  if [[ -n "$CMD_RESULT" && $RCODE -eq 0 ]]; then
    return $TRUE
  fi
  return $FALSE
}

#------------------------------------------------------------------------
function create_cr_class(){
  apos_log "--- create_cr_class() begin"
  if ! is_compute_resource_class_exist; then
   kill_after_try 5 5 6 "/usr/bin/immcfg -c AxeEquipmentCrMgmt crMgmtId=1,AxeEquipmentequipmentMId=1 -u"
   [ $? -ne 0 ] &&  apos_abort 'Failure while creating parent class [crMgmtId=1,AxeEquipmentequipmentMId=1]'
  else
    apos_log "--- crMgmtId=1,AxeEquipmentequipmentMId=1 already exist"
  fi
  apos_log "--- create_cr_class() end"
}

#### M A I N ####


if is_vAPG ; then
	create_cr_class
fi 

apos_outro $0

exit $TRUE
