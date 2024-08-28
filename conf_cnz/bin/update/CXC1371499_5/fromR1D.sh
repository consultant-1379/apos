#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1D.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue Dec 06 2016 -Baratam Swetha (xswebar)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
# Common variables

CFG_PATH="/opt/ap/apos/conf"
SRC="/opt/ap/apos/etc/deploy"

#BEGIN Deployment of hooks
pushd $CFG_PATH &> /dev/null
[ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/cluster/hooks/pre-installation.tar.gz" --to "/cluster/hooks/pre-installation.tar.gz" --exlo
./apos_deploy.sh --from "$SRC/cluster/hooks/after-booting-from-disk.tar.gz" --to "/cluster/hooks/after-booting-from-disk.tar.gz" --exlo
popd &>/dev/null

#END Deployment of hooks
##

#BEGIN fix for TR HV39005
DD_REPLICATION_TYPE=$(get_storage_type)
if [ "$DD_REPLICATION_TYPE" != "DRBD" ]; then
   drbd_file="/usr/lib/systemd/scripts/apos-drbd.sh"
   cmd_rm='/usr/bin/rm'
   [ -x "$drbd_file" ] && $cmd_rm $drbd_file
fi

#END
##

#BEGIN: updating apos_adhoc_templates  for virtual environment------------------------#
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)

if [[ "$HW_TYPE" == 'VM' ]]; then

  this_id=$(</etc/cluster/nodes/this/id)
  peer_id=$(</etc/cluster/nodes/peer/id)
  hostname=$(</etc/cluster/nodes/this/hostname)
  peer_hostname=$(</etc/cluster/nodes/peer/hostname)
  true=0

  node_name="AP-A"
  peer_nodename="AP-B"

  if [ "$this_id" -eq 2 ]; then
    node_name='AP-B'
    peer_nodename='AP-A'
  fi

  cmd_adhoc_template_mngr='/opt/ap/apos/conf/apos_adhoc_template_mgr.sh'
  storage_path='/storage/system/config/apos'
  adhoc_hot_template="${storage_path}/HEAT_${node_name}.yml"

  #status files
  status_file="${storage_path}/.${hostname}_upgraded"
  peer_status_file="${storage_path}/.${peer_hostname}_upgraded"

  #commands
  cmd_touch='/usr/bin/touch'
  ssh='/usr/bin/ssh'
  cmd_rm='/usr/bin/rm'

  # generated hot-template
  if [ -x "$cmd_adhoc_template_mngr" ]; then
    $cmd_adhoc_template_mngr --generate &>/dev/null
    if [ $? -eq 0 ]; then
          #create an temporary status file /storage/system/config/apos/HEAT_AP-[A/B].yml
          $cmd_touch $status_file
      apos_log "created new adhoc templates...OK"
    else
      apos_abort "created new adhoc templates...Failed"
    fi
  else
      apos_abort "no file $cmd_adhoc_template_mngr "
  fi

  #workaround for availability zone and APT TYPE, as this data is missing from user_data file
  #update apt_type value to MSC
  subs_string="{availability_zone_ap_substitute}"
  value="nova"
  sed -i -e "s/$subs_string/$value/g" $adhoc_hot_template

  #update apt_type value to MSC
  subs_string="{apt_type_substitute}"
  value="MSC"
  sed -i -e "s/$subs_string/$value/g" $adhoc_hot_template

  # try copy apos_adhoc_templates to nbi from active node once both the nodes are upgraded
  if [[ -f "$status_file" && -f "$peer_status_file" ]]; then
    removeExitCode=$($ssh $peer_hostname "$cmd_adhoc_template_mngr --copy-to-nbi  &> /dev/null; echo $?" 2> /dev/null)
    if [ "$removeExitCode" == "$true"  ]; then

          #clean up  temporary status files
          [ -f "$status_file" ] && $cmd_rm $status_file
          [ -f "$peer_status_file" ] && $cmd_rm $peer_status_file

      apos_log "adhoc_hot_templates Transferred succesfully"

    else

          #clean up  temporary status files
          [ -f "$status_file" ] && $cmd_rm $status_file
          [ -f "$peer_status_file" ] && $cmd_rm $peer_status_file
      apos_abort "adhoc_hot_templates Transferred failed"
    fi
  else
      apos_log "Not transferred files as upgradation is still in progress"
  fi

fi
#END  : updating apos_adhoc_templates  --------------------------------------------#

#------------------------------------------------------------------------------#

# R1D -> R1E
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_5 R1E
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

