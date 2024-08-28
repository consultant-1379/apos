#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A05.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1A05.
# Note:
#	None.
##
# Changelog:
# - Thu May 07 2015 - Yeswanth Vankayala(XYESVAN)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

SRC='/opt/ap/apos/etc/deploy'
CFG_PATH='/opt/ap/apos/conf'
# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)

fuse_path="/usr/share/filem"
internal_root_file="internal_filem_root.conf"
lde_nbi_fs_path="/usr/share/ericsson/cba/nbi-root-dir"
CMD_CLUSTER_CONF="/opt/ap/apos/bin/clusterconf/clusterconf"

# R1A05 --> R1A06
#------------------------------------------------------------------------------#

##
# BEGIN: COM configuration
pushd $CFG_PATH >/dev/null
if [ -x $CFG_PATH/apos_comconf.sh ]; then
	./apos_comconf.sh
	if [ $? -ne 0 ]; then
		apos_abort 1 "\"apos_comconf.sh\" exited with non-zero return code"
	fi
else
	apos_abort 1 'apos_comconf.sh not found or not executable'
fi
popd >/dev/null
# END: COM configuration 

# BEGIN: LDAP initial settings
pushd $CFG_PATH >/dev/null
if [ -x $CFG_PATH/apos_ldapconf.sh ] ; then
	./apos_ldapconf.sh
	if [ $? -ne 0 ]; then
		apos_abort 1 "\"apos_ldapconf.sh\" exited with non-zero return code"
	fi
else
	apos_abort 1 'file apos_ldapconf.sh not found or not executable'
fi
popd &>/dev/null
# END: LDAP initial settings
##

# BEGIN: Configure NBI FS root path
pushd $CFG_PATH &>/dev/null
if [ -f $lde_nbi_fs_path ]; then
	apos_log "$lde_nbi_fs_path File exists proceed with configuration"	
else
	apos_abort 1 "$lde_nbi_fs_path File not exists. Not possible to configure NBI root FS folder."
fi

if [ -f $fuse_path/$internal_root_file ]; then
	cat $fuse_path/$internal_root_file > "$lde_nbi_fs_path" || apos_abort 1 'not possible to update NBI FS root path.'
	apos_log "NBI FS root path updated"
else
	apos_abort 1 "$fuse_path/$internal_root_file File not exists. Not possible to configure NBI root FS folder."
fi
popd &>/dev/null
# END: Configure NBI FS root path
##

##
# BEGIN: lde-dhcpd update
pushd $CFG_PATH &> /dev/null
if [ -x /opt/ap/apos/conf/apos_deploy.sh ]; then
  if [ "$AP2" == "$AP_TYPE" ]; then
    ./apos_deploy.sh --from $SRC/etc/init.d/lde-dhcpd_ap2 --to /etc/init.d/lde-dhcpd
  else
    ./apos_deploy.sh --from $SRC/etc/init.d/lde-dhcpd --to /etc/init.d/lde-dhcpd
  fi
  if [ $? -ne 0 ]; then
    apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
  fi
fi
popd &> /dev/null
# END:  libcli_extension_subshell update
##

##
# BEGIN: pcp an dscp vlaue update for APG internal vlans
MI_INST_PATH="/cluster/mi/installation"
STORAGE_API='/usr/share/pso/storage-paths/config'
STORAGE_PATH=$(cat $STORAGE_API)
RHOST=$(</etc/cluster/nodes/peer/hostname)
PEER_NODE_UP=$FALSE

CFG_FILE_SHELF='apos/shelf_architecture'
if [ -f $MI_INST_PATH/shelf_architecture ]; then
 install -m 444 -D $MI_INST_PATH/shelf_architecture $STORAGE_PATH/$CFG_FILE_SHELF
fi

SHELF_ARCH=$(get_shelf_architecture)
[ -z "$SHELF_ARCH" ] && apos_abort "shelf architecture found NULL"

