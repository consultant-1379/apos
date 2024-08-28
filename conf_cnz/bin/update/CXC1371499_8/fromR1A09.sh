#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2017 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A09.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue 17 Apr 2018 - Pratap Reddy Uppada (xpraupp)
#     First version.
##
# Changelog:
# - Wed 18 Apr 2018 - Yeswanth Vankayala (xyesvan)
#     First version.
##
##
# Changelog:
# - Tue 24 Apr 2018 - Furquan Ullah (xfurull)
#     First version.
##


# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh


#Common variables
CFG_PATH="/opt/ap/apos/conf"
STORAGE_PATHS="/usr/share/pso/storage-paths"
STORAGE_CONFIG_PATH="$STORAGE_PATHS/config"
PSO_FOLDER=$( apos_check_and_cat $STORAGE_CONFIG_PATH)
SEC_ACS_PSO_CONFIG_FOLDER="$PSO_FOLDER/sec-apr9010539"
SRC='/opt/ap/apos/etc/deploy'
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
BASEDIR='/usr/lib/lde/failoverd-helpers'
BASEFILE="${BASEDIR}/apg-defaults"

##
# BEGIN: Deployment of sudoers for swmgr
STORAGE_TYPE=$(get_storage_type)
pushd $CFG_PATH &> /dev/null
if [ "$STORAGE_TYPE" == 'MD' ] ; then
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup"
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_md" --to "/etc/sudoers.d/APG-comgroup"
else
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_drbd" --to "/etc/sudoers.d/APG-comgroup"
  ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
fi
popd &> /dev/null
# END: Deployment of sudoers for swmgr
##

##
# BEGIN: Deploy apg-defaults script in failoverd framework
if [ "$HW_TYPE" != 'VM' ]; then
        pushd $CFG_PATH &> /dev/null
  # Deployment of custom failoverd-related files
  ./apos_deploy.sh --from "${SRC}/${BASEFILE}" --to "${BASEFILE}"
  if [ $? -ne $TRUE ]; then
    apos_abort "failure while deploying ${BASEFILE}"
  fi
  popd &>/dev/null
fi
# END: Deploy apg-defaults script in failoverd framework
##

##
# BEGIN: NETCONF server issue
AP_TYPE=$(apos_get_ap_type)
if [ "$AP_TYPE" == 'AP1' ]; then
  pushd $CFG_PATH &> /dev/null
  ./apos_deploy.sh --from "$SRC/usr/lib/systemd/system/apg-netconf-beep@.service" --to "/usr/lib/systemd/system/apg-netconf-beep@.service"
  [ ! $? = 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code while deploying apg-netconf-beep\@.service"
  popd &>/dev/null
  # reload the APOS services
  apos_servicemgmt reload APOS --type=service &>/dev/null || apos_abort 'failure while reloading system services'
fi
# END: NETCONF server issue
##


##
# BEGIN: ldap_aa.conf for SEC 2.6 
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from /opt/ap/apos/conf/ldap_aa.conf --to $SEC_ACS_PSO_CONFIG_FOLDER/ldap/etc/ldap_aa.conf
if [ $? -ne 0 ]; then
  apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code for ldap_aa.conf"
fi
popd &> /dev/null
# END: ldap_aa.conf for SEC 2.6 
##

##
# BEGIN: Fix for TR HW69055
/usr/lib/lde/config-management/apos_syslog-config config init
if [ $? -ne 0 ];then
apos_abort "Failure while executing apos_syslog-config"
fi
apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'
# END: Fix for TR HW69055
##

# R1A09 -> R1A10
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_8 R1A10
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0

exit $TRUE
# End of file

