#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_immcfg_sec_cmd.sh
# Description:
#       A script to update the rules AxeApCmd_71 and AxeApCmd_70, so that ldap user with role SystemSecurityAdministartor will be able to access sec-encryption-key-update command but not user with role SystemAdministrator
# Note:
#       Invoked by apos_conf plugin
#       on both the Nodes of vAPG.
# Usage:
#       Used during APG upgrade installation.
##
# Output:
#       None.
##
# Changelog:
# - Fri Auf 13 2021 - Anjireddy Daka(xdakanj)
#   Fix the space issue for fqdndef command
# - Fri Aug 5 2021 - Anjireddy Daka (xdakanj)
#   Included fqdndef command for APG43L Security Enhancement SYSLOG adaption support
# - Thu Jul 2 2020 - Medichelmi Ramya (ZMEDRAM)
#   Modified the rules for Data at Rest
# - Thu Oct 24 2019 - Sowjanya G V L (XSOWGVL)
#   Modified the script to expose Tls MO to ldap user with role SystemSecurityAdministrator
# - Wed May 15 2019 - Yeswanth Vankayala (xyesvan)
#    Updated security rules for 3.7
# - Wed Apr 17 2019 - Sowjanya G V L (XSOWGVL)
#   Fix for TR HX61311 (removed kill_after_try function for updating ruleId=AxeApCmd_70,roleId=SystemAdministrator,localAuthorizationMethodId=1)
# - Mon Apr 08 2019 - Suman kumar sahu (ZSAHSUM)
# - Script has been updated to configure required rules for FTP over TLS
# - Thu Mar 07 2019 - Sowjanya G V L (XSOWGVL)
#   Modified to use kill_after_retry function for updating imm commands and also done few other changes realted to comments 
# - Thu Feb 28 2019 - Sowjanya G V L (XSOWGVL)
#   First version.


# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh
#set -x

#BEGIN : sec-encryption-key-update command should not be accessible to ldap user with role SystemAdministrator

IMMCFG_CMD="/usr/bin/immcfg"
IMMFIND_CMD="/usr/bin/immfind"
IMMFIND_RULE_70="ruleId=AxeApCmd_70,roleId=SystemAdministrator,localAuthorizationMethodId=1"
IMMFIND_RULE_71="ruleId=AxeApCmd_71,roleId=SystemSecurityAdministrator,localAuthorizationMethodId=1"
IMMFIND_RULE_55='ruleId=AxeSysm_55,roleId=SystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_57='ruleId=AxeSysm_57,roleId=SystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_58='ruleId=AxeSysm_58,roleId=SystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_40='ruleId=AxeBackupRestore_40,roleId=SystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_41='ruleId=AxeBackupRestore_41,roleId=SystemReadOnly,localAuthorizationMethodId=1'
IMMFIND_RULE_59='ruleId=AxeSysm_59,roleId=SystemReadOnly,localAuthorizationMethodId=1'
IMMFIND_RULE_SYSTEMREAD_70='ruleId=AxeSysm_70,roleId=SystemReadOnly,localAuthorizationMethodId=1'
IMMFIND_RULE_63='ruleId=AxeSysm_63,roleId=SystemReadOnly,localAuthorizationMethodId=1'
IMMFIND_RULE_56='ruleId=AxeSysm_56,roleId=SystemReadOnly,localAuthorizationMethodId=1'
IMMFIND_RULE_61='ruleId=AxeSysm_61,roleId=SystemAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_3='ruleId=AxeUserManagement_3,roleId=SystemSecurityAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_TLS_1='ruleId=Axetls_1,roleId=SystemSecurityAdministrator,localAuthorizationMethodId=1'
IMMFIND_RULE_17='ruleId=AxeApCmd_17,roleId=SystemReadOnly,localAuthorizationMethodId=1'
IMMFIND_RULE_39='ruleId=AxeApCmd_39,roleId=CpRole1,localAuthorizationMethodId=1'
IMMFIND_RULE_42='ruleId=AxeApCmd_42,roleId=CpRole2,localAuthorizationMethodId=1'
IMMFIND_RULE_43='ruleId=AxeApCmd_43,roleId=CpRole3,localAuthorizationMethodId=1'
IMMFIND_RULE_44='ruleId=AxeApCmd_44,roleId=CpRole4,localAuthorizationMethodId=1'
IMMFIND_RULE_45='ruleId=AxeApCmd_45,roleId=CpRole5,localAuthorizationMethodId=1'
IMMFIND_RULE_46='ruleId=AxeApCmd_46,roleId=CpRole6,localAuthorizationMethodId=1'
IMMFIND_RULE_47='ruleId=AxeApCmd_47,roleId=CpRole7,localAuthorizationMethodId=1'
IMMFIND_RULE_48='ruleId=AxeApCmd_48,roleId=CpRole8,localAuthorizationMethodId=1'
IMMFIND_RULE_49='ruleId=AxeApCmd_49,roleId=CpRole9,localAuthorizationMethodId=1'
IMMFIND_RULE_50='ruleId=AxeApCmd_50,roleId=CpRole10,localAuthorizationMethodId=1'
IMMFIND_RULE_51='ruleId=AxeApCmd_51,roleId=CpRole11,localAuthorizationMethodId=1'
IMMFIND_RULE_52='ruleId=AxeApCmd_52,roleId=CpRole12,localAuthorizationMethodId=1'
IMMFIND_RULE_53='ruleId=AxeApCmd_53,roleId=CpRole13,localAuthorizationMethodId=1'
IMMFIND_RULE_54='ruleId=AxeApCmd_54,roleId=CpRole14,localAuthorizationMethodId=1'
IMMFIND_RULE_CPROLE15_55='ruleId=AxeApCmd_55,roleId=CpRole15,localAuthorizationMethodId=1'

