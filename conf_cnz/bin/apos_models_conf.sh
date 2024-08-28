#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_models_conf.sh
# Description:
#       Network configuration in IMM script.
#                               In APOS R1A08 there is an old ApzFuntions model and then
#                               it will be replaced in next LSVs, NetworkConfiguration model is a
#                               new added model. This script is providing the configuration inside
#       the NetworkConfiguration object in IMM.
# Note:
#                               None.
##
# Usage:
#                               None.
##
# Output:
#       None.
##
# Changelog:
# - Thu Jan 23 2020 - Pratap Reddy Uppada (xpraupp)
#       IPv6 impacts for Virtual
# - Thu Apr 04 2019 - Dharma Teja (xdhatej)
#       HX56291: applied retry mechnaism for fetching system_type attribute.
# - Wed Apr 12 2017 - Yeswanth Vankayala (xyesvan)
#       Adaptations for Single APG Images.
# - Fri Dec 02 2016 - Antonio Buonocunto (eanbuon)
#       Added new AxeInfo handling
# - Mon Jul 25 2016 - Mallikarjuna Rao (xmalrao)
#       Added new apt-type IPSTP
# - Mon Feb 01 2016 - Pratap Reddy Uppada (xpraupp)
#       system configuration impacts for virtulization
# - Thu Jan 14 2016 - Sindhuja Palla (xsinpal)
#       added new parameter SMX for shelf architecture
# - Thu Dec 10 2015 - Pratap Reddy Uppada (xpraupp)
#       updated with parmtool to fetch parameters
# - wed jul 02 2014 - Rajeshwari Padavala (xcsrpad)
#       changes for virtual environment
# - Mon May 19 2014 - Antonio Buonocunto (eanbuon)
#       timingStatus configuration in NOCABLE environment.
# - Mon Apr 7 2014 - Malangsha Shaik (xmalsha)
#       cableless changes
# - Fri Dec 06 2013 - Luca Ruffini (xlucruf)
#       Add maxStoredManualBackup and autoDelete attributes handling for BrF.
# - Tue Aug 13 2013 - Uppada Pratapa Reddy (xpraupp)
#       Add data replication type
# - Tue Jun 18 2013 - Claudia Atteo (eattcla)
#       Add ap attribute handling for dual ap.
# - Tue Mar 26 2013 - Vincenzo Conforti (qvincon)
#       Add apNodeNumber handling for dual ap.
# - Mon Oct 29 2012 - Antonio Bonocunto (eanbuon)
#       Add AxeApplication handling.
# - Fri Sep 14 2012 - Fabio Ronca (efabron), Antonio Bonocunto (eanbuon)
#       Configuration scripts rework.
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#       Configuration scripts rework.
# - Fri Sep 02 2011 - Paolo Palmieri (epaopal)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Global variables
MI_PATH="/cluster/mi/installation"
node_a_name="SC-2-1"
node_b_name="SC-2-2"
datadisk_replication_type=0
CMD_LOGGER='/bin/logger'
CFG_PATH="/opt/ap/apos/conf"

function cidr2mask() {
  local i mask=""
  local full_octets=$(($1/8))
  local partial_octet=$(($1%8))

  for ((i=0;i<4;i+=1)); do
    if [ $i -lt $full_octets ]; then
      mask+=255
    elif [ $i -eq $full_octets ]; then
      mask+=$((256 - 2**(8-$partial_octet)))
    else
      mask+=0
    fi
    test $i -lt 3 && mask+=.
  done

  echo $mask
}