if [ "$SHELF_ARCH" == "DMX" ]; then
  # EGEM2, GEP5, EVO and BSP configuration: oam_vlanid is mandatory.
  CFG_FILE_OAM='apos/oam_vlanid'
  if [ -f $MI_INST_PATH/oam_vlanid ]; then
    install -m 444 -D $MI_INST_PATH/oam_vlanid $STORAGE_PATH/$CFG_FILE_OAM
		OAM_VLANTAG=$( cat $STORAGE_PATH/$CFG_FILE_OAM)
  fi
  # EGEM2, GEP5, EVO and BSP configuration: tipc_vlantag is mandatory.
  CFG_FILE_TIPC='apos/tipc_vlantag'
  if [ -f $MI_INST_PATH/tipc_vlantag ]; then
    install -m 444 -D $MI_INST_PATH/tipc_vlantag $STORAGE_PATH/$CFG_FILE_TIPC
		TIPC_VLANTAG=$(cat $STORAGE_PATH/$CFG_FILE_TIPC)
  fi
  # EGEM2, GEP5, EVO and BSP configuration: network_10g_vlantag file is mandatory.
  CFG_FILE_10G='apos/network_10g_vlantag'
  if [ -f $MI_INST_PATH/network_10g_vlantag ]; then
    install -m 444 -D $MI_INST_PATH/network_10g_vlantag $STORAGE_PATH/$CFG_FILE_10G
		NW10G_VLANTAG=$(cat $STORAGE_PATH/$CFG_FILE_OAM)
  fi

	# check if the remote node is up
	/bin/ping -c 1 -W 1 $RHOST &>/dev/null
  [ $? -eq 0 ] && PEER_NODE_UP=$TRUE

	INTERNAL_VLAN_TAGS="$TIPC_VLANTAG $NW10G_VLANTAG $OAM_VLANTAG"
  # setting PCP value for tipc_vlan, network_10g_vlantag and
  # oam_vlanid. The default value for these vlan is 16
	for vlan in $INTERNAL_VLAN_TAGS; do
  	for INTERFACE in $( /opt/ap/apos/bin/clusterconf/clusterconf interface  -D | grep -w vlan | grep ".$vlan" | awk -F' ' '{print $4}'); do
    	/sbin/vconfig  set_egress_map $INTERFACE 0 $VLAN_PCP  &>/dev/null
    	[ $? -ne 0 ] && apos_abort "Error adding PCP, no changes done"
    	if [ $PEER_NODE_UP -eq $TRUE ]; then
      	/usr/bin/rsh $RHOST /sbin/vconfig set_egress_map $INTERFACE 0 6  &>/dev/null
      	[ $? -ne 0 ] && apos_abort "ERROR: Error adding PCP, no changes done"
    	fi
    	apos_log "PCP value successfully set vlan $INTERFACE"
  	done
	done
	
	#Create files to store PCP values for internal APG vlans
  TMP_CFG_FILE='/tmp/internal_vlan_pcp_file'
  STORAGE_PATH_APOS="/storage/system/config/apos"
  echo '6' > $TMP_CFG_FILE
  install -m 444 -D $TMP_CFG_FILE $STORAGE_PATH_APOS/tipc_vlan_pcp
  install -m 444 -D $TMP_CFG_FILE $STORAGE_PATH_APOS/oam_vlan_pcp
  install -m 444 -D $TMP_CFG_FILE $STORAGE_PATH_APOS/network_10G_pcp
  rm -f $TMP_CFG_FILE

  # set DSCP values for oam_vlanid
  destination_address="0.0.0.0/0"
  $CMD_CLUSTER_CONF iptables --m_add all -t mangle -A OUTPUT -d $destination_address -j DSCP --set-dscp 16 &> /dev/null
  if [ $? -eq 0 ]; then
    echo -e '16' > /storage/system/config/apos/oam_vlanDSCP
    apos_log "DSCP value successfully set for default destination for OAM Vlan"
  else
    apos_abort "Failed to set DSCP value for default destination"
    rCode=1
  fi

  # set PCP values for external vlans
  for l_VLAN_NAME in $( cat /cluster/etc/ap/apos/vlan_adapter_maping.conf | awk '{print $1}'); do
    if [ -z $(echo $(cat /cluster/etc/ap/apos/vlan_adapter_maping.conf | grep -w "$l_VLAN_NAME" | awk '{print $3}')) ]; then
      $( vlanch -q $l_VLAN_NAME,6 -f &>/dev/null )
      if [ $? -eq 0 ]; then
        apos_log "PCP value successfully set vlan $l_VLAN_NAME"
      else
        apos_abort "Failed to set PCP value vlan $l_VLAN_NAME"
      fi
    fi
  done

  # set DSCP values for external Vlans
  # DEFAULT_DSCP=16
  vlan_destinations=$(cat /cluster/etc/cluster.conf | grep -i ^network | grep -i _gw | awk '{print $3}')
  for address in $vlan_destinations; do
    record=$($CMD_CLUSTER_CONF iptables -D | grep -w $address | grep "DSCP" | awk '{print $1}')
    if [ "$record" == "" ] ; then
      $CMD_CLUSTER_CONF iptables --m_add all -t mangle -A OUTPUT -d $address -j DSCP --set-dscp 16 &> /dev/null
      apos_log "cluster conf reload and commit success..."
    fi
  done

  # commit clusterconf changes
  rCode=0
  #Verify cluster configuration is OK after update.
  $CMD_CLUSTER_CONF mgmt --cluster --verify &> /dev/null || rCode=1
  if [ $rCode -eq 1 ]; then
    # Something wrong. Fallback with older cluster config
    $(${CMD_CLUSTER_CONF} mgmt --cluster --abort) && apos_abort "Cluster management verification failed"
  fi

  # Verify seems to be OK. Reload the cluster now.
  $CMD_CLUSTER_CONF mgmt --cluster --reload --verbose &>/dev/null || rCode=1
  if [ $rCode -eq 1 ]; then
    # Something wrong in reload. Fallback on older cluster config
    $(${CMD_CLUSTER_CONF} mgmt --cluster --abort) && apos_abort "Cluster management reload failed"
  fi

  # Things seems to be OK so-far. Commit cluster configuration now.
  $CMD_CLUSTER_CONF mgmt --cluster --commit &>/dev/null || rCode=1
  if [ $rCode -eq 1 ]; then
    # Commit should not fail, as it involves only removing the
    # back up file. anyway bail-out?
    apos_abort "Cluster Management commit failed"
  fi

  apos_log "cluster conf reload and commit success..."

  apos_log "restarting iptables daemon..."
  service iptables restart &>/dev/null || apos_abort "failure while restarting iptables service"

