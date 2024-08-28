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
#	None.
##
# Changelog:
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
CFG_PATH='/opt/ap/apos/conf'
# BEGIN:Market Adaptation impacts and TR HX13989
/usr/lib/lde/config-management/apos_syslog-config config init
if [ $? -ne 0 ];then
  apos_abort "Failure while executing apos_syslog-config"
fi
apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'
# END:Market Adaptation impacts and TR HX13989

# TR HW92423 
#------------------------------------------------------------------------------#
init_file="/opt/ap/apos/conf/initparam.conf"
siteparam_file="/opt/ap/apos/conf/apos_siteparam.sh"
rm_file="/usr/bin/rm"
[ -f "$init_file" ] && $rm_file $init_file
[ -f "$siteparam_file" ] && $rm_file $siteparam_file
#------------------------------------------------------------------------------#
# END

# BEGIN: Enm system role configuration
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH aposcfg_axe_sysroles.sh
popd &> /dev/null
# END: Enm system role configuration

# For COM 7.7.0-22 integration
#-------------------------------------------#
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &> /dev/null
#------------------------------------------#

# R1A03 -> R1A04
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_9 R1A04
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
