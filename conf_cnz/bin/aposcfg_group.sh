#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_group.sh
# Description:
#       A script to set the root group in the cluster.
# Note:
#	None.
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Fri May 19 2016 - Antonio Buonocunto (eanbuon)
#   Removed LAPH0 groups creation.
# - Thu Apr 28 2016 - Francesco Rainone (EFRARAI)
#   Impact in lockfile invocation for avoiding the creation of lockfile in
#   backed-up directory.
# - Fri Mar 4 2016 - Antonio Buonocunto (eanbuon)
#       Changes to wwwrun moved to aposcfg_appendgroup.sh.
# - Sat Feb 6 2016 - Antonio Buonocunto (eanbuon)
#       Adaptation to system-oam group.
# - Mon Jan 25 2016 - Antonio Nicoletti (eantnic)
#   	Rework for SLES12.
# - Mon Aug 24 2015 - Phaninder G (xphagat)
#	    TR HT99301 Fix
# - Mon Jun 29 2015 - Antonio Buonocunto (eanbuon)
#       Groups creation for LA PH0.
# - Wed Nov 14 2012 - Antonio Buonocunto (eanbuon)
#		com-ldap group handling added.
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#		Configuration scripts rework.
# - Mon Sep 05 2011 - Paolo Palmieri (epaopal)
#       Bugs correction.
# - Thu Jul 19 2011 - Paolo Palmieri (epaopal)
#       Definition of the APG FTP sites and related virtual directories.
# - Mon Mar 14 2011 - Francesco Rainone (efrarai)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Variables
FILE="/etc/group"

# Row search and replacement
if [ -f $FILE ]; then
  KEYWORD="root:"
  NEW_ROW="root:x:0:"
  if ! grep -q "^${NEW_ROW}" $FILE &>/dev/null; then
    if grep -q "^${KEYWORD}" $FILE &>/dev/null; then
      sed -i "s@^${KEYWORD}.*@${NEW_ROW}@g" $FILE		
      apos_log "group for root user set"
    else	
      echo -e "$NEW_ROW" >> $FILE
      apos_log "group for root user added"
    fi
  else
    apos_log "group for root user already present: skipping"
  fi
else
  apos_abort "file \"${FILE}\" not found!"
fi

apos_outro $0
exit $TRUE

# End of file
