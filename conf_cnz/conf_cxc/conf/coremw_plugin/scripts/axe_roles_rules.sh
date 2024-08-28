#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       axe_roles_rules.sh
# Description:
#       A script to update the Rules and Roles for Application 
#
# Usage:
#       Used during APG upgrade installation.
##
# Output:
#       None.
##
# Changelog:
# - Mon Aug 10 2020 - Yeswanth Vankayala (xyesvan)
#   Fix for rules for TSC app
# - Thu Jul 09 2020 - Ramya Medichelmi (ZMEDRAM)
#   Fix for TR HY52084
# - Thu Jun 11 2020 - Ramya Medichelmi (ZMEDRAM)
#   First version.

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

IMMCFG_CMD="/usr/bin/immcfg"
IMMFIND_CMD="/usr/bin/immfind"

IMMFIND_RULE_MSCSYSADM_1='ruleId=MscSaApCmd_1,roleId=MscCpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_MSCOPERATOR_1='ruleId=MscOpeApCmd_1,roleId=MscCpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_MSC_24='ruleId=MscSaFileManagement_24,roleId=MscCpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_MSC_25='ruleId=MscSaFileManagement_25,roleId=MscCpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_MSC_26='ruleId=MscSaFileManagement_26,roleId=MscCpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_MSC_27='ruleId=MscSaFileManagement_27,roleId=MscCpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_MSC_9='ruleId=MscOpeFileManagement_9,roleId=MscCpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_MSC_10='ruleId=MscOpeFileManagement_10,roleId=MscCpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_MSC_11='ruleId=MscOpeFileManagement_11,roleId=MscCpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_MSC_12='ruleId=MscOpeFileManagement_12,roleId=MscCpOperator,localAuthorizationMethodId=1'

IMMFIND_RULE_HLRSYSADM_1='ruleId=HlrSaApCmd_1,roleId=HlrAucMnpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_HLROPERATOR_1='ruleId=HlrOpeApCmd_1,roleId=HlrAucMnpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_HLR_24='ruleId=HlrSaFileManagement_24,roleId=HlrAucMnpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_HLR_25='ruleId=HlrSaFileManagement_25,roleId=HlrAucMnpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_HLR_26='ruleId=HlrSaFileManagement_26,roleId=HlrAucMnpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_HLR_27='ruleId=HlrSaFileManagement_27,roleId=HlrAucMnpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_HLR_9='ruleId=HlrOpeFileManagement_9,roleId=HlrAucMnpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_HLR_10='ruleId=HlrOpeFileManagement_10,roleId=HlrAucMnpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_HLR_11='ruleId=HlrOpeFileManagement_11,roleId=HlrAucMnpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_HLR_12='ruleId=HlrOpeFileManagement_12,roleId=HlrAucMnpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_IPSTPSYSADM_1='ruleId=IpStpSaApCmd_1,roleId=IpStpCpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_IPSTPOPERATOR_1='ruleId=IpStpOpeApCmd_1,roleId=IpStpCpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_IPSTP_24='ruleId=IpStpSaFileManagement_24,roleId=IpStpCpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_IPSTP_25='ruleId=IpStpSaFileManagement_25,roleId=IpStpCpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_IPSTP_26='ruleId=IpStpSaFileManagement_26,roleId=IpStpCpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_IPSTP_27='ruleId=IpStpSaFileManagement_27,roleId=IpStpCpSystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_IPSTP_9='ruleId=IpStpOpeFileManagement_9,roleId=IpStpCpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_IPSTP_10='ruleId=IpStpOpeFileManagement_10,roleId=IpStpCpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_IPSTP_11='ruleId=IpStpOpeFileManagement_11,roleId=IpStpCpOperator,localAuthorizationMethodId=1'
IMMFIND_RULE_IPSTP_12='ruleId=IpStpOpeFileManagement_12,roleId=IpStpCpOperator,localAuthorizationMethodId=1'

app_type=$( $CMD_PARMTOOL get --item-list apt_type 2>/dev/null | awk -F'=' '{print $2}')
[ -z "$app_type" ] && app_type=$( cat $CLUSTER_MI_PATH/apt_type)
[ -z "$app_type" ] && apos_abort 1 "axe_application type found NULL!!"

apos_log "Found application type as $app_type"
[ "$app_type" == 'TSC' ] && app_type="MSC"


#BEGIN: MSC

if [ "$app_type" == 'MSC' ] ; then

  $IMMFIND_CMD | grep $IMMFIND_RULE_MSCSYSADM_1
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|alogfind|bupidls|cfeted|clhls|cmdlls|cpdtest|cpfls|cpfrm|cqrhils|cqrhlls|crdls|fixerls|misclhls|mml|tesrvls|mktr' $IMMFIND_RULE_MSCSYSADM_1" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_MSCSYSADM_1"
    apos_log "$IMMFIND_RULE_MSCSYSADM_1 has been updated successfully"
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_MSCOPERATOR_1
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:alist|cpdtest|cpfls|cpfrm|crdls|fixerls|misclhls|mml' $IMMFIND_RULE_MSCOPERATOR_1" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_MSCOPERATOR_1"
    apos_log "$IMMFIND_RULE_MSCOPERATOR_1 has been updated successfully"
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_MSC_24
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Read-only access to the folder /support_data and subtree' -a permission='4' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data,*' $IMMFIND_RULE_MSC_24" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_MSC_24"
    apos_log "$IMMFIND_RULE_MSC_24 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_MSC_25
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Read-only access to folder /support_data and full access to folders and files present in it' -a permission='7' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data.*' $IMMFIND_RULE_MSC_25" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_MSC_25"
    apos_log "$IMMFIND_RULE_MSC_25 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_MSC_26
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Full access to create any folder in folder /support_data' -a permission='7' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data,FileGroup,*' $IMMFIND_RULE_MSC_26" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_MSC_26"
    apos_log "$IMMFIND_RULE_MSC_26 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_MSC_27
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Full access to create any file in folder /support_data' -a permission='7' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data,FileInformation,*' $IMMFIND_RULE_MSC_27" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_MSC_27"
    apos_log "$IMMFIND_RULE_MSC_27 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_MSC_9
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_MSC_9 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_MSC_9"
    apos_log "$IMMFIND_RULE_MSC_9 rule has been deleted successfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_MSC_10
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_MSC_10 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_MSC_10"
    apos_log "$IMMFIND_RULE_MSC_10 rule has been deleted successfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_MSC_11
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_MSC_11 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_MSC_11"
    apos_log "$IMMFIND_RULE_MSC_11 rule has been deleted successfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_MSC_12
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_MSC_12 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_MSC_12"
    apos_log "$IMMFIND_RULE_MSC_12 rule has been deleted successfully."
  fi

fi

#End: MSC

#BEGIN: HLR

if [ "$app_type" == 'HLR' ] ; then

  $IMMFIND_CMD | grep $IMMFIND_RULE_HLRSYSADM_1
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|alogfind|bupidls|cfeted|clhls|cmdlls|cpdtest|cpfls|cpfrm|cqrhils|cqrhlls|crdls|fixerls|misclhls|mml|tesrvls|xpuls|mktr' $IMMFIND_RULE_HLRSYSADM_1" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_HLRSYSADM_1"
    apos_log "$IMMFIND_RULE_HLRSYSADM_1 has been updated successfully"
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_HLROPERATOR_1
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:alist|cpdtest|cpfls|cpfrm|crdls|fixerls|misclhls|mml' $IMMFIND_RULE_HLROPERATOR_1" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_HLROPERATOR_1"
    apos_log "$IMMFIND_RULE_HLROPERATOR_1 has been updated successfully"
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_HLR_24
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Read-only access to the folder /support_data and subtree' -a permission='4' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data,*' $IMMFIND_RULE_HLR_24" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_HLR_24"
    apos_log "$IMMFIND_RULE_HLR_24 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_HLR_25
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Read-only access to folder /support_data and full access to folders and files present in it' -a permission='7' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data.*' $IMMFIND_RULE_HLR_25" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_HLR_25"
    apos_log "$IMMFIND_RULE_HLR_25 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_HLR_26
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Full access to create any folder in folder /support_data' -a permission='7' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data,FileGroup,*' $IMMFIND_RULE_HLR_26" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_HLR_26"
    apos_log "$IMMFIND_RULE_HLR_26 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_HLR_27
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Full access to create any file in folder /support_data' -a permission='7' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data,FileInformation,*' $IMMFIND_RULE_HLR_27" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_HLR_27"
    apos_log "$IMMFIND_RULE_HLR_27 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_HLR_9
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_HLR_9 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_HLR_9"
    apos_log "$IMMFIND_RULE_HLR_9 rule has been deleted successfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_HLR_10
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_HLR_10 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_HLR_10"
    apos_log "$IMMFIND_RULE_HLR_10 rule has been deleted successfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_HLR_11
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_HLR_11 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_HLR_11"
    apos_log "$IMMFIND_RULE_HLR_11 rule has been deleted successfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_HLR_12
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_HLR_12 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_HLR_12"
    apos_log "$IMMFIND_RULE_HLR_12 rule has been deleted successfully."
  fi

