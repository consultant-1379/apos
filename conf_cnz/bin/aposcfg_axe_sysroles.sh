#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_axe_sysroles.sh
# Description:
#       This script loads the Rules and Roles for ENM system based on the 
#       aplication type. It is invoked from apos_finalize.sh script during MI and
#	during UP scenario this script invoked from campaign template.
# Note:
#       Script invoked during MI & UP.
##
# Usage:
#       ./aposcfg_axe_sysroles.sh
##
# Output:
#       None.
##
# Changelog:
#
# - Tue Sep 04 2018 -Suman Kumar Sahu (zsahsum)
#	Updated to support WIRELINE application type.
# - Thu Aug 23 2018 - Suman kumar Sahu (zsahsum)
#       Complete rework of the script 
# - Thu Jun 01 2018 - Suryanarayana Pammi (xpamsur)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Global Variables
CLUSTER_MI_PATH='/cluster/mi/installation'
ENM_MODELS_PATH='/opt/ap/apos/etc/enm_models'

app_type=$( $CMD_PARMTOOL get --item-list apt_type 2>/dev/null | awk -F'=' '{print $2}')
[ -z "$app_type" ] && app_type=$( cat $CLUSTER_MI_PATH/apt_type)  
[ -z "$app_type" ] && apos_abort 1 "axe_application type found NULL!!"

apos_log "Found application type as $app_type"


if [ ! "$app_type" == 'BSC' ] && [ ! "$app_type" == 'WIRELINE' ] ; then 
  apos_log "Loading $app_type rules and roles into IMM..."

  [ "$app_type" == 'TSC' ] && app_type='MSC'
  ENM_MODELS_FILE="${ENM_MODELS_PATH}/${app_type}_ENM_Roles_Rules.xml"
  [ ! -f "${ENM_MODELS_FILE}" ] && apos_abort 1 "${app_type}_ENM_Roles_Rules.xml file is not found. Exiting with errors."
  kill_after_try 3 3 4 immcfg -f "${ENM_MODELS_FILE}" || apos_abort 1 "Failed to load $app_type roles and rule into IMM."
  apos_log 'Done'
else
	apos_log "Found application type as $app_type, skipping the configuring models"
fi 

apos_outro $0
exit $TRUE

# End of file

