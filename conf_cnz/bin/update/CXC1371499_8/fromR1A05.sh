#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A05.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Mon 22 Jan 2018 - Yeswanth Vankayala (xyesvan)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

# R1A04 -> R1A05
#------------------------------------------------------------------------------#
# BEGIN:

SRC='/opt/ap/apos/etc/deploy'
CFG_PATH="/opt/ap/apos/conf/"
PAM_CONF_FOLDER="etc/pam.d"
APG_COMMON_AUTH_ROLE2GROUP_FILENAME="acs-apg-auth-role2group"
APG_COMMON_AUTH_ROLE2GROUP_FILE="$PAM_CONF_FOLDER/$APG_COMMON_AUTH_ROLE2GROUP_FILENAME"
ACS_COMMON_AUTH_ROLE2GROUP_LINK="acs-common-auth-role2group"
HW_TYPE='/opt/ap/apos/conf/apos_hwtype.sh'
DD_REPLICATION_TYPE=$(get_storage_type)
LDE_CONFIG_MGMT='usr/lib/lde/config-management'
CMD_DRBDADM='/sbin/drbdadm'
SSSD_CONF_FILE='/etc/sssd/sssd.conf'
NEWROW='case_sensitive = Preserving'
APG_SSHD_CONF='apg_sshd.conf'
MASK=644

pushd $CFG_PATH >/dev/null
if [ -x ./apos_deploy.sh ]; then
  ./apos_deploy.sh --from "$SRC/$APG_COMMON_AUTH_ROLE2GROUP_FILE" --to "/$APG_COMMON_AUTH_ROLE2GROUP_FILE" || apos_abort "failure while deploying /           $APG_COMMON_AUTH_ROLE2GROUP_FILE"
else
  apos_abort "apos_deploy.sh not found or not executable"
fi
popd >/dev/null

pushd /$PAM_CONF_FOLDER >/dev/null
apos_log "creating symbolic link $ACS_COMMON_AUTH_ROLE2GROUP_LINK -> $APG_COMMON_AUTH_ROLE2GROUP_FILENAME"
ln -sf $APG_COMMON_AUTH_ROLE2GROUP_FILENAME $ACS_COMMON_AUTH_ROLE2GROUP_LINK || apos_abort "Failure to link APG PAM auth-role2group configuration"
apos_log "...success"
popd >/dev/null

pushd $CFG_PATH >/dev/null
./aposcfg_sec-conf.sh
popd >/dev/null

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
# END: com configuration handling

##
if ! grep -q '^[[:space:]]*case_sensitive[[:space:]]*=[[:space:]]*' $SSSD_CONF_FILE; then
  apos_log "adding \"$NEWROW\" to $SSSD_CONF_FILE..."
  sed -i "/\[domain\/LdapAuthenticationMethod\]/a ${NEWROW}" $SSSD_CONF_FILE || \
    apos_abort "failure while adding \"$NEWROW\" to $SSSD_CONF_FILE file"
  apos_log "done"
else
  apos_log "\"case_sensitive\" entry already present. Re-setting it to \"$NEWROW\" in $SSSD_CONF_FILE..."
  sed -r -i "s/^[[:space:]]*case_sensitive[[:space:]]*=[[:space:]]*.*/${NEWROW}/g" $SSSD_CONF_FILE || \
    apos_abort "failure while re-setting \"$NEWROW\" in $SSSD_CONF_FILE file"
  apos_log "done"
fi

# sssd restart to make the new rules effective
pushd $CFG_PATH &>/dev/null
apos_servicemgmt restart sssd.service &>/dev/null || \
  apos_abort "failure while restarting sssd.service"
popd &>/dev/null
# END: Disabling case sensitivity for LDAP
##


# Get the Hypervisor type
HYPERVISOR=$( $HW_TYPE --verbose | grep "system-manufacturer" | awk -F"=" '{print $2}' | sed -e 's@^[[:space:]]*@@g' -e 's@^"@@g' -e 's@"$@@g' )
[ -z "$HYPERVISOR" ] && apos_abort 'Failed to fetch hypervisor type'

