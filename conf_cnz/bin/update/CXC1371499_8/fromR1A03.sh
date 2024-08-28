#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A03.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Mon 01 Dec 2017 - Raghavendra Koduri(XKODRAG)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
CLU_HOOKS_PATH='/cluster/hooks/'
SRC='/opt/ap/apos/etc/deploy/cluster/hooks/'.
CFG_PATH="/opt/ap/apos/conf"

##
# BEGIN: updating DNR hooks for GEP7
##
  pushd $CLU_HOOKS_PATH &>/dev/null
    ./apos_deploy.sh --from "$SRC/after-booting-from-disk.tar.gz" --to "$CLU_HOOKS_PATH/after-booting-from-disk.tar.gz"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying after-booting-from-disk.tar.gz file"
    fi
    
	./apos_deploy.sh --from "$SRC/post-installation.tar.gz" --to "$CLU_HOOKS_PATH/post-installation.tar.gz"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying post-installation.tar.gz file"
    fi
	
    ./apos_deploy.sh --from "$SRC/pre-installation.tar.gz" --to "$CLU_HOOKS_PATH/pre-installation.tar.gz"
    if [ $? -ne $TRUE ]; then
      apos_abort "failure while deploying pre-installation.tar.gz file"
    fi
	
	##
	
  popd &>/dev/null
  
  
##
# END: updating DNR hooks for GEP7
##

# BEGIN: updating iptables configuration
  pushd $CFG_PATH &>/dev/null
    apos_check_and_call $CFG_PATH apos_iptables.sh
  popd &>/dev/null
# END: updating iptables configuration
##

# BEGIN: updating aposcfg_sshd_config.sh configuration due to merge conflict
  pushd $CFG_PATH &>/dev/null
    apos_check_and_call $CFG_PATH aposcfg_sshd_config.sh
  popd &>/dev/null
# END: updating aposcfg_sshd_config.sh configuration due to merge conflict
##
##

# BEGIN: Deploy of drbd config
SRC='/opt/ap/apos/etc/deploy'

#deploying apos-drbd.sh files
  DD_REPLICATION_TYPE=$(get_storage_type)

  if [ "$DD_REPLICATION_TYPE" == "DRBD" ]; then
    pushd $CFG_PATH &> /dev/null
    [ ! -x apos_deploy.sh ] && apos_abort 1 '$CFG_PATH/apos_deploy.sh not found or not executable'
    ./apos_deploy.sh --from "$SRC/usr/lib/systemd/scripts/apos-drbd.sh" --to "/usr/lib/systemd/scripts/apos-drbd.sh"
    [ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of apos-drbd.sh file"

    ./apos_deploy.sh --from "$SRC/usr/lib/systemd/scripts/apg-drbd-meta-convert" --to "/usr/lib/systemd/scripts/apg-drbd-meta-convert"
    [ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code during the deployment of apg-drbd-meta-convert file"
   
  
    popd &>/dev/null
  fi

# END: Deploy of drbd config
##

##
# BEGIN: Fix for sockets issue in SLES12 SP2
  pushd $CFG_PATH &> /dev/null
# check AP type
    if ! isAP2; then
      # AP1 files deployment
      LIST='usr/lib/systemd/system/apg-netconf-beep@.service
            usr/lib/systemd/system/apg-netconf-beep.socket
            usr/lib/systemd/system/apg-rsh@.service
            usr/lib/systemd/system/apg-rsh.socket
            usr/lib/systemd/system/apg-vsftpd@.service
            usr/lib/systemd/system/apg-vsftpd.socket
            usr/lib/systemd/system/apg-vsftpd-nbi@.service
            usr/lib/systemd/system/apg-vsftpd-nbi.socket
            usr/lib/systemd/system/apg-vsftpd-APIO_1@.service
            usr/lib/systemd/system/apg-vsftpd-APIO_1.socket
            usr/lib/systemd/system/apg-vsftpd-APIO_2@.service
            usr/lib/systemd/system/apg-vsftpd-APIO_2.socket'
    else
      # AP2 files deployment
      LIST='usr/lib/systemd/system/apg-rsh@.service
            usr/lib/systemd/system/apg-rsh.socket
            usr/lib/systemd/system/apg-vsftpd@.service
            usr/lib/systemd/system/apg-vsftpd.socket
            usr/lib/systemd/system/apg-vsftpd-nbi@.service
            usr/lib/systemd/system/apg-vsftpd-nbi.socket'
    fi
    
    SRC='/opt/ap/apos/etc/deploy'
    for ITEM in $LIST; do
      $(echo $ITEM | grep -q "socket" ) && {
        apos_servicemgmt disable "$ITEM" &>/dev/null || apos_abort "failure while disabling $ITEM"
      }
      ./apos_deploy.sh --from $SRC/$ITEM --to /$ITEM
      [ ! $? = 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
	  $(echo $ITEM | grep -q "socket" ) && {
	  apos_servicemgmt enable "$ITEM" &>/dev/null || apos_abort "failure while enabling $ITEM"
	  apos_servicemgmt restart "$ITEM" &>/dev/null || apos_abort "failure while restarting $ITEM" 
      }
	  apos_servicemgmt reload APOS --type=service &>/dev/null || apos_abort 'failure while reloading system services'
    done
  popd &>/dev/null

# END: Fix for sockets issue in SLES12 SP2
##

# R1A04 -> R1A05
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_8 R1A04
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0

exit $TRUE
# End of file

