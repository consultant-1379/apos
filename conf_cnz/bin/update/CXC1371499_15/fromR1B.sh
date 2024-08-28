#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1B.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Tue 12 Apr - P S SOUMYA (zpsxsou)
#        First Version
# Mon 06 Apr - SOWJANYA MEDAK (xsowmed)
#        First Version
# Fri 01 Apr - Rajeshwari Padavala (xcsrpad)
#        Support for Chrony feature
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"
CMD_CLUSTER_CONF="/opt/ap/apos/bin/clusterconf/clusterconf"
CLUS_MGMT_OPTS="mgmt --cluster"
lcc_name="/usr/bin/cluster"
CMD_HWTYPE='/opt/ap/apos/conf/apos_hwtype.sh'
CMD_GREP=/usr/bin/grep
CMD_AWK=/usr/bin/awk
TELNET_PORTS=("23" "4423" "5000" "5001" "5002" "5010" "5011" "5100" "5101" "5110" "5111")

# Function to configure chrony 
function configure_chrony() {
if is_vAPG; then
  LIST_OF_FILES='/usr/lib/lde/config-management/apos_ntp-config
                 /usr/lib/lde/config-management/apos_rp-hosts-config'

  for file in $LIST_OF_FILES; do 

    ./apos_deploy.sh --from "$SRC/$file" --to $file || apos_abort "failure while deploying $file file"

    # remove symlink of old one 
    rm -f /usr/lib/lde/config-management/config/C620apos_ntp 
    
    # creeate symlink 
    ./apos_insserv.sh $file || apos_abort "Failure while creating symlink to file $file"
 
    # reload config to update ntp-config
    $file config reload  
    if [ $? -ne 0 ]; then
      apos_abort "Failure while executing $file"
    fi
  done

  popd &> /dev/null

fi
}

# Function to delete the TELNET related iptables not used anymore 
function remove_telnet_rules() {
	apos_log "Deleting rules for telnet and mts insecure protocol"
	for PORT in "${TELNET_PORTS[@]}"
	do
	    NoOfRules=`${CMD_CLUSTER_CONF} iptables -D |${CMD_GREP} "tcp \-\-dport $PORT" | wc -l`
	    apos_log "There are $NoOfRules rules for telnet port $PORT"
	    for (( j=1;j<=$NoOfRules;j++))
	    do
	        Rule=$( ${CMD_CLUSTER_CONF} iptables -D |${CMD_GREP} "tcp \-\-dport $PORT" | ${CMD_AWK} '{print $1}' | head -1)
	        ${CMD_CLUSTER_CONF} iptables --m_delete $Rule &>/dev/null
	        if [ $? -ne 0 ]; then
	           apos_log "Delete telnet rule failed or no rule present"
	        fi
	    done
	done

#Verify cluster configuration is OK
$CMD_CLUSTER_CONF $CLUS_MGMT_OPTS --verify &> /dev/null
if [ $? -ne 0 ]; then
   # Something wrong. Fallback with older cluster config
   $CMD_CLUSTER_CONF $CLUS_MGMT_OPTS --abort
   apos_abort "Cluster management verification failed"
fi
# Verify seems to be OK. Reload the cluster now.
$CMD_CLUSTER_CONF $CLUS_MGMT_OPTS --reload --verbose &>/dev/null
if [ $? -ne 0 ]; then
   # Something wrong in reload. Fallback on older cluster config
   $CMD_CLUSTER_CONF $CLUS_MGMT_OPTS --abort
   apos_abort "Cluster management reload failed"
fi
# Things seems to be OK so-far. Commit cluster configuration now.
$CMD_CLUSTER_CONF $CLUS_MGMT_OPTS --commit &>/dev/null
if [ $? -ne 0 ]; then
   # Commit should not fail, as it involves only removing the
   # back up file. anyway bail-out?
   apos_abort "Cluster Management commit failed"
fi
# iptables restart to make the new rules effective

apos_servicemgmt restart lde-iptables.service &>/dev/null 
if [ $? -ne 0 ]; then
   apos_abort "failure while reloading iptables rules"
fi
   apos_log "telnet rules delete success"

}

# Main

pushd $CFG_PATH &> /dev/null

# Removal of TELNET-related IP Table rules
remove_telnet_rules
configure_chrony
popd &> /dev/null

HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
SRC="/opt/ap/apos/etc/deploy"
BASEFILE="/usr/lib/systemd/scripts/apos-system-conf.sh"

# BEGIN: Deploy
if [ "$HW_TYPE" == 'VM' ]; then
  pushd $CFG_PATH &> /dev/null
  ./apos_deploy.sh --from "${SRC}/${BASEFILE}" --to "${BASEFILE}"
  if [ $? -ne $TRUE ]; then
    apos_abort "failure while deploying ${BASEFILE}"
  fi
  popd &>/dev/null
fi
# END: Deploy 
##

# R1B -> R1C
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_15 R1C
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

