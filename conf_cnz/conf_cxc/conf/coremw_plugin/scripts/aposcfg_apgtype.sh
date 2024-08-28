#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_apgtype.sh
# Description:
#       A script to configure type attribute to "APG".
##
# Changelog:
#  TUE 22 MAY 2018 - XSRAVAN

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0


#fetch the swVersionMainId,swVersionId
sw_version_dn=$(immfind | grep -i swVersionId | grep -i id=administrativeData)
sw_version_main_dn=$(immfind | grep -i swVersionMainId | grep -i id=administrativeData)

immcfg -a type="APG" $sw_version_dn
if [ $? -ne 0 ]; then
  apos_log "ERROR:Failed to set type attribute for object [$sw_version_dn]"
  exit 1
fi

immcfg -a type="APG" $sw_version_main_dn
if [ $? -ne 0 ]; then
  apos_log "ERROR:Failed to set type attribute for object [$sw_version_main_dn]"
  exit 1
fi

apos_outro $0
exit $TRUE

# End of file
