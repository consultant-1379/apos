#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A08.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Thu 29 Mar 2018 - Pratap Reddy Uppada (xpraupp)
#     First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

CFG_PATH='/opt/ap/apos/conf'
SRC='/opt/ap/apos/etc/deploy'
cluster_file='/cluster/etc/cluster.conf'

##
# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
# END: com configuration handling
##

# R1A08 -> R1A09
#------------------------------------------------------------------------------#
##
# BEGIN: Fix for TR HW72572
pushd $CFG_PATH &>/dev/null
[ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/cluster/hooks/post-installation.tar.gz" --to "/cluster/hooks/post-installation.tar.gz" --exlo
popd &>/dev/null
# END: Fix for TR HW72572
##

# R1A08 -> R1A09
#------------------------------------------------------------------------------#
##
# BEGIN: Fix for TR HW71844
pushd $CFG_PATH &>/dev/null
[ ! -x "$CFG_PATH/apos_deploy.sh" ] && apos_abort 1 "/opt/ap/apos/conf/apos_deploy.sh not found or not executable"
./apos_deploy.sh --from "$SRC/cluster/hooks/after-installation.tar.gz" --to "/cluster/hooks/after-installation.tar.gz" --exlo
popd &>/dev/null
# END: Fix for TR HW71844
##

##
# BEGIN: Fix for TR HW57634
if is_vAPG ; then
  if grep -q "quick-reboot all off" "$cluster_file"; then
    apos_log 'Already quick-reboot all off is present in /cluster.conf file'
  else
    sed -i '/node 2 control SC-2-2/a\quick-reboot all off\' $cluster_file
    # BEGIN: Reload the cluster configuration on the current node
    cluster config -v &>/dev/null || apos_abort "cluster.conf validation has failed!"
    cluster config --reload &> /dev/null || apos_abort 'Failure while reloading cluster configuration'
    #END: Reload the cluster configuration
  fi
fi
# END: Fix for TR HW57634
##

# R1A08 -> R1A09
#------------------------------------------------------------------------------#
##
# BEGIN: Fix for openssh 7.2 NBC changes.
AP_TYPE=$(apos_get_ap_type)
function isAP2(){
  [ "$AP_TYPE" == "$AP2" ] && return $TRUE
  return $FALSE
}

if isAP2; then
LIST='etc/ssh/sshd_config_22
      etc/ssh/sshd_config_830   
      etc/ssh/sshd_config_4422'
else
LIST='etc/ssh/sshd_config_22
      etc/ssh/sshd_config_830   
      etc/ssh/sshd_config_4422
      etc/ssh/sshd_config_mssd'
fi
pushd $CFG_PATH &> /dev/null
for ITEM in $LIST; do
  ./apos_deploy.sh --from $SRC/$ITEM --to /$ITEM
  [ ! $? = 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
done
popd &> /dev/null
apos_servicemgmt restart lde-sshd.target &>/dev/null || apos_abort 'failure while restarting lde-sshd target'

# END: Fix for openssh 7.2 NBC changes.
##

# R1A09 -> R1A10
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_8 R1A09 
popd &>/dev/null
#------------------------------------------------------------------------------#


apos_outro $0

exit $TRUE
# End of file

