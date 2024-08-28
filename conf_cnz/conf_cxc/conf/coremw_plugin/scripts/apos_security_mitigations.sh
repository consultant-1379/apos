#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      apos_security_mitigations.sh
# Description:
#       This script is to enable all security mitigations by default 
#       during Upgrade 
# Note:
#       This script should only invoked during CSP upgrade scenario 
#
##
# Changelog:
# - Fri 01 Jan 2021 - Yeswanth Vankayala (xyesvan)
#      Added new function to align the behaviour of patches
#       First version.

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh 

CLU_FILE='/cluster/etc/cluster.conf'
[ ! -f $CLU_FILE ] && apos_abort 'cluster.conf file not found'

CMD_HWTYPE='/opt/ap/apos/conf/apos_hwtype.sh'
[[ -x $CMD_HWTYPE ]] && HW_TYPE=$($CMD_HWTYPE)
[ -z "$HW_TYPE" ] && apos_abort 'Hardware type found NULL'

LDE_VERSION=$(/usr/bin/immfind | grep ^safMemberCompType | grep ERIC-ldews.cfsmonitor | \
  awk -F'safVersion=' '{print $2}' | awk -F'\' '{print $1}' | cut -d'.' -f1-2)
[ -z "$LDE_VERSION" ] && apos_log 'LDE version found NULL'


function fetch_existing_patch_info() {
  if grep -q '^[[:space:]]*kernel-cmdline[[:space:]]all[[:space:]]*.*$' $CLU_FILE 2>/dev/null; then
    EXISTING_PATCH_INFO="$(grep 'kernel-cmdline all *' $CLU_FILE 2>/dev/null | cut -d' ' -f3-)"
  else
    apos_log 'Kernel-cmdline entry not found. Assuming patches are already enabled'
    exit $TRUE
  fi
}

function undo_changes() {
  if grep -q '^[[:space:]]*kernel-cmdline[[:space:]]all[[:space:]]*.*$' $CLU_FILE 2>/dev/null; then
    /usr/bin/sed -i -r "s/^[[:space:]]*kernel-cmdline[[:space:]]all[[:space:]]*.*$/kernel-cmdline all $EXISTING_PATCH_INFO/g" $CLU_FILE 2>/dev/null
    rCode=$?
  else
    /usr/bin/sed -i -r "$ i\ kernel-cmdline all $EXISTING_PATCH_INFO" $CLU_FILE 2>/dev/null
    rCode=$?
  fi 
 
  if [ $rCode -eq $TRUE ]; then
    /usr/sbin/lde-config --reload --all &>/dev/null
    if [ $? -ne $TRUE ]; then
      apos_abort 'Failure while undoing the configuration changes in cluster.conf'
    fi
  fi

}

# This function disables the mitigations by using lde-config command 
function enable_mitigations() {
  if grep -q '^[[:space:]]*kernel-cmdline[[:space:]]all[[:space:]]*.*$' $CLU_FILE 2>/dev/null; then  
    /usr/bin/sed -i '/^[[:space:]]*kernel-cmdline[[:space:]]all[[:space:]]*.*$/d' $CLU_FILE 2>/dev/null ||\
     apos_abort 'Failed to remove kernel-cmdline entry from cluster.conf file'
    /usr/sbin/lde-config --reload --all &>/dev/null
    if [ $? -ne $TRUE ]; then
      undo_changes
      apos_abort 'Failure while reloading cluster.conf changes'
    else
      apos_log 'Security mitigations are ENABLED successfully'
    fi
  else
    apos_log 'Security mitigations are already ENABLED.'
  fi
}

function disable_quick_reboot() {
  if ! grep -q '^[[:space:]]*quick-reboot[[:space:]]all[[:space:]]off' $CLU_FILE 2>/dev/null; then
    /usr/bin/sed -i -r "$ i\quick-reboot all off" $CLU_FILE 2>/dev/null || \
     apos_abort 'Failed to add quick-reboot entry in cluster.conf file'
    /usr/sbin/lde-config --reload --all &>/dev/null
    if [ $? -ne $TRUE ]; then
      if grep -q '^[[:space:]]*quick-reboot[[:space:]]all[[:space:]]off' $CLU_FILE 2>/dev/null; then
        /usr/bin/sed -i '/^[[:space:]]*quick-reboot[[:space:]]all[[:space:]]off/d' $CLU_FILE 2>/dev/null 
      fi 
      apos_abort 'Failure while reloading cluster.conf changes'
    else
      apos_log 'Quick Reboot disabled successfully'
    fi 
  else
    apos_log 'INFO: Quick Reboot is already disabled.'
  fi 
}

function enable_quick_reboot() {
  if grep -q '^[[:space:]]*quick-reboot[[:space:]]all[[:space:]]off' $CLU_FILE 2>/dev/null; then
    /usr/bin/sed -i '/^[[:space:]]*quick-reboot[[:space:]]all[[:space:]]off/d' $CLU_FILE 2>/dev/null ||\
      apos_abort 'Failed to remove quick-reboot entry from cluster.conf file'
    /usr/sbin/lde-config --reload --all &>/dev/null
    [ $? -ne $TRUE ] && apos_abort 'Failure while reloading cluster.conf changes'
    apos_log 'Quick Reboot enabled successfully'
  else
    apos_log 'INFO: Quick Reboot is already enabled.'
  fi
}

function align_patches_after_upgrade() {
  if grep -q '^[[:space:]]*kernel-cmdline[[:space:]]all[[:space:]]*.*mds=off[[:space:]]*.*' $CLU_FILE 2>/dev/null; then
    if grep -q '^[[:space:]]*kernel-cmdline[[:space:]]all[[:space:]]*.*tsx_async_abort=off[[:space:]]*.*' $CLU_FILE 2>/dev/null; then
      apos_log "TSX_Patch is already Present. Skip the Fix...."
    else
      apos_log "MDS Patch is disabled and TSX is not disabled . Applying  the fix"
      /usr/bin/sed -i "s/mds=off/& tsx_async_abort=off/" $CLU_FILE 2>/dev/null ||\
       apos_log "Failed to append tsx patch"
      /usr/sbin/lde-config --reload --all &>/dev/null
      [ $? -ne 0 ] && apos_log "Reload Failed ..... "
      apos_log "Reload is Successful ...."
    fi
  else
    apos_log "MDS Patch is not disabled. Skip the Fix .... "
  fi
}

# _____________________
#|    _ _   _  .  _    |
#|   | ) ) (_| | | )   |
#|_____________________|
# Here begins the "main" function...

apos_intro $0


case "$1" in

  apply)
        # It must be executed only LDE with 4.7 version
        if [[ -n "$LDE_VERSION" && "$LDE_VERSION" == '4.7' ]]; then
	  # Fetch the existing patchinfo
          fetch_existing_patch_info

          # Enable the mitigations by removing the
          # kernel-cmdline entry from cluster.conf
          enable_mitigations
        else
          apos_log 'INFO: LDE version is greater than 4.7.'
        fi 
     
        # disable quick reboot
        if [[ "$HW_TYPE" == "GEP5"  || "$HW_TYPE" == "GEP7" ]]; then
          disable_quick_reboot
        fi 

        align_patches_after_upgrade
   ;;

  clear)
        if [[ "$HW_TYPE" == "GEP5"  || "$HW_TYPE" == "GEP7" ]]; then
         enable_quick_reboot
        fi
   ;;

   *)
     exit 1
   ;;
esac

apos_outro $0 

exit $TRUE

# END
