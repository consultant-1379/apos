#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_common-session.sh
# Description:
#       A script to configure /etc/pam.d/acs-common-session-* files
# Note:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Thu Feb 04 2016 - Alessio Cascone (EALOCAE)
#	First version.
##
 
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
TRUE=$( true; echo $? )
FALSE=$( false; echo $? )

# Source paths 
SRC='/opt/ap/apos/etc/deploy'
APOS_CONF_FOLDER="/opt/ap/apos/conf/"
PAM_CONF_FOLDER="etc/pam.d"

# Config files
PAM_SESSION_HEADING_FILENAME="acs-apg-session-heading"
PAM_SESSION_HEADING_FILE="$PAM_CONF_FOLDER/$PAM_SESSION_HEADING_FILENAME"
PAM_SESSION_SUCCESS_FILENAME="acs-apg-session-success"
PAM_SESSION_SUCCESS_FILE="$PAM_CONF_FOLDER/$PAM_SESSION_SUCCESS_FILENAME"
ACS_COMMON_SESSION_HEADING_LINK="acs-common-session-heading"
ACS_COMMON_SESSION_SUCCESS_LINK="acs-common-session-success"

pushd $APOS_CONF_FOLDER >/dev/null
if [ -x ./apos_deploy.sh ]; then
	./apos_deploy.sh --from "$SRC/$PAM_SESSION_HEADING_FILE" --to "/$PAM_SESSION_HEADING_FILE" || apos_abort "failure while deploying /$PAM_SESSION_HEADING_FILE"
	./apos_deploy.sh --from "$SRC/$PAM_SESSION_SUCCESS_FILE" --to "/$PAM_SESSION_SUCCESS_FILE" || apos_abort "failure while deploying /$PAM_SESSION_SUCCESS_FILE"
else
	apos_abort "apos_deploy.sh not found or not executable"
fi
popd >/dev/null

pushd /$PAM_CONF_FOLDER >/dev/null
ln -sf $PAM_SESSION_HEADING_FILENAME $ACS_COMMON_SESSION_HEADING_LINK || apos_abort "Failure to link APG PAM session-heading configuration"
ln -sf $PAM_SESSION_SUCCESS_FILENAME $ACS_COMMON_SESSION_SUCCESS_LINK || apos_abort "Failure to link APG PAM session-success configuration"
popd >/dev/null

##
# WORKAROUND: BEGIN
# DESCRIPTION: Please remove the following lines when the solution for HU75009 will be delivered by SEC.
pushd /$PAM_CONF_FOLDER >/dev/null

SEC_ACS_TEMPLATES_PATH="/opt/eric/sec-acs-cxp9026450/etc"
SEC_ACS_COMMON_SESSION_FILENAME="common-session-acs"
SEC_ACS_COMMON_SESSION_TEMPLATE_FILE="$SEC_ACS_TEMPLATES_PATH/$SEC_ACS_COMMON_SESSION_FILENAME"
SEC_ACS_COMMON_SESSION_FILE="/$PAM_CONF_FOLDER/$SEC_ACS_COMMON_SESSION_FILENAME"

apos_log "WORKAROUND: Patching '$SEC_ACS_COMMON_SESSION_TEMPLATE_FILE' PAM stack file..."
sed -i -r 's/(^session[[:space:]]+optional[[:space:]]+pam_systemd\.so)/#\1/g' $SEC_ACS_COMMON_SESSION_TEMPLATE_FILE 

apos_log "WORKAROUND: Delivering '$SEC_ACS_COMMON_SESSION_TEMPLATE_FILE' patched file..."
cp -f $SEC_ACS_COMMON_SESSION_TEMPLATE_FILE $SEC_ACS_COMMON_SESSION_FILE || apos_abort "Failure to patch the SEC-ACS common-account file" 

popd >/dev/null
# WORKAROUND: END
## 

apos_outro $0
exit $TRUE

# End of file