$IMMFIND_CMD |grep $IMMFIND_RULE_70
if [ $? -eq 0 ] ; then
	$IMMCFG_CMD -a ruleData='regexp:^\b((?!alogset\b)(?!aloglist\b)(?!alogpchg\b)(?!alogpls\b)(?!alogfind\b)(?!csadm\b)(?!gmlog\b)(?!rpmo\b)(?!mml\b)(?!ldapdef\b)(?!fqdndef\b)(?!ipsecdef\b)(?!ipsecls\b)(?!ipsecrm\b)(?!sec-encryption-key-update\b)(?!wssadm\b)).*$' $IMMFIND_RULE_70
else
	apos_abort 1 '$IMMFIND_RULE_70  not found '
fi
#END : sec-encryption-key-update command should not be accessible to ldap user with role SystemAdministrator

#BEGIN : sec-encryption-key-update command should be accessible to ldap user with role SystemSecurityAdministrator only
$IMMFIND_CMD | grep $IMMFIND_RULE_71
if [ $? -eq 0 ] ; then
	kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to execute AP commands aehls, alist, alogfind, csadm, ldapdef, fqdndef, ipsecdef, ipsecls, ipsecrm, sec-encryption-key-update, wssadm' -a ruleData='regexp:alogset|aloglist|alogpchg|alogpls|aehls|alist|alogfind|csadm|ldapdef|ipsec.*|sec-encryption-key-update|wssadm.*' $IMMFIND_RULE_71"
else
	apos_abort 1 '$IMMFIND_RULE_71  not found '
fi

#END : sec-encryption-key-update command should be accessible to ldap user with role SystemSecurityAdministrator only

#BEGIN : Exposing the FtpTlsServer MO for SystemAdministrator and port configuration
$IMMFIND_CMD |grep $IMMFIND_RULE_55
if [ $? -eq 0 ] ; then
  kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_55 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_55"
  apos_log "$IMMFIND_RULE_55 rule has been deleted succesfuly."
fi
#Adding new rules
$IMMFIND_CMD | grep $IMMFIND_RULE_57
if [ $? -ne 0 ] ; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='No access to MOC FtpTls' -a permission='0' -a ruleData='ManagedElement,SystemFunctions,SysM,FileTPM,FtpTls' $IMMFIND_RULE_57" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_57"
  apos_log "$IMMFIND_RULE_57 rule has been added succesfully."
fi

$IMMFIND_CMD |grep $IMMFIND_RULE_58
if [ $? -ne 0 ] ; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='No access to MOC Sftp' -a permission='0' -a ruleData='ManagedElement,SystemFunctions,SysM,FileTPM,Sftp' $IMMFIND_RULE_58" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_58"
  apos_log "$IMMFIND_RULE_58 rule has been added succesfully."
fi

#END : Exposing the FtpTlsServer MO for SystemAdministrator and port configuration


