#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2023 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      changing_umask_value.sh
#
# Changelog:
# - Aug 29 2023 - Pravalika P (ZPRAPXX)
#    - Improving the logic to handle all negative scenarios 
# - Aug 03 2023 - Pravalika P (ZPRAPXX)
#    - Improving the logic to handle all negative scenarios 
# - May 17 2023 - Pravalika P (ZPRAPXX)
#    -updating umask value in bash.bashrc.local and profile.local files
#    -This logic is taken from LDE script /usr/lib/lde/hardening/lde-user-hardening.sh (-u option)
##
##
. /opt/ap/apos/conf/apos_common.sh
apos_intro $0

# Common variables
CFG_PATH="/opt/ap/apos/conf"
LOGIN_DEFS="/etc/login.defs"
BASHRC_LOCAL="/etc/bash.bashrc.local"
PROFILE_LOCAL="/etc/profile.local"

apos_log 'OSCONF:Fetching the umask value from login.defs file and updating in /etc/bash.bashrc.local and /etc/profile.local files'

#This below code has been taken from /usr/lib/lde/hardening/lde-user-hardening.sh (-u option)
# Propagate umask to CIS-CAT scanned files
HEADING1="# Make umask visible in CIS-CAT scanned file"
HEADING2="# Actual system umask in use is defined in $LOGIN_DEFS"
UMASK=""
UMASK=$(grep '^\s*UMASK' $LOGIN_DEFS | tr '[:upper:]' '[:lower:]')


if ! grep -q "$UMASK" $PROFILE_LOCAL ; then

  if ! grep -q '^\s*umask' $PROFILE_LOCAL ; then
    echo -e "\n$HEADING1\n$HEADING2\n$UMASK" >> $PROFILE_LOCAL
    [[ $? -eq 0 ]] && apos_log "OSCONF:Successfully updated $UMASK in profile.local file"
  else
    sed -i "s/^umask.*/$UMASK/g" $PROFILE_LOCAL
    [[ $? -eq 0 ]] && apos_log "OSCONF:Successfully updated $UMASK in profile.local file"
  fi

fi

if ! grep -q "$UMASK" $BASHRC_LOCAL ; then

  if ! grep -q '^\s*umask' $BASHRC_LOCAL ; then
    echo -e "\n$HEADING1\n$HEADING2\n$UMASK" >> $BASHRC_LOCAL
    [[ $? -eq 0 ]] && apos_log "OSCONF:Successfully updated $UMASK in bash.bashrc.local file"
  else
    sed -i "s/^umask.*/$UMASK/g" $BASHRC_LOCAL
    [[ $? -eq 0 ]] && apos_log "OSCONF:Successfully updated $UMASK in bash.bashrc.local file"
  fi

fi


apos_outro $0
exit $TRUE

