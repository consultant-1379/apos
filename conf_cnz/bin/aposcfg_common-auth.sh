#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_common-auth.sh
# Description:
#       A script to configure /etc/pam.d/common-auth file.
# Note:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Wed Jan 03 2018 - Swetha Rambhathini
#   add auth-role2group
# - Thu Feb 08 2016 - Akkij Darvajkar (xakkdar)
#       Symbolic link for LA phase 1
# - Fri Feb 05 2016 - Alessio Cascone (EALOCAE)
#	Implemented changed to adapt to new SEC ACS component.
# - Mon May 13 2013 - Krishna Chaitanya (xchakri)
#	Rework to handle user story
#	The tsadmin user has a 5 second delay for each failed login
#	The locktime for tsadmin was set to 5 minutes after 3 failed logins
# - Tue May 08 2012 - Fabio Ronca (efabron)
#	Configuration scripts rework.
# - Tue Jan 31 2012 - Satya Deepthi Gopisetti (xsatdee)
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
PAM_AUTH_FAILURE_FILENAME="acs-apg-auth-failure"
PAM_AUTH_FAILURE_FILE="$PAM_CONF_FOLDER/$PAM_AUTH_FAILURE_FILENAME"
PAM_AUTH_SUCCESS_FILENAME="acs-apg-auth-success"
PAM_AUTH_SUCCESS_FILE="$PAM_CONF_FOLDER/$PAM_AUTH_SUCCESS_FILENAME"
ACS_COMMON_AUTH_SUCCESS_LINK="acs-common-auth-success"
ACS_COMMON_AUTH_FAILURE_LINK="acs-common-auth-failure"
APG_LOCKOUT_TSADMIN_FILENAME="acs-apg-lockout-tsadmin"
APG_LOCKOUT_TSADMIN_FILE="$PAM_CONF_FOLDER/$APG_LOCKOUT_TSADMIN_FILENAME"
APG_LOCKOUT_TSGROUP_FILENAME="acs-apg-lockout-tsgroup"
APG_LOCKOUT_TSGROUP_FILE="$PAM_CONF_FOLDER/$APG_LOCKOUT_TSGROUP_FILENAME"
APG_COMMON_BANNER_FILENAME="acs-apg-common-banner"
APG_COMMON_BANNER_FILE="$PAM_CONF_FOLDER/$APG_COMMON_BANNER_FILENAME"
ACS_COMMON_AUTH_HEADING_LINK="acs-common-auth-heading"
APG_COMMON_AUTH_ROLE2GROUP_FILENAME="acs-apg-auth-role2group"
APG_COMMON_AUTH_ROLE2GROUP_FILE="$PAM_CONF_FOLDER/$APG_COMMON_AUTH_ROLE2GROUP_FILENAME"
ACS_COMMON_AUTH_ROLE2GROUP_LINK="acs-common-auth-role2group"

pushd $APOS_CONF_FOLDER >/dev/null
if [ -x ./apos_deploy.sh ]; then
	./apos_deploy.sh --from "$SRC/$PAM_AUTH_FAILURE_FILE" --to "/$PAM_AUTH_FAILURE_FILE" || apos_abort "failure while deploying /$PAM_AUTH_FAILURE_FILE" 
	./apos_deploy.sh --from "$SRC/$PAM_AUTH_SUCCESS_FILE" --to "/$PAM_AUTH_SUCCESS_FILE" || apos_abort "failure while deploying /$PAM_AUTH_SUCCESS_FILE" 
	./apos_deploy.sh --from "$SRC/$APG_LOCKOUT_TSADMIN_FILE" --to "/$APG_LOCKOUT_TSADMIN_FILE" || apos_abort "failure while deploying /$APG_LOCKOUT_TSADMIN_FILE" 
	./apos_deploy.sh --from "$SRC/$APG_LOCKOUT_TSGROUP_FILE" --to "/$APG_LOCKOUT_TSGROUP_FILE" || apos_abort "failure while deploying /$APG_LOCKOUT_TSGROUP_FILE" 
	./apos_deploy.sh --from "$SRC/$APG_COMMON_BANNER_FILE" --to "/$APG_COMMON_BANNER_FILE" || apos_abort "failure while deploying /$APG_COMMON_BANNER_FILE" 
	./apos_deploy.sh --from "$SRC/$APG_COMMON_AUTH_ROLE2GROUP_FILE" --to "/$APG_COMMON_AUTH_ROLE2GROUP_FILE" || apos_abort "failure while deploying /$APG_COMMON_AUTH_ROLE2GROUP_FILE" 
else
	apos_abort "apos_deploy.sh not found or not executable"
fi
popd >/dev/null

pushd /$PAM_CONF_FOLDER >/dev/null
ln -sf $PAM_AUTH_FAILURE_FILENAME $ACS_COMMON_AUTH_FAILURE_LINK || apos_abort "Failure to link APG PAM auth-success configuration"
ln -sf $PAM_AUTH_SUCCESS_FILENAME $ACS_COMMON_AUTH_SUCCESS_LINK || apos_abort "Failure to link APG PAM auth-failure configuration"
ln -sf $APG_COMMON_BANNER_FILENAME $ACS_COMMON_AUTH_HEADING_LINK || apos_abort "Failure to link APG PAM auth-heading configuration"
ln -sf $APG_COMMON_AUTH_ROLE2GROUP_FILENAME $ACS_COMMON_AUTH_ROLE2GROUP_LINK || apos_abort "Failure to link APG PAM auth-role2group configuration"
popd >/dev/null

apos_outro $0
exit $TRUE

# End of file

