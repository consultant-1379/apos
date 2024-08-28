#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_common-account.sh
# Description:
#       A script to configure /etc/pam.d/common-account file.
# Note:
#	None.
##
# Output:
#       None.
##
# Changelog:
# 
# - Fri Feb 05 2016 - Alessio Cascone (EALOCAE)
#	Implemented changed to adapt to new SEC ACS component.
# - Tue Sept 04 2012 - Salvatore Delle Donne (teisdel)
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
PAM_ACCOUNT_FAILURE_FILENAME="acs-apg-account-failure"
PAM_ACCOUNT_FAILURE_FILE="$PAM_CONF_FOLDER/$PAM_ACCOUNT_FAILURE_FILENAME"
PAM_ACCOUNT_SUCCESS_FILENAME="acs-apg-account-success"
PAM_ACCOUNT_SUCCESS_FILE="$PAM_CONF_FOLDER/$PAM_ACCOUNT_SUCCESS_FILENAME"
ACS_COMMON_ACCOUNT_SUCCESS_LINK="acs-common-account-success"
ACS_COMMON_ACCOUNT_FAILURE_LINK="acs-common-account-failure"

pushd $APOS_CONF_FOLDER >/dev/null
if [ -x ./apos_deploy.sh ]; then
	./apos_deploy.sh --from "$SRC/$PAM_ACCOUNT_FAILURE_FILE" --to "/$PAM_ACCOUNT_FAILURE_FILE" || apos_abort "failure while deploying /$PAM_ACCOUNT_FAILURE_FILE" 
	./apos_deploy.sh --from "$SRC/$PAM_ACCOUNT_SUCCESS_FILE" --to "/$PAM_ACCOUNT_SUCCESS_FILE" || apos_abort "failure while deploying /$PAM_ACCOUNT_SUCCESS_FILE" 
else
	apos_abort "apos_deploy.sh not found or not executable"
fi
popd >/dev/null

pushd /$PAM_CONF_FOLDER >/dev/null
ln -sf $PAM_ACCOUNT_FAILURE_FILENAME $ACS_COMMON_ACCOUNT_FAILURE_LINK || apos_abort "Failure to link APG PAM account-success configuration"
ln -sf $PAM_ACCOUNT_SUCCESS_FILENAME $ACS_COMMON_ACCOUNT_SUCCESS_LINK || apos_abort "Failure to link APG PAM account-failure configuration"
popd >/dev/null

apos_outro $0
exit $TRUE

# End of file