fi
# END: pcp an dscp vlaue update for APG internal vlans

# BEGIN: fix on LVM filter
CFG_PATH="/opt/ap/apos/conf"
DRBD_CFG_FILE="$CFG_PATH/apos-drbd"
LVM_CONF="/etc/lvm/lvm.conf"
LVM_FILTER='filter = [ "a|drbd0|sd[^m].*|", "r|.*|" ]'
#Deploy disaster recovery hook
[ ! -x $CFG_PATH/apos_deploy.sh ] && apos_abort "Can not execute $CFG_PATH/apos_deploy.sh"

# DR post-installation hook copy
$CFG_PATH/apos_deploy.sh --from "/opt/ap/apos/etc/deploy/cluster/hooks/post-installation.tar.gz" --to "/cluster/hooks/post-installation.tar.gz" --exlo

#Check if we are on GEP5
DD_REPLICATION_TYPE=$(get_storage_type)
if [ "$DD_REPLICATION_TYPE" == "DRBD" ]; then 
  #deploy the new apos_drbd file
  [ ! -f $DRBD_CFG_FILE ] && apos_abort "$DRBD_CFG_FILE not found"
  chmod 555 $DRBD_CFG_FILE

  $CFG_PATH/apos_deploy.sh --from $DRBD_CFG_FILE --to /etc/init.d/apos-drbd
  if [ $? -ne 0 ]; then 
    apos_abort "Deploy of apos-drbd file failed"
  else
    apos_log "apos-drbd deployed"
  fi

  #change lvm.conf file
  $(sed -i "/^\s*filter/ c \    $LVM_FILTER" $LVM_CONF)
  [ $? -ne 0 ] && abort "Falied to update lvm.conf file"
  apos_log "$LVM_CONF updated with new LVM filter"
  $( /sbin/lvmdiskscan &>/dev/null )
  [ $? -ne 0 ] && abort "Falied to update lvm.conf file"
  apos_log "$LVM_CONF reload whit success"
  
fi
# END:  fix on LVM filter 
##

##
# BEGIN: apos_sshd-config script configuration
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_sshd-config" --to "/usr/lib/lde/config-management/apos_sshd-config" || apos_abort "failure while deploying lde-config file"
./apos_insserv.sh /usr/lib/lde/config-management/apos_sshd-config || apos_abort "failure while deploying lde-config file symlink"
/usr/lib/lde/config-management/apos_sshd-config config reload
popd &>/dev/null
# END: apos_sshd-config script configuration
##


#------------------------------------------------------------------------------#

# R1A05 -> <NEXT_REVISION>
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R1A06
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A06"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
