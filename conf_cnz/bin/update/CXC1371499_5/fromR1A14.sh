#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A14.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#	None.
##
# Changelog:
# - Fri Jul 08 2016 - Alessio Cascone (ealocae)
#	Added invokation of apos_iptables.sh   
# - Thu Jun 30 2016 - Antonio Buonocunto (EANBUON)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
CFG_PATH="/opt/ap/apos/conf"
SRC='/opt/ap/apos/etc/deploy'

# Function to delete the CPS-related iptables not used anymore 
function remove_cps_rules() {
local CLUSTER_CONF_CMD='/opt/ap/apos/bin/clusterconf/clusterconf'
local RULES_CPS=(
	"all -A INPUT -p tcp --dport 23 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 23 -m state --state NEW -j DROP"
	"all -A INPUT -p tcp --dport 4423 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 4423 -m state --state NEW -j DROP"
	"all -A INPUT -p tcp --dport 5000 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 5000 -m state --state NEW -j DROP"
	"all -A INPUT -p tcp --dport 5001 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 5001 -m state --state NEW -j DROP"
	"all -A INPUT -p tcp --dport 5002 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 5002 -m state --state NEW -j DROP"
	"all -A INPUT -p tcp --dport 5010 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 5010 -m state --state NEW -j DROP"
	"all -A INPUT -p tcp --dport 5011 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 5011 -m state --state NEW -j DROP"
	"all -A INPUT -p tcp --dport 5100 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 5100 -m state --state NEW -j DROP"
	"all -A INPUT -p tcp --dport 5101 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 5101 -m state --state NEW -j DROP"
	"all -A INPUT -p tcp --dport 5110 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 5110 -m state --state NEW -j DROP"
	"all -A INPUT -p tcp --dport 5111 -m state --state NEW -m limit --limit 160/second --limit-burst 1 -j ACCEPT"
	"all -A INPUT -p tcp --dport 5111 -m state --state NEW -j DROP"
	)

  SOMETHING_CHANGED=$FALSE
  for RULE in "${RULES_CPS[@]}"; do
    RULE_ID=$(${CLUSTER_CONF_CMD} iptables --display | grep "$RULE" | awk -F ' ' '{print $1}')
    if [ -n "$RULE_ID" ]; then
      ${CLUSTER_CONF_CMD} iptables --m_delete $RULE_ID
      if [ $? -ne 0 ]; then
        apos_log "WARNING: Failed to delete the following rule: \"$RULE\""
      else
        SOMETHING_CHANGED=$TRUE
      fi
    else
      apos_log "WARNING: Rule not found: \"$RULE\""
    fi
  done
	
  # Reload cluster configuration to apply removal
  if [ $SOMETHING_CHANGED -eq $TRUE ]; then
    cluster config -r -a || apos_abort "Failed to reload cluster configuration."
  fi

  # iptables restart to make the new rules effective
  apos_servicemgmt restart lde-iptables.service &>/dev/null || apos_abort "failure while reloading iptables rules"
}


# Main

pushd $CFG_PATH &> /dev/null

# /etc/pam.d/common-session file set up
apos_check_and_call $CFG_PATH aposcfg_common-session.sh

##
# BEGIN: NEW apos_sshd-config
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_sshd-config" --to "/usr/lib/lde/config-management/apos_sshd-config" || apos_abort "failure while deploying apos_sshd-config file"
./apos_insserv.sh /usr/lib/lde/config-management/apos_sshd-config || apos_abort "failure while creating apos_sshd-config file symlink"

/usr/lib/lde/config-management/apos_sshd-config config init
if [ $? -ne 0 ];then
  apos_abort "Failure while executing apos_sshd-config"
fi
# END: NEW apos_sshd-config
##

# Removal of CPS-related IP Table rules
remove_cps_rules

# iptables configuration
apos_check_and_exlocall $CFG_PATH apos_iptables.sh

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

# R1A14 -> R1A15
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1A15
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
