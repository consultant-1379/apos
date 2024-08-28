#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_preinstall.sh
# Description:
#       A script to update configuration parameters in APOS PSO
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
#   First version.

# If installation_type is MI, then installtion is happening in Native
# installation_type parameter is not available on virtual 
installation_type=$(cat /cluster/mi/installation/installation_type 2>/dev/null)
if [[ -n "$installation_type" && "$installation_type" == 'MI' ]]; then 
  /bin/logger 'apos_preinstall: Skipping configuration changes, not applicable on Native!'
  exit 0
fi 

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

if is_vAPG ; then
  update_pso_params

  # Populate ip version type in APOS storage Type
  # Supported values are 4,6 and dual
  populate_apg_protocol_version_type
fi

apos_outro $0

exit $TRUE