#BEGIN: updating apos_adhoc_templates  for virtual environment------------------------#
if is_vAPG;then
  if [[ "$HYPERVISOR" =~ .*openstack.* ]]; then

  this_id=$(</etc/cluster/nodes/this/id)
  peer_id=$(</etc/cluster/nodes/peer/id)
  hostname=$(</etc/cluster/nodes/this/hostname)
  peer_hostname=$(</etc/cluster/nodes/peer/hostname)

  node_name="AP-A"
  peer_nodename="AP-B"

  if [ "$this_id" -eq 2 ]; then
    node_name='AP-B'
    peer_nodename='AP-A'
  fi

  cmd_adhoc_template_mngr="$CFG_PATH/apos_adhoc_template_mgr.sh"
  storage_path='/storage/system/config/apos'
  adhoc_hot_template="${storage_path}/HEAT_${node_name}.yml"

  #status files
  status_file="$(apos_create_brf_folder clear)/.${hostname}_upgraded"
  peer_status_file="$(apos_create_brf_folder clear)/.${peer_hostname}_upgraded"

  # generated hot-template
  if [ -x "$cmd_adhoc_template_mngr" ]; then
   $cmd_adhoc_template_mngr --generate &>/dev/null
   if [ $? -eq 0 ]; then
     # create an temporary status file
     # /storage/system/config/apos/HEAT_AP-[A/B].yml
     /usr/bin/touch $status_file
     apos_log "New adhoc templates creation...OK"
   else
    apos_abort "New adhoc templates creation...Failed"
   fi
  else
    apos_abort "$cmd_adhoc_template_mngr file does not exists"
  fi

  # try copy apos_adhoc_templates to nbi from
  # active node once both the nodes are upgraded
  if [[ -f "$status_file" && -f "$peer_status_file" ]]; then
    /usr/bin/ssh $peer_hostname "$cmd_adhoc_template_mngr --copy-to-nbi  &> /dev/null; echo $?" 2> /dev/null
    removeExitCode=$?

    #clean up  temporary status files
    [ -f "$status_file" ] && /usr/bin/rm $status_file
    [ -f "$peer_status_file" ] && /usr/bin/rm $peer_status_file

    if [ "$removeExitCode" == $TRUE  ]; then
      apos_log "adhoc_hot_templates transferred succesfully to NBI path...OK"
    else
      apos_abort "Failed to transfer adhoc_hot_templates to NBI path"
    fi
  else
      apos_log "Not transferred files as upgradation is still in progress"
  fi
 fi
fi

#Common variables
APG_SSHD_CONF='apg_sshd.conf'
MASK=644
AP_TYPE=$(apos_get_ap_type)

function isAP2(){
  [ "$AP_TYPE" == 'AP2' ] && return $TRUE
  return $FALSE
}

##
# BEGIN: Creating drop-in files for APG sshd daemons
LIST='etc/systemd/system/lde-sshd@sshd_config_4422.service.d
      etc/systemd/system/lde-sshd@sshd_config_22.service.d
      etc/systemd/system/lde-sshd@sshd_config_830.service.d
      etc/systemd/system/lde-sshd@sshd_config_mssd.service.d'

pushd $CFG_PATH &>/dev/null

for ITEM in $LIST; do
   [ ! -d "/$ITEM" ] && /bin/mkdir -m $MASK -p "/$ITEM"
  ./apos_deploy.sh --from $SRC/$ITEM/$APG_SSHD_CONF --to /$ITEM/$APG_SSHD_CONF
    [ ! $? = 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
done

# END: Creating drop-in files for APG sshd daemons
##

##
# BEGIN: Fix for sockets issue in SLES12 SP2
# check AP type
if ! isAP2; then
  # AP1 files deployment
  FILES_LIST='/usr/lib/systemd/system/apg-netconf-beep.socket
              /usr/lib/systemd/system/apg-vsftpd.socket
              /usr/lib/systemd/system/apg-vsftpd-nbi.socket'
else
  # AP2 files deployment
  FILES_LIST='/usr/lib/systemd/system/apg-vsftpd.socket
              /usr/lib/systemd/system/apg-vsftpd-nbi.socket'
fi
for ITEM in $FILES_LIST; do
  if ! grep -q "DefaultDependencies=no" $ITEM ;then
    if echo $ITEM | grep -q "apg-netconf-beep.socket" ; then
      /usr/bin/sed -i '/Description\=NETCONF-beep Activation Socket/a DefaultDependencies\=no' $ITEM
    else
      /usr/bin/sed -i '/Conflicts\=vsftpd\.service/a DefaultDependencies\=no' $ITEM
    fi
  fi
done

# END: Fix for sockets issue in SLES12 SP2
##


apos_servicemgmt reload APOS --type=service &>/dev/null || apos_abort 'failure while reloading system services'
# END: Deploy systemd drop-in files for lde-sshd@service


popd &> /dev/null

# BEGIN updating apos_hwinfo command cache file with new option
pushd $CFG_PATH &>/dev/null
./apos_hwinfo.sh --cleancache
./apos_hwinfo.sh --all &>/dev/null
popd &> /dev/null
# END

#END  : updating apos_adhoc_templates  --------------------------------------------#


# R1A02 -> R1A02
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_8 R1A06
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0

exit $TRUE
# End of file

