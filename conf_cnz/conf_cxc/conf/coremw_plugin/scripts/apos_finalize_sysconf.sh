#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_finalize_sysconf.sh
# Description:
#       A script to start apos-finalize-system-config.service
# Note:
#       Invoked by apos_conf plugin on both the Nodes of vAPG.
##
# Usage:
#       Used during vAPG maiden installation.
##
# Output:
#       None.
##
# Changelog:
# - Tue Oct 2 2018 - Pratap Reddy Uppada (XPRAUPP)
#   Rework to use existing functions
# - Thu Aug 9 2018 - Pranshu Sinha (XPRANSI)
#   First version.


# In case of MI, installation_type parameter is set to MI and configuration
# changes will be skipped. Where as installation_type parameter is not
# set on virtual and configuration settings are applied.
installation_type=$(cat /cluster/mi/installation/installation_type 2>/dev/null)
if [[ -n "$installation_type" && "$installation_type" == 'MI' ]]; then
  echo -e 'Skipping configuration changes, not applicable on Native!'
	exit 0
fi

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

if is_vAPG ; then
  /usr/bin/systemctl start apos-finalize-system-config.service
  if [ $? -ne 0 ]; then
    apos_abort "Failed to start apos-finalize-system-config.service"
  fi

  # Idle time 
  sleep 5

  if [ -x /opt/ap/acs/bin/cs_hidemodel.sh ]; then 
    /opt/ap/acs/bin/cs_hidemodel.sh || apos_abort 1 'cs_hidemodel.sh execution failed'
  else
    apos_abort 1 'cs_hidemodel.sh script not found'
  fi 
fi

apos_outro $0
exit $TRUE