function fetch_params() {

  local ITEMS="$@"
  for ITEM in $ITEMS; do
     case "$ITEM" in
     public_network_ipv4_prefix)
       # - Collect public network netmask
       netmaskId=$( $CMD_PARMTOOL get --item-list public_network_ipv4_prefix \
        2>/dev/null | awk -F'=' '{print $2}')
       if [ -z "$netmaskId" ]; then
         netmaskId=$( cat $MI_PATH/public_network_ipv4_prefix)
       fi
       netmask_v4=$(cidr2mask $netmaskId)
       [ -z "$netmask_v4" ] && apos_abort 1 "public network netmask not found!"
     ;;
     public_network_ipv6_prefix)
       # - Collect public_v6 network netmask
       netmask_v6=$( $CMD_PARMTOOL get --item-list public_network_ipv6_prefix \
        2>/dev/null | awk -F'=' '{print $2}')
       [ -z "$netmask_v6" ] && apos_abort 1 "public_v6 network netmask not found!"
     ;;
     node1_public_network_ipv6_ip_address)
       # - Collect node A IPv6 address
       node1_ipv6_address=$( $CMD_PARMTOOL get --item-list node1_public_network_ipv6_ip_address \
       2>/dev/null | awk -F'=' '{print $2}')
         [ -z "$node1_ipv6_address" ] && apos_abort 1 "node A IPv6 address not found!"
     ;;

     node1_public_network_ipv4_ip_address)
       # - Collect node A IPv4 address
       node1_ipv4_address=$( $CMD_PARMTOOL get --item-list node1_public_network_ipv4_ip_address \
       2>/dev/null | awk -F'=' '{print $2}')
       if [ -z "$node1_ipv4_address" ]; then
         node1_ipv4_address=$( cat $MI_PATH/node1_public_network_ipv4_ip_address)
         [ -z "$node1_ipv4_address" ] && apos_abort 1 "node A IPv4 address not found!"
       fi
     ;;

     node2_public_network_ipv4_ip_address)
       # - Collect node B IPv4 address
       node2_ipv4_address=$( $CMD_PARMTOOL get --item-list node2_public_network_ipv4_ip_address \
        2>/dev/null | awk -F'=' '{print $2}')
       if [ -z "$node2_ipv4_address" ]; then
         node2_ipv4_address=$( cat $MI_PATH/node2_public_network_ipv4_ip_address)
         [ -z "$node2_ipv4_address" ] && apos_abort 1 "node B IPv4 address not found!"
       fi
     ;;

     node2_public_network_ipv6_ip_address)
       # - Collect node B IPv6 address
       node2_ipv6_address=$( $CMD_PARMTOOL get --item-list node2_public_network_ipv6_ip_address \
       2>/dev/null | awk -F'=' '{print $2}')
         [ -z "$node2_ipv6_address" ] && apos_abort 1 "node B IPv6 address not found!"
     ;;

     cluster_public_network_ipv4_ip_address)
       # - Collect cluster IPv4 address
       cluster_ipv4_address=$( $CMD_PARMTOOL get --item-list cluster_public_network_ipv4_ip_address \
        2>/dev/null | awk -F'=' '{print $2}')
       if [ -z "$cluster_ipv4_address" ]; then
         cluster_ipv4_address=$( cat $MI_PATH/cluster_public_network_ipv4_ip_address)
         [ -z "$cluster_ipv4_address" ] && apos_abort 1 "cluster IPv4 address not found!"
       fi
     ;;

     cluster_public_network_ipv6_ip_address)
       # - Collect cluster IPv6 address
       cluster_ipv6_address=$( $CMD_PARMTOOL get --item-list cluster_public_network_ipv6_ip_address \
        2>/dev/null | awk -F'=' '{print $2}')
       [ -z "$cluster_ipv6_address" ] && apos_abort 1 "cluster IPv6 address not found!"
     ;;

     default_network_ipv4_gateway_ip_address)
       # - Collect default gateway IPv4 address
       gateway_ipv4_address=$( $CMD_PARMTOOL get --item-list default_network_ipv4_gateway_ip_address \
        2>/dev/null | awk -F'=' '{print $2}')
       if [ -z "$gateway_ipv4_address" ]; then
         gateway_ipv4_address=$( cat $MI_PATH/default_network_ipv4_gateway_ip_address)
         [ -z "$gateway_ipv4_address" ] && apos_abort 1 "gateway IPv4 address not found!"
       fi
     ;;

     default_network_ipv6_gateway_ip_address)
       # - Collect default gateway IPv6 address
       gateway_ipv6_address=$( $CMD_PARMTOOL get --item-list default_network_ipv6_gateway_ip_address \
        2>/dev/null | awk -F'=' '{print $2}')
       [ -z "$gateway_ipv6_address" ] && apos_abort 1 "gateway IPv6 address not found!"
     ;;

     me_name)
       # - Collect Managed element name
       me_name=$( $CMD_PARMTOOL get --item-list me_name 2>/dev/null | \
        awk -F'=' '{print $2}')
       if [ -z "$me_name" ]; then
         me_name=$( cat $MI_PATH/me_name)
         [ -z "$me_name" ] && apos_abort 1 "Managed Element name not found!"
       fi
     ;;
     shelf_architecture)
       # - Collect shelf architecture parameter
       shelf_architecture=$( $CMD_PARMTOOL get --item-list shelf_architecture \
        2>/dev/null | awk -F'=' '{print $2}')
       if [ -z "$shelf_architecture" ]; then
         shelf_architecture=$( cat $MI_PATH/shelf_architecture)
         [ -z "$shelf_architecture" ] && apos_abort 1 "shelf_architecture parameter not found!"
       fi
       case "$shelf_architecture" in
             SCB)
             shelf_architecture=0
             ;;
             SCX)
             shelf_architecture=1
             ;;
             DMX)
             shelf_architecture=2
             ;;
             VIRTUALIZED)
             shelf_architecture=3
             ;;
             SMX)
             shelf_architecture=4
             ;;
             *)
               apos_abort 1 "($shelf_architecture) shelf_achitecture parameter not valid!"
        esac
        ;;
      system_type)
        # - Collect SystemType parameter
        $CMD_LOGGER "Entering the system_type function.."
        system_type=$( $CMD_PARMTOOL get --item-list system_type 2>/dev/null | \
         awk -F'=' '{print $2}')
       $CMD_LOGGER "system_type value after executing the parmtool command is $system_type"
        if [ -z "$system_type" ]; then
          system_type=$( cat $MI_PATH/system_type)
          $CMD_LOGGER "system_type value after searching in MI_PATH is $system_type"
          if [ -z "$system_type" ]; then
                $CMD_LOGGER "Retrying for fetching system_type value with sleep 10sec"
                sleep 10
                 system_type=$( $CMD_PARMTOOL get --item-list system_type 2>/dev/null | \
                  awk -F'=' '{print $2}')
                 [ -z "$system_type" ] && system_type=$( cat $MI_PATH/system_type)
                 $CMD_LOGGER "system_type value after retrying is $system_type"
          fi

          [ -z "$system_type" ] && apos_abort 1 "system_type parameter not found!"
        fi
	case "$system_type" in
            SCP)
            system_type=0
            ;;
            MCP)
            system_type=1
            ;;
            *)
            apos_abort 1 "($system_type) system_type parameter not valid!"
        esac
        ;;
     datadisk_replication_type)
        # - Collect datadisk replication type parameter
        replication_type_str=$(get_storage_type)
        [ -z "$replication_type_str" ] && apos_abort 1 "replication_type_str parameter not found!"
        case "$replication_type_str" in
            MD)
            datadisk_replication_type=1
            ;;
            DRBD)
            datadisk_replication_type=2
            ;;
            *)
            apos_abort 1 "data replication_type_str($replication_type_str) parameter not valid!"
         esac
         ;;
     apg_oam_access)
        # collect apg_oam_access parameter
        apg_oam_access=$(get_oam_param)
        [ -z "$apg_oam_access" ] && apos_abort 1 "apg_oam_access parameter not found!"
        case "$apg_oam_access" in
            FRONTCABLE)
            apg_oam_access=0
            ;;
            NOCABLE)
            apg_oam_access=1
            timingStatus=1
            ;;
        esac
        ;;
     apt_type)
       # - Collect Axe Application parameter
       axe_application=$( $CMD_PARMTOOL get --item-list apt_type 2>/dev/null | \
        awk -F'=' '{print $2}')
       if [ -z "$axe_application" ]; then
         axe_application=$( cat $MI_PATH/apt_type)
         [ -z "$axe_application" ] && apos_abort 1 "axe_application parameter not found!"
       fi
       case "$axe_application" in
             MSC)
             axe_application=0
             ;;
             HLR)
             axe_application=1
             ;;
             BSC)
             axe_application=2
             ;;
             WIRELINE)
             axe_application=3
             ;;
             TSC)
             axe_application=4
             ;;
             IPSTP)
             axe_application=5
             ;;
             *)
             apos_abort 1 "($axe_application) axe_application parameter not valid!"
       esac
       ;;
       apz_protocol_type)
        # - Collect apzProtocolType parameter
        apz_protocol_type=$( $CMD_PARMTOOL get --item-list apz_protocol_type 2>/dev/null | \
         awk -F'=' '{print $2}')
        if [ -z "$apz_protocol_type" ]; then
          apz_protocol_type=$( cat $MI_PATH/apz_protocol_type)
          [ -z "$apz_protocol_type" ] && apos_abort 1 "apz_protocol_type parameter not found!"
        fi
        case "$apz_protocol_type" in
              APZ2123X_SDLC)
              apz_protocol_type=0
              ;;
              APZ2123X_TCPIP)
              apz_protocol_type=1
              ;;
              APZ21240_TCPIP)
              apz_protocol_type=2
              ;;
              APZ21250_TCPIP)
              apz_protocol_type=3
              ;;
              APZ21255_OR_LATER_TCPIP)
              apz_protocol_type=4
              ;;
              *)
             apos_abort 1 "($apz_protocol_type) apz_protocol_type parameter not valid!"
         esac
        ;;
     *)
       apos_abort 1 "parameter not found!"
     esac
  done
}

