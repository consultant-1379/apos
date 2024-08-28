#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A03.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version 
# Note:
#       None.
##
# Changelog:
# - 26 Apr 2019 - Chaitanya Tamiri (xtamcha)
#       Impact for new COM 7.9 inntroduction
# - 30 Apr 2019 - Suman Kumar Sahu (zsahsum)
#        COM update for Ftp over Tls, First draft
# - 26 Apr 2019 - Suryanarayana Pammi (xpamsur)
#       First Draft (Adapating the COM environmental variable in APG for Alog-Remote IP)
##


# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
#Common variables
CFG_PATH="/opt/ap/apos/conf"
SRC="/opt/ap/apos/etc/deploy"

##
# BEGIN: Profile local handling
# /etc/profile.local file set up
AP_TYPE=$(apos_get_ap_type)
pushd $CFG_PATH &> /dev/null
if [ "AP1" == "$AP_TYPE" ]; then
  apos_check_and_call $CFG_PATH aposcfg_profile-local.sh
else
  apos_check_and_call $CFG_PATH aposcfg_profile-local_AP2.sh
fi
popd &> /dev/null
# END: Profile local handling
##

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling


# R1A03 -> R1A04
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_10 R1A04
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file

