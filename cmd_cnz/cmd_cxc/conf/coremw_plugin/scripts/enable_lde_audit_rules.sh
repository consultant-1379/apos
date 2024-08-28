#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2023 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      enable_lde_audit_rules.sh
#
# Changelog:
# - Apr 27 2023 - Pravalika P (ZPRAPXX)
#    - Enabling lde audit rules during MI
##
##
. /opt/ap/apos/conf/apos_common.sh
apos_intro $0

# Common variables
CFG_PATH="/opt/ap/apos/conf"
  
  apos_log 'Re-loading audit rules after the addition of new audit rules by LDE'
  pushd $CFG_PATH &> /dev/null

  apos_check_and_call $CFG_PATH aposcfg_audit-rules.sh

  popd &> /dev/null

apos_outro $0
exit $TRUE


