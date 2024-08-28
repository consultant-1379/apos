#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_common-password.sh
# Description:
#       A script to configure /etc/pam.d/common-password file.
# Note:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Fri Feb 05 2016 - Alessio Cascone (EALOCAE)
#	Implemented changed to adapt to new SEC ACS component.
# - Thu Oct 10 2013 - Francesco Rainone (efrarai)
#	Moved to deploy.sh approach.
# - Mon Sep 30 2013 - C Greeshmalatha (xgrecha)
#	Addressed TR HR33409.
# - Wed Jan 02 2013 - Salvatore Delle Donne (teisdel)
#	Cracklib settings updated.
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
PAM_PASSWORD_FILENAME="acs-apg-password-local"
PAM_PASSWORD_FILE="$PAM_CONF_FOLDER/$PAM_PASSWORD_FILENAME"
ACS_COMMON_PASSWORD_LOCAL_LINK="acs-common-password-local"

pushd $APOS_CONF_FOLDER >/dev/null
if [ -x ./apos_deploy.sh ]; then
	./apos_deploy.sh --from "$SRC/$PAM_PASSWORD_FILE" --to "/$PAM_PASSWORD_FILE" || apos_abort "failure while deploying /$PAM_PASSWORD_FILE"
else
	apos_abort "apos_deploy.sh not found or not executable"
fi
popd >/dev/null

pushd /$PAM_CONF_FOLDER >/dev/null
ln -sf $PAM_PASSWORD_FILENAME $ACS_COMMON_PASSWORD_LOCAL_LINK || apos_abort "Failure to link APG PAM password configuration"
popd >/dev/null

apos_outro $0
exit $TRUE

# End of file
