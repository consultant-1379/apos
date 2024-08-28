#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A01.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
##Mon 02 Jun - P S SOUMYA (zpsxsou)
##         First Version
# Load the apos common functions.

. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
SRC_ETC_DEPLOY='/opt/ap/apos/etc/deploy'
SYSLOG_PATH=$(</etc/syslog-logstream.d)
SYSLOG_CONFIG_TEMPLATE="/usr/lib/lde/syslog-config/templates/rsyslog"
NODE_APOS_CONFIG_PATH="/opt/ap/apos/conf"
SRC_APG_RSYS_RULE=/opt/ap/apos/etc/deploy/etc/10-apg-rsyslog-rule
ETC_APG_RSYS_RULE=/etc/logrot.d/10-apg-rsyslog-rule
CONF_DIR='/opt/ap/apos/conf'
CFG_PATH='/opt/ap/apos/conf'


pushd $CFG_PATH &>/dev/null
if [ -f $SYSLOG_CONFIG_TEMPLATE/lde-rsyslog-global-template.conf ] ; then
/usr/bin/cp $NODE_APOS_CONFIG_PATH/apg_rsyslog_global_template.conf $SYSLOG_CONFIG_TEMPLATE/lde-rsyslog-global-template.conf
else
apos_abort 'lde-rsyslog-global-template.conf file not found'
fi
if  [ -f $SYSLOG_CONFIG_TEMPLATE/lde-log-stream-template.conf ] ; then
        /usr/bin/cp $NODE_APOS_CONFIG_PATH/apg-log-stream-template.conf $SYSLOG_CONFIG_TEMPLATE/lde-log-stream-template.conf
else
    apos_abort 'apg-log-stream-template.conf file not found'
fi

popd &>/dev/null
#apos_log 'entering to restart syslog service'
sleep 5
#apos_servicemgmt restart rsyslog.service &>/dev/null || apos_log 'failure while restarting syslog service'

#Deploying APG customized rule for logrotation
pushd $CFG_PATH &>/dev/null
if [ -r "${SRC_APG_RSYS_RULE}" ]; then
apos_log 'copying 10-apg-rsyslog-rule file'
${CONF_DIR}/apos_deploy.sh --from "${SRC_APG_RSYS_RULE}" --to "${ETC_APG_RSYS_RULE}"
if [ $? -ne 0 ]; then
apos_abort "failure when deploying ${SRC_APG_RSYS_RULE} to ${ETC_APG_RSYS_RULE}"
fi
fi
popd &>/dev/null
# restart logrotd service
apos_log 'Restarting lde-logrot service'
apos_servicemgmt restart lde-logrot.service &> /dev/null || apos_abort "failure while restarting lde-logrot service"
pushd $CFG_PATH &>/dev/null
if [ -x "$SYSLOG_PATH"]; then
    apos_log 'Syslog Copying 02-lde-syslog-logstream-list.conf file'
    ./apos_deploy.sh --from "$SRC_ETC_DEPLOY/etc/02-lde-syslog-logstream-list.conf" --to "/etc/syslog-logstream.d/02-lde-syslog-logstream-list.conf"
else
      apos_abort "$SYSLOG_PATH not found!"
fi
popd &>/dev/null

/usr/bin/cmw-utility immcfg -c Rule -a userLabel="Access permissions to mml_audit logstream in the class LogM" -a permission=7 -a ruleData=ManagedElement,SystemFunctions,LogM,Log=mml_audit,*  ruleId=LdeLogManagement_7,roleId=SystemSecurityAdministrator,localAuthorizationMethodId=1
if [ $? -ne 0 ]; then
  apos_log "Not able to create rule for mml_audit file"
fi

# R1A01 -> R1A02
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_16 R1A02
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE
