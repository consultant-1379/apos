#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1C.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1C.
# Note:
#	None.
##
# Changelog:
# - Thu Mar 24 2016 - Pratap Reddy Uppada(XPRAUPP)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
SRC='/opt/ap/apos/etc/deploy'
CFG_PATH='/opt/ap/apos/conf'
AP_TYPE=$(apos_get_ap_type)
ftp_state_file="/opt/ap/apos/conf/apos_ftp_state.conf"

fuse_path="/usr/share/filem"
internal_root_file="internal_filem_root.conf"
lde_nbi_fs_path="/usr/share/ericsson/cba/nbi-root-dir"

#------------------------------------------------------------------------------#

# R1B --> R1C
#------------------------------------------------------------------------------#
##
# BEGIN: New group creation for LAPH0
pushd $CFG_PATH &> /dev/null
apos_check_and_call $CFG_PATH aposcfg_group.sh
popd &> /dev/null
# END: Groups creation
##

##
# BEGIN: new script to set vlan QoS settings like PCP/DSCP setting
isBSP && apos_check_and_call $CFG_PATH aposcfg_vlanqos.sh
# END: new script to set vlan QoS settings like PCP/DSCP setting
##
       
##
# BEGIN: Create system disk folders
apos_check_and_call $CFG_PATH apos_mkdir_sd.sh
# END: Create system disk folders
##

##
# BEGIN: syncd config script configuration
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH aposcfg_syncd-conf.sh
popd &>/dev/null
# END: syncd config script configuration
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
# BEGIN: Update of sshd in case of cache.
CACHE_DURATION=$(apos_get_cached_creds_duration)
pushd $CFG_PATH &> /dev/null
if [ $CACHE_DURATION -ne 0 ];then
  ./apos_deploy.sh --from "/opt/ap/apos/etc/deploy/etc/pam.d/sshd_cache" --to "/cluster/etc/pam.d/sshd" \
    || apos_abort "Failure during the update of sshd cached"
else
  ./apos_deploy.sh --from "/opt/ap/apos/etc/deploy/etc/pam.d/sshd" --to "/cluster/etc/pam.d/sshd" \
    || apos_abort "Failure during the update of sshd"
  MAX_RETRY=3;count=0
  while ! diff /cluster/etc/pam.d/sshd /etc/pam.d/sshd &>/dev/null && [ $count -lt $MAX_RETRY ]; do
    /bin/sleep 1
    ((count ++))
  done
  if ! diff /cluster/etc/pam.d/sshd /etc/pam.d/sshd &>/dev/null ; then
    apos_log "No syncd intervention, deploying /etc/pam.d/sshd"
    ./apos_deploy.sh --from "/opt/ap/apos/etc/deploy/etc/pam.d/sshd" --to "/etc/pam.d/sshd" \
      || apos_abort "Failure during the update of sshd locally"
  fi
fi
popd &> /dev/null
# END: Update of sshd in case of cache.
##

##
# BEGIN: Deploy of apos_ftp_state.conf files
pushd $CFG_PATH &> /dev/null
FTP_DEST_DIR=$(apos_create_brf_folder config)
[ ! -d $FTP_DEST_DIR ] && apos_abort 1 'unable to retrieve ftp-state configuration folder'
if [ ! -f $FTP_DEST_DIR/ftp_state.conf ]; then
  if [ -f $ftp_state_file ]; then
    MESSAGE=$(./apos_deploy.sh --from /opt/ap/apos/conf/apos_ftp_state.conf --to $FTP_DEST_DIR/ftp_state.conf 2>&1)
    if [ $? -ne 0 ]; then
      apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code. Error: \"${MESSAGE}\""
    fi
  else
    apos_abort 1 'unable to retrieve ftp_state configuration file'
  fi
fi
popd >/dev/null
# END: Deploy of apos_ftp_state.conf files
##

##
# BEGIN: lde-config script configuration
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_ftp-config" --to "/usr/lib/lde/config-management/apos_ftp-config" \
  || apos_abort "failure while deploying apos_ftp-config file"
./apos_insserv.sh /usr/lib/lde/config-management/apos_ftp-config \
  || apos_abort "failure while creating apos_ftp-config file symlink"
popd &>/dev/null
# END: lde-config script configuration
##

##
# BEGIN: Profile local handling
# /etc/profile.local file set up
pushd $CFG_PATH &> /dev/null
if [ "AP1" == "$AP_TYPE" ]; then
  apos_check_and_call $CFG_PATH aposcfg_profile-local.sh
else
  apos_check_and_call $CFG_PATH aposcfg_profile-local_AP2.sh
fi
popd &> /dev/null
# END: Profile local handling
##

##
# BEGIN: Deployment of sudoers
STORAGE_TYPE=$(get_storage_type)
pushd $CFG_PATH &> /dev/null
if [ "$STORAGE_TYPE" == "MD" ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup" 
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_md" --to "/etc/sudoers.d/APG-comgroup"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_drbd" --to "/etc/sudoers.d/APG-comgroup"
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
fi
./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsadmin" --to "/etc/sudoers.d/APG-tsadmin"
popd &> /dev/null
# END: Deployment of sudoers
##

##
# BEGIN: libcli_extension_subshell update
pushd $CFG_PATH &> /dev/null
if [ -x /opt/ap/apos/conf/apos_deploy.sh ]; then
  if [ -x /opt/com/util/com_config_tool ]; then
    DEST_DIR=$(/opt/com/util/com_config_tool location)
  else
    DEST_DIR='/storage/system/config/com-apr9010443'
  fi
  [ ! -d $DEST_DIR ] && apos_abort 1 'unable to retrieve COM configuration folder'
  # libcli_extension_subshell.cfg
  if [ "AP2" == "$AP_TYPE" ]; then
    ./apos_deploy.sh --from /opt/ap/apos/conf/libcli_extension_subshell_ap2.cfg --to $DEST_DIR/lib/comp/libcli_extension_subshell.cfg
  else
    ./apos_deploy.sh --from /opt/ap/apos/conf/libcli_extension_subshell.cfg --to $DEST_DIR/lib/comp/libcli_extension_subshell.cfg
  fi
  if [ $? -ne 0 ]; then
    apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
  fi
fi
popd &> /dev/null
# END:  libcli_extension_subshell update
##

##
# BEGIN: Symlink creation for vsftpd
/bin/ln -f -s /etc/pam.d/sshd /etc/pam.d/vsftpd || apos_abort 'creation of symlink /etc/pam.d/vsftpd failed'
# END: Symlink creation for vsftpd
##

##
# BEGIN: TR HU18007
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_logrotd-config" --to "/usr/lib/lde/config-management/apos_logrotd-config" \
  || apos_abort "failure while deploying apos_logrotd-config file"
popd &> /dev/null
CONFIG_PATH='/usr/lib/lde/config-management'
pushd $CONFIG_PATH &>/dev/null
./apos_logrotd-config config reload || apos_abort 'reload of apos_logrotd-config failed'
popd &>/dev/null
# restart logrotd to apply new configuration
/sbin/service lde-logrotd restart || apos_abort 'reload of /etc/init.d/lde-logrotd service failed'
# END: TR HU18007
##

##
# BEGIN: apos_exports-config setup
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_exports-config" --to "/usr/lib/lde/config-management/apos_exports-config" || apos_abort "failure while deploying lde-config file"
./apos_insserv.sh /usr/lib/lde/config-management/apos_exports-config || apos_abort "failure while deploying lde-config file symlink"
/usr/lib/lde/config-management/apos_exports-config config reload
popd &>/dev/null
exportfs -ra
# END: apos_exports-config setup
##

##
# BEGIN: iptables rules configuration
pushd $CFG_PATH &>/dev/null
./apos_iptables.sh
cluster config -v &>/dev/null || apos_abort "cluster.conf validation has failed!"
cluster config -r -n $(</etc/cluster/nodes/this/id) &>/dev/null || apos_abort "cluster.config reload has failed!"
service iptables restart &>/dev/null || apos_abort 'failure while restarting iptables service'
popd &>/dev/null
# END: iptables rules configuration
##

##
# BEGIN: lde-dhcpd update
pushd $CFG_PATH &> /dev/null
if [ -x /opt/ap/apos/conf/apos_deploy.sh ]; then
  if [ "AP2" == "$AP_TYPE" ]; then
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


#------------------------------------------------------------------------------#

# R1C -> R2A (APG43L 3.1) 
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R2A
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A01"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