fi

#END: HLR 

#BEGIN: IPSTP

if [ "$app_type" == 'IPSTP' ] ; then
  
  $IMMFIND_CMD | grep $IMMFIND_RULE_IPSTPSYSADM_1
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|alogfind|bupidls|cfeted|clhls|cmdlls|cpdtest|cpfls|cpfrm|cqrhils|cqrhlls|crdls|fixerls|misclhls|mml|tesrvls|mktr' $IMMFIND_RULE_IPSTPSYSADM_1" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_IPSTPSYSADM_1"
    apos_log "$IMMFIND_RULE_IPSTPSYSADM_1 has been updated successfully"
  fi 

  $IMMFIND_CMD | grep $IMMFIND_RULE_IPSTPOPERATOR_1
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:alist|cpdtest|cpfls|cpfrm|crdls|fixerls|misclhls|mml' $IMMFIND_RULE_IPSTPOPERATOR_1" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_IPSTPOPERATOR_1"
    apos_log "$IMMFIND_RULE_IPSTPOPERATOR_1 has been updated successfully"
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_IPSTP_24
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Read-only access to the folder /support_data and subtree' -a permission='4' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data,*' $IMMFIND_RULE_IPSTP_24" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_IPSTP_24"
    apos_log "$IMMFIND_RULE_IPSTP_24 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_IPSTP_25
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Read-only access to folder /support_data and full access to folders and files present in it' -a permission='7' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data.*' $IMMFIND_RULE_IPSTP_25" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_IPSTP_25"
    apos_log "$IMMFIND_RULE_IPSTP_25 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_IPSTP_26
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Full access to create any folder in folder /support_data' -a permission='7' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data,FileGroup,*' $IMMFIND_RULE_IPSTP_26" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_IPSTP_26"
    apos_log "$IMMFIND_RULE_IPSTP_26 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_IPSTP_27
  if [ $? -ne 0 ] ; then
    kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='Full access to create any file in folder /support_data' -a permission='7' -a ruleData='ManagedElement,SystemFunctions,FileM,LogicalFs,FileGroup=support_data,FileInformation,*' $IMMFIND_RULE_IPSTP_27" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_IPSTP_27"
    apos_log "$IMMFIND_RULE_IPSTP_27 rule has been added succesfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_IPSTP_9
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_IPSTP_9 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_IPSTP_9"
    apos_log "$IMMFIND_RULE_IPSTP_9 rule has been deleted successfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_IPSTP_10
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_IPSTP_10 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_IPSTP_10"
    apos_log "$IMMFIND_RULE_IPSTP_10 rule has been deleted successfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_IPSTP_11
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_IPSTP_11 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_IPSTP_11"
    apos_log "$IMMFIND_RULE_IPSTP_11 rule has been deleted successfully."
  fi

  $IMMFIND_CMD | grep $IMMFIND_RULE_IPSTP_12
  if [ $? -eq 0 ] ; then
    kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_IPSTP_12 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_IPSTP_12"
    apos_log "$IMMFIND_RULE_IPSTP_12 rule has been deleted successfully."
  fi

fi

#END: IPSTP
