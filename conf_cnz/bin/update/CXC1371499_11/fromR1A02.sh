#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A02.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Thu Dec 19 2019 - Poorna Chandra Gorle (zgorpoo)
#        Fix for TR HX87126
# - Thu Dec 19 2019 - Nazeema Begum (xnazbeg)
#        Fix for TR HX33144
# - Tue Dec 3 2019 - Yeswanth Vankayala (xyesvan)
#      COM Shipment Integration
# - Tue Nov 26  2019 - Sowmya Pola (xsowpol) 
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling

# BEGIN: Fix for TR HX33144
/usr/lib/lde/config-management/apos_syslog-config config init
if [ $? -ne 0 ];then
apos_abort "Failure while executing apos_syslog-config"
fi
apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'
# END: Fix for TR HX33144


# R1A02 -> R1A03
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_11 R1A03
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
