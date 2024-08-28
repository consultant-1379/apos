#!/bin/bash 
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# prepare_osext_rpms.sh
# A script to prepare rpms folder for APOS OSEXTBIN component.
##
# Usage:
#	prepare_osext_rpms.sh 
#	
# Output:
# Folder .../apos/3pp_cnz/3pp_cxc/packages/rpms will be populated with all 3pp rpm 
# packages needed for building OSEXTBIN sdp. Updated list of rpms is assumed to be 
# in .../apos/3pp_cnz/sles/rpms_in_apos.txt. File libACE*.rpm should already be in 
# .../packages/rpms folder when this script is invoked. 
# File .../3pp_cnz/OSEXTBIN_info.txt is copied in .../packages/rpms folder too.
# File openssh*.rpm is copied from .../openssh/openssh_cxc/packages/rpm.
# Changelog:
# - Mon Mar 05 2018 - Gianluca Santoro (eginsan)
#	First version.

APOS_ROOT="$1"
CNZDIR=${APOS_ROOT}/ext_cnz
CXCDIR=$CNZDIR/ext_cxc
SLESDIR=$CNZDIR/sles
RPMDIR=$CXCDIR/packages/rpm
SSHRPMDIR=$CNZDIR/openssh/openssh_cxc/packages/rpm
INFOFILE=OSEXTBIN_info.txt
RPMLIST=$SLESDIR/rpms_in_apos.txt

# clean RPMDIR except *libACE* files
LIST=$(ls $RPMDIR) 
for i in $LIST; do 
  [[ "$i" != *libACE* ]] && rm -f $RPMDIR/$i 
done

# copy OSEXTBIN_info.txt to RPMDIR 
if [ -f $CNZDIR/$INFOFILE ]; then
  rm -f $RPMDIR/$INFOFILE 2>&1 > /dev/null
  cp $CNZDIR/$INFOFILE $CXCDIR/packages/rpm 2>&1 > /dev/null
else 
  exit $INFOFILE copy failure 
fi
# copy all needed rpm to RPMDIR except *libACE*.rpm 
LIST=$(cat $RPMLIST) 
for i in $LIST; do 
  if [[ "$i" == openssh*.rpm ]]; then
    cp $SSHRPMDIR/$i $RPMDIR
    [[ $? -ne 0 ]] && exit $RPM copy openssh failure 
  else 
    RPM=$(ls $SLESDIR/pkgs/$i) 
    if [ ! -z $RPM ]; then 
      cp $RPM $RPMDIR 
      [[ $? -ne 0 ]] && exit $RPM copy failure 
    fi
  fi
done

