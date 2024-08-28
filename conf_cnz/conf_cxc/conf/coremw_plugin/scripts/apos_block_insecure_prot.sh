#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2020 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_block_insecure_prot.sh
# Description:
#       A script to block insecure protocols ( ftp) at MI.
# Note:
#       None.
##
# Usage:
#       apos_block_insecure_prot.sh
##
# Output:
#       None.
##
# Changelog:
# - Tue Feb 08 2022 - Sowjanya Medak (xsowmed)
#	Removed telnet and mts related code
# - Wed Dec 30 2020 - Rajeshwari Padavala  (xcsrpad)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh
# Common variables
CMD_CLUSTER_CONF="/opt/ap/apos/bin/clusterconf/clusterconf"
VLAN_MAPING_CONF="/cluster/etc/ap/apos/vlan_adapter_maping.conf"
CLUS_MGMT_OPTS="mgmt --cluster"
lcc_name="/usr/bin/cluster"
CMD_HWTYPE='/opt/ap/apos/conf/apos_hwtype.sh'
IMMFIND="/usr/bin/cmw-utility immfind"
IMMLIST="/usr/bin/cmw-utility immlist"
CMD_GREP=/usr/bin/grep
CMD_AWK=/usr/bin/awk
exit_sucs=0
exit_fail=1
CUST_INTERFACE_LIST=''

rules_ftp=(
"all -A INPUT -p tcp --dport 21 -i eth1 -j DROP"
)
rules_gep7=(
"all -A INPUT -p tcp --dport 21 -i eth7 -j DROP"
"all -A INPUT -p tcp --dport 21 -i eth8 -j DROP"
)

rules_ftp_native=(
"all -A INPUT -p tcp --dport 21 -i bond1 -j DROP"
)

rules_ftp_frontcable=(
"all -A INPUT -p tcp --dport 21 -i eth2 -j DROP"
)

function GET_VLANTAGS(){
  local VLANTAGS=''
  local V_DOMAIN=''
  local V_ADAPTER=''
  local INTERFACE=''
  local V_NAME=''

  # check if the network is defined for the perticular vlan
  if is_vAPG; then
    while read line
    do
      V_DOMAIN=$( echo $line | $CMD_AWK -F " " '{print $2}')
      V_ADAPTER=$( echo $line | $CMD_AWK -F " " '{print $3}')
      INTERFACE=$( echo $V_ADAPTER | cut -d . -f2)
			[ "$V_DOMAIN" == "" ] && continue
      if [ "$V_DOMAIN" == 'AP' ]; then
        if $( ${CMD_CLUSTER_CONF} interface -D | ${CMD_GREP} -qw $INTERFACE &>/dev/null); then
          VLANTAGS="$VLANTAGS $INTERFACE"
        fi
      fi
    done < $VLAN_MAPING_CONF
  else
    while read line
    do
      V_NAME=$( echo $line | $CMD_AWK -F " " '{print $1}')
      V_ADAPTER=$( echo $line | $CMD_AWK -F " " '{print $2}')
      [[ "$V_NAME" == "" ]] && continue
      if $( ${CMD_CLUSTER_CONF} interface -D | ${CMD_GREP} -qw "$V_ADAPTER" &>/dev/null); then
        VLANTAGS="$VLANTAGS $V_ADAPTER"
      fi
    done < $VLAN_MAPING_CONF
  fi

  echo $VLANTAGS
}
#// to check if any other way of fetching teaming status 
#########MAIN
OAM_ACCESS=$(get_oam_param)

apos_log "checking teaming status"
imm_class_name=$(kill_after_try 3 3 4 ${IMMFIND} -c NorthBound)
  if [ ! -z "$imm_class_name" ]; then
apos_log "Teaming status: $rif_status Oam access:  $OAM_ACCESS"     
rif_status=$(kill_after_try 3 3 4 ${IMMLIST} -a teamingStatus $imm_class_name | ${CMD_AWK} 'BEGIN { FS = "=" } ; { print $2 }')
fi
 
[[ -s $VLAN_MAPING_CONF ]] && 
{
VLAN_VAR=1
}

rules=("${rules_ftp[@]}")
if is_vAPG; then
      rules=("${rules_ftp[@]}")
	  INTERFACE_LIST=$( ${CMD_CLUSTER_CONF} interface -D | ${CMD_GREP} -w ethernet | ${CMD_AWK} '{print $4}' | sort | uniq)
      
      for eth in $INTERFACE_LIST; do
          if echo $eth | $CMD_GREP -Eq 'eth7|eth8|eth9|eth10' ; then 
            CUST_INTERFACE_LIST="$CUST_INTERFACE_LIST $eth"
          fi 
      done
    elif [[ $rif_status -eq 1  ||  "$OAM_ACCESS" == "NOCABLE" ]]; then
      rules=("${rules_ftp_native[@]}")
fi
if [ "$OAM_ACCESS" = "FRONTCABLE" ]; then   
	rules=("${rules[@]}" "${rules_ftp_frontcable[@]}")
fi

  HW_TYPE=$($CMD_HWTYPE 2>/dev/null)
  [ -z "$HW_TYPE" ] && apos_abort "ERROR: HW_TYPE not found"

  
  [[  $HW_TYPE == "GEP7" ]] && {
    rules=("${rules_ftp[@]}" "${rules_gep7[@]}")
   }
   
    apos_log "Adding rules for blocking insecure protocol" 
    for rule in "${rules[@]}"; do
        $CMD_CLUSTER_CONF iptables --m_add ${rule} 	&>/dev/null	
    done
	
	if is_vAPG; then
		rules=("${rules_ftp[@]}" ) 
        for rule in "${rules[@]}"; do
            $CMD_CLUSTER_CONF ip6tables --m_add ${rule} &>/dev/null		
        done
		for CUST_ETH in $CUST_INTERFACE_LIST; do
		    $CMD_CLUSTER_CONF iptables --m_add all -A INPUT -p tcp --dport 21 -i $CUST_ETH -j DROP  &>/dev/null
		    $CMD_CLUSTER_CONF ip6tables --m_add all -A INPUT -p tcp --dport 21 -i $CUST_ETH -j DROP  &>/dev/null
		done
	fi
	
	if [[ $VLAN_VAR -eq 1 ]];then
	VLAN_TAG=$( GET_VLANTAGS)
       for TAG in $VLAN_TAG; do
	       $CMD_CLUSTER_CONF iptables --m_add all -A INPUT -p tcp --dport 21 -i $TAG -j DROP  &>/dev/null
	   done
	fi   
	
	   
	rCode=$exit_sucs

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
	 apos_log "failure while reloading iptables rules"	
    fi

	 apos_log "script success executed"	