function stage0_configuration() {

  local BUILD_TIME_ITEMS='system_type
             apz_protocol_type
             shelf_architecture
             apt_type
             datadisk_replication_type
             apg_oam_access'

  fetch_params $BUILD_TIME_ITEMS

  local CMD_LIST=( "immcfg -a nodeAName="$node_a_name" northBoundId=1,networkConfigurationId=1"
             "immcfg -a nodeBName="$node_b_name" northBoundId=1,networkConfigurationId=1"
             "immcfg -a systemType="$system_type" axeFunctionsId=1"
             "immcfg -a apzProtocolType="$apz_protocol_type" axeFunctionsId=1"
             "immcfg -a apgShelfArchitecture="$shelf_architecture" axeFunctionsId=1"
             "immcfg -a axeApplication="$axe_application" axeFunctionsId=1"
             "immcfg -a dataDiskReplicationType="$datadisk_replication_type" axeFunctionsId=1"
             "immcfg -a apgOamAccess="$apg_oam_access" axeFunctionsId=1" )

  for CMD in "${CMD_LIST[@]}"; do
    PARAM=$(echo $CMD | awk '{print $3}' | awk -F= '{print $1}')
    kill_after_try 5 5 6 $CMD 2>/dev/null ||  apos_abort 1 'Failed to set parameter ${PARM} in IMM!'
  done

  if [ "$apg_oam_access" = "1" ]; then
    CMD="immcfg -a teamingStatus="$timingStatus" northBoundId=1,networkConfigurationId=1"
    kill_after_try 5 5 6 $CMD 2>/dev/null || apos_abort 1 'parameter timingStatus updation failed!'
  fi

  # get the ap type : AP1 or AP2
  AP_TYPE=$(apos_get_ap_type)
  # check AP type
  if [ $AP2 == $AP_TYPE ]; then
    kill_after_try 5 5 6 immcfg -a apNodeNumber="2" axeFunctionsId=1 2>/dev/null || apos_abort 1 'parameter apNodeNumber in axeFunctions class not found!'
    kill_after_try 5 5 6 immcfg -a ap="2" axeFunctionsId=1 2>/dev/null || apos_abort 1 'parameter ap in axeFunctions class not found!'
  else
    kill_after_try 5 5 6 immcfg -a ap="1" axeFunctionsId=1 2>/dev/null || apos_abort 1 'parameter ap in axeFunctions class not found!'
  fi

  # Set BRF Manual Backup Housekeeping
  BRF_HSK_DN="brmBackupHousekeepingId=SYSTEM_DATA,brmBackupManagerId=SYSTEM_DATA,brMId=1"
  BRF_HSK_DN_12="brmBackupHousekeepingId=SYSTEM_DATA,brmBackupManagerId=SYSTEM_DATA,BrMbrMId=1"
  BRF_HSK=$(immfind | grep brmBackupHousekeepingId=SYSTEM_DATA | tr -d '\n')
  # check that BRF_HSK is set to a non-empty string
  if [ -n "${BRF_HSK}" ] ; then
    if [[ "$BRF_HSK" == "$BRF_HSK_DN" || "$BRF_HSK" == "$BRF_HSK_DN_12" ]] ; then
      kill_after_try 5 5 6 immcfg -a maxStoredManualBackups="5" $BRF_HSK
      kill_after_try 5 5 6 immcfg -a autoDelete="1" $BRF_HSK
    fi
  fi
}

