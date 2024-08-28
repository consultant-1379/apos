#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A15.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Fri Jul 26 2016 - Alessio Cascone (ealocae)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
CFG_PATH="/opt/ap/apos/conf"
CACHE_DURATION=$(apos_get_cached_creds_duration)
SYNCD_CONF='/etc/syncd.conf'

if [ $CACHE_DURATION -ne 0 ]; then
  PATTERN='[[:space:]]*description[[:space:]]*=[[:space:]]*\"APG[[:space:]]cache_LdapAuthenticationMethod\.ldb\"'
  OUT_FILE=$(/usr/bin/mktemp -t ${APOS_APP_NAME}.output.XXX)
  TMP_FILE=$(/usr/bin/mktemp -t ${APOS_APP_NAME}.working.XXX)
  
  # Loop over all the file {} sections
  for INDEX in $(/usr/bin/sed -r -n '/file[[:space:]]*\{/ {=;}' $SYNCD_CONF | /usr/bin/sort -n)
  do
    # Extract the file {} section from the syncd configuration file
    /usr/bin/sed -n "${INDEX},/\}/ p" $SYNCD_CONF > $TMP_FILE

    # If the pattern doesn't match, add the entry to the output file
    if ! /usr/bin/grep -q "$PATTERN" $TMP_FILE ; then
      /usr/bin/echo -e "\n$(/usr/bin/cat $TMP_FILE)\n" >> $OUT_FILE
    fi
  done
  
  # Copy the content of the temporary output file into the syncd 
  /usr/bin/cp -f $OUT_FILE $SYNCD_CONF 
  /usr/bin/rm -f $TMP_FILE $OUT_FILE  
  apos_servicemgmt restart lde-syncd.service &> /dev/null || apos_abort "failure while restarting lde-syncd daemon"
fi

pushd $CFG_PATH &> /dev/null
# BEGIN: New apos_comconf.sh
if [ -x $CFG_PATH/apos_comconf.sh ]; then
  ./apos_comconf.sh
  if [ $? -ne 0 ]; then
    apos_abort 1 "\"apos_comconf.sh\" exited with non-zero return code"
  fi
else
  apos_abort 1 'apos_comconf.sh not found or not executable'
fi
# END: New apos_comconf.sh
##
popd &> /dev/null

# R1A15 -> R1A16
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1A16
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
