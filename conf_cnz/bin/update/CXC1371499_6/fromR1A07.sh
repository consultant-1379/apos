#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A07.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Wed Apr 24 2017 - Neelam Kumar(xneelku)
# - Wed May 10 2017 - Yeshwanth Vankayala (xyesvan)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SSSD_CONF_FILE='/etc/sssd/sssd.conf'
NEWROW='case_sensitive = false'

##
# BEGIN: Disabling case sensitivity for LDAP
if ! grep -q '^[[:space:]]*case_sensitive[[:space:]]*=[[:space:]]*' $SSSD_CONF_FILE; then
  apos_log "adding \"$NEWROW\" to $SSSD_CONF_FILE..."
  sed -i "/\[domain\/LdapAuthenticationMethod\]/a ${NEWROW}" $SSSD_CONF_FILE || \
    apos_abort "failure while adding \"$NEWROW\" to $SSSD_CONF_FILE file"
  apos_log "done"
else
  apos_log "\"case_sensitive\" entry already present. Re-setting it to \"$NEWROW\" in $SSSD_CONF_FILE..."
  sed -r -i "s/^[[:space:]]*case_sensitive[[:space:]]*=[[:space:]]*.*/${NEWROW}/g" $SSSD_CONF_FILE || \
    apos_abort "failure while re-setting \"$NEWROW\" in $SSSD_CONF_FILE file"
  apos_log "done"
fi

# sssd restart to make the new rules effective
pushd $CFG_PATH &>/dev/null
apos_servicemgmt restart sssd.service &>/dev/null || \
  apos_abort "failure while restarting sssd.service"
popd &>/dev/null
# END: Disabling case sensitivity for LDAP
## 

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling
##


# R1A07 --> <next_revision>
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_6 R1A08 
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