function stage2_configuration() {

  apos_log 'INFO: stage2 configuration'
 
  local CONFIG_PARAMS
  local COMMON_CONFIG_PARAMS
  local IPV4_NETWORK_PARAMS
  local IPV6_NETWORK_PARAMS

  COMMON_CONFIG_PARAMS='me_name
                        apt_type
                        system_type'

  IPV4_NETWORK_PARAMS='public_network_ipv4_prefix
             node1_public_network_ipv4_ip_address
             node2_public_network_ipv4_ip_address
             cluster_public_network_ipv4_ip_address
             default_network_ipv4_gateway_ip_address'
   
  IPV6_NETWORK_PARAMS='public_network_ipv6_prefix
             node1_public_network_ipv6_ip_address
             node2_public_network_ipv6_ip_address
             cluster_public_network_ipv6_ip_address
             default_network_ipv6_gateway_ip_address'

  # Handling of AxeInfo objects
  if is_vAPG; then
    pushd $CFG_PATH &> /dev/null
    apos_log 'Handling of AxeInfo objects'
    ./aposcfg_axe_info.sh
    if [ $? -ne 0 ]; then
      apos_abort 1 "\"aposcfg_axe_info.sh\" exited with non-zero return code"
    fi
    popd &> /dev/null 

    if isIPv4Stack; then 
      # Formation configuration parameters for IPv4 stack 
      CONFIG_PARAMS="$IPV4_NETWORK_PARAMS 
                     $COMMON_CONFIG_PARAMS"

      apos_log 'INFO: Handling of IPv4stack model config parameters'
      # Fetch the config parameter values
      fetch_params $CONFIG_PARAMS

      node_a_ip_address="$node1_ipv4_address"
      node_b_ip_address="$node2_ipv4_address"
      cluster_ip_address="$cluster_ipv4_address"
      gateway_ip_address="$gateway_ipv4_address"
      netmask="$netmask_v4"

    elif isIPv6Stack; then 
      # Formation of configuration parameters for IPv4 stack
      CONFIG_PARAMS="$IPV6_NETWORK_PARAMS 
                     $COMMON_CONFIG_PARAMS"

      apos_log 'INFO: Handling of IPv6stack model config parameters'
      # Fetch the config parameter values
      fetch_params $CONFIG_PARAMS

      node_a_ip_address="$node1_ipv6_address"
      node_b_ip_address="$node2_ipv6_address"
      cluster_ip_address="$cluster_ipv6_address"
      gateway_ip_address="$gateway_ipv6_address"
      netmask="$netmask_v6"

    elif isDualStack; then
      # Formation of configuration parameters for Dual stack
      CONFIG_PARAMS="$IPV4_NETWORK_PARAMS 
                     $IPV6_NETWORK_PARAMS 
                     $COMMON_CONFIG_PARAMS"
     
      apos_log 'INFO: Handling of Dualstack model config parameters'
      # Fetch the config parameter values
      fetch_params $CONFIG_PARAMS

      # Here both IPv4 and IPv6 addresses are populated with 
      # comma seperated in the northbound model.
      # For example:
      #   nodeBIpAddress    SA_STRING_T  10.33.42.189,2010:33:42::1d
      node_a_ip_address="$node1_ipv4_address,$node1_ipv6_address"
      node_b_ip_address="$node2_ipv4_address,$node2_ipv6_address"
      cluster_ip_address="$cluster_ipv4_address,$cluster_ipv6_address"
      gateway_ip_address="$gateway_ipv4_address,$gateway_ipv6_address"
      netmask="$netmask_v4,$netmask_v6"
    fi 

  else
    # In case of Native, 
    # only IPv4 network parameters are required
    CONFIG_PARAMS="$IPV4_NETWORK_PARAMS 
                   $COMMON_CONFIG_PARAMS"

    apos_log 'INFO: Handling of Native model config parameters'
    fetch_params $CONFIG_PARAMS

    node_a_ip_address="$node1_ipv4_address"
    node_b_ip_address="$node2_ipv4_address"
    cluster_ip_address="$cluster_ipv4_address"
    gateway_ip_address="$gateway_ipv4_address"
    netmask="$netmask_v4"
  fi 

  local CMD_LIST=( "immcfg -a netmask="$netmask" northBoundId=1,networkConfigurationId=1"
                   "immcfg -a nodeAIpAddress="$node_a_ip_address" northBoundId=1,networkConfigurationId=1"
                   "immcfg -a nodeBIpAddress="$node_b_ip_address" northBoundId=1,networkConfigurationId=1"
                   "immcfg -a clusterIpAddress="$cluster_ip_address" northBoundId=1,networkConfigurationId=1"
                   "immcfg -a gatewayIpAddress="$gateway_ip_address" northBoundId=1,networkConfigurationId=1"
                   "immcfg -a networkManagedElementId="$me_name"  managedElementId=1"
                   "immcfg -a axeApplication="$axe_application" axeFunctionsId=1" 
                   "immcfg -a systemType="$system_type" axeFunctionsId=1" )

  for CMD in "${CMD_LIST[@]}"; do
    PARAM=$(echo $CMD | awk '{print $3}' | awk -F= '{print $1}')
    kill_after_try 5 5 6 $CMD 2>/dev/null ||  apos_abort 1 'Failed to set parameter ${PARAM} in IMM!'
  done
}

##### M A I N #####
FACTORY_FILE='/cluster/storage/system/config/lde/csm/templates/config/initial/ldews.os/factoryparam.conf'
CMD_GREP='/usr/bin/grep'
CMD_AWK='/usr/bin/awk'
if [ -f $FACTORY_FILE ];  then
  is_vm=$(cat $FACTORY_FILE | $CMD_GREP -i installation_hw | $CMD_AWK -F "=" '{print $2}')
fi
if is_system_configuration_allowed; then
  if is_deploy_phase; then
    apos_log "Models: Deploy Phase Virtual"
    # Only deployment time configuration parameters
    # applied at this phase
    [ "$is_vm" == "VM" ] && stage0_configuration
    stage2_configuration
  fi
else
  apos_log "Models: Deploy Phase Native"
  # In case of native and build-time(ISO) of APG,
  # all manadatory configuration parameters(i.e
  # stage0 and stage2 parameters) are stored in IMM.
  stage0_configuration
  ! is_vAPG && stage2_configuration
fi

apos_outro $0
exit $TRUE

# End of file