#Security Rules for 3.7
#BEGIN: New Rules Addition
$IMMFIND_CMD | grep $IMMFIND_RULE_40
if [ $? -ne 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='No access to action createSecuredBackupWithPasswd under MOC BrmBackupManager' -a permission='0' -a ruleData='ManagedElement,SystemFunctions,BrM,BrmBackupManager.createSecuredBackupWithPasswd' $IMMFIND_RULE_40" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_40"
  apos_log "$IMMFIND_RULE_40 has been added sucessfully."
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_41
if [ $? -ne 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='No access to action createSecuredBackupWithPasswd under MOC BrmBackupManager' -a permission='0' -a ruleData='ManagedElement,SystemFunctions,BrM,BrmBackupManager.createSecuredBackupWithPasswd' $IMMFIND_RULE_41" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_41"
  apos_log "$IMMFIND_RULE_41 has been added successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_59
if [ $? -ne 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='No access to MOC FileTPM,FtpTls' -a permission='0' -a ruleData='ManagedElement,SystemFunctions,SysM,FileTPM,FtpTls' $IMMFIND_RULE_59" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_59"
  apos_log "$IMMFIND_RULE_59 has been added successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_SYSTEMREAD_70
if [ $? -ne 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='No access to MOC FileTPM,Sftp' -a permission='0' -a ruleData='ManagedElement,SystemFunctions,SysM,FileTPM,Sftp' $IMMFIND_RULE_70" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_SYSTEMREAD_70"
  apos_log "$IMMFIND_RULE_SYSTEMREAD_70 has been added successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_3
if [ $? -ne 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -c Rule -a userLabel='No access to attribute UserManagement.privacyNotice' -a permission='0' -a ruleData='ManagedElement,SystemFunctions,SecM,UserManagement.privacyNotice' $IMMFIND_RULE_3" || apos_abort 1 "Failed to add rule $IMMFIND_RULE_3"
  apos_log "$IMMFIND_RULE_3 has been added successfully"
fi


#END: New Rules Addition
#BEGIN: Updation of Rules

$IMMFIND_CMD | grep $IMMFIND_RULE_57
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='No access to MOC FileTPM,FtpTls' $IMMFIND_RULE_57" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_57"
  apos_log "$IMMFIND_RULE_57 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_58
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='No access to MOC FileTPM,Sftp' $IMMFIND_RULE_58" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_58"
  apos_log "$IMMFIND_RULE_58 has been updated successfully"
fi

#BEGIN:DATA_REST

$IMMFIND_CMD | grep $IMMFIND_RULE_17
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permissions to all listing AP commands having 'ls' as final letters, except for ipsecls, alogpls, cmdlls, tesrvls, clhls, xpuls' -a ruleData='regexp:^\b((?!ipsec)(?!alog)(?!cmdl)(?!tesrv)(?!clh)(?!xpu)).*ls$' $IMMFIND_RULE_17" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_17"
  apos_log "$IMMFIND_RULE_17 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_39
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_39" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_39"
  apos_log "$IMMFIND_RULE_39 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_42
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_42" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_42"
  apos_log "$IMMFIND_RULE_42 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_43
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_43" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_43"
  apos_log "$IMMFIND_RULE_43 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_44
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_44" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_44"
  apos_log "$IMMFIND_RULE_44 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_45
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_45" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_45"
  apos_log "$IMMFIND_RULE_45 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_46
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_46" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_46"
  apos_log "$IMMFIND_RULE_46 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_47
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_47" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_47"
  apos_log "$IMMFIND_RULE_47 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_48
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_48" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_48"
  apos_log "$IMMFIND_RULE_48 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_49
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_49" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_49"
  apos_log "$IMMFIND_RULE_49 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_50
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_50" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_50"
  apos_log "$IMMFIND_RULE_50 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_51
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_51" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_51"
  apos_log "$IMMFIND_RULE_51 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_52
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_52" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_52"
  apos_log "$IMMFIND_RULE_52 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_53
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_53" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_53"
  apos_log "$IMMFIND_RULE_53 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_54
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_54" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_54"
  apos_log "$IMMFIND_RULE_54 has been updated successfully"
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_CPROLE15_55
if [ $? -eq 0 ]; then
  kill_after_try 3 3 4 "$IMMCFG_CMD -a userLabel='Execute permission to some AP commands' -a ruleData='regexp:acease|alist|cmdlls|cpdtest|cqrhils|cqrhlls|crdls|misclhls|fixerls' $IMMFIND_RULE_CPROLE15_55" || apos_abort 1 "Failed to update userLabel attribute for $IMMFIND_RULE_CPROLE15_55"
  apos_log "$IMMFIND_RULE_CPROLE15_55 has been updated successfully"
fi

#END:DATA_REST

#END: Updation of Rules
#BEGIN: Removal of Rules

$IMMFIND_CMD | grep $IMMFIND_RULE_63
if [ $? -eq 0 ];then
  kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_63 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_63"
  apos_log "$IMMFIND_RULE_63 rule has been deleted successfully."
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_56 
if [ $? -eq 0 ];then
  kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_56 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_56"
  apos_log "$IMMFIND_RULE_56 rule has been deleted successfully."
fi

$IMMFIND_CMD | grep $IMMFIND_RULE_61
if [ $? -eq 0 ];then
  kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_61 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_61"
  apos_log "$IMMFIND_RULE_61 rule has been deleted successfully."
fi

#END: Removal of Rules
##Security Rules for 3.7 ##

#BEGIN: Deleting the rule to expose TLS MO under SECM for ldap user with role SystemSecurityAdministrator
$IMMFIND_CMD | grep $IMMFIND_RULE_TLS_1
if [ $? -eq 0 ];then
  kill_after_try 3 3 4 $IMMCFG_CMD -d $IMMFIND_RULE_TLS_1 || apos_abort 1 "Failed to delete the rule $IMMFIND_RULE_TLS_1"
  apos_log "$IMMFIND_RULE_TLS_1 rule has been deleted successfully."
fi
#END: Deleting the rule to expose TLS MO under SECM for ldap user with role SystemSecurityAdministrator

