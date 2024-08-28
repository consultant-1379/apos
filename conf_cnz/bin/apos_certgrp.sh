#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
#------------------------------------------------------------------------
##
# Name:
#       apos_certgrp.sh
# Description:
#        script to change the owner group of certificates folder to CERTGRP.
#
# Note:
#       None.
##
# Usage:
#       apos_certgrp.sh
##
# Output:
#       None.

#changelog:
#- Mon Apr 12 2022 -P S SOUMYA (zpsxsou)
#       Adding error handling scenarios
# - Tue Dec 21  2021 - P S SOUMYA (zpsxsou)
#       CERTGRP for certificates folder

. /opt/ap/apos/conf/apos_common.sh
apos_intro $0
apos_log "Searching the sec-cert.sh file in given path"
SEC_CERT_PATH=$(find /opt/eric -mindepth 3 -maxdepth 3 -iname "sec-cert.sh" 2>/dev/null)
if [ -n "$SEC_CERT_PATH" ]; then
   sed -i '/SEC_CERTM_LOCAL_FILE_STORE/ s/system-nbi-data/CERTGRP/g' $SEC_CERT_PATH 2>/dev/null
   if [ $? -ne 0 ]; then
      apos_abort "Failed to update nbi path in $SEC_CERT_PATH"
   else
      apos_log "sucessfully update nbi path in $SEC_CERT_PATH"
   fi

else
     apos_abort "$SEC_CERT_PATH not found!"
fi
apos_outro $0
exit $TRUE

