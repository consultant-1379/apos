# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A06.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# Thu 02 Sep - Swapnika Baradi (xswapba)
# Tue 07 Sept - Pravalika P (zprapxx)
#        First Version
##
# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
[ -z "$HW_TYPE" ] && apos_abort 1 'HW_TYPE not found'

##
# WORKAROUND FOR TR:HX28643 BEGIN
if [ "$HW_TYPE" == "GEP5" ]; then
        eri-ipmitool wbcsgep5 -b 18 0x30
fi
# WORKAROUND FOR TR:HX28643 END
##
#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC="/opt/ap/apos/etc/deploy"

# BEGIN: rsyslog configuration changes
apos_log 'Configuring Syslog Changes _14/fromR1A06 .....'
SYSLOG_CONFIG_FILE='usr/lib/lde/config-management/apos_syslog-config'
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "${SRC}/${SYSLOG_CONFIG_FILE}" --to "/${SYSLOG_CONFIG_FILE}" || \
  apos_abort "failure while deploying syslog configuration file"
  "/${SYSLOG_CONFIG_FILE}" config reload &>/dev/null || \
  apos_abort 'Failure while reloading syslog configuration file'
popd &>/dev/null
apos_servicemgmt restart rsyslog.service &>/dev/null ||  apos_log 'failure while restarting syslog service'
# END: rsyslog configuration changes

#BEGIN : vBSC : RP-VM SSH KEYS MANAGEMENT HOST ID MAPPING
if isvBSC; then
##
# BEGIN: Deployment of apos_rp-hosts-config
# vBSC: keymgmt command
  pushd $CFG_PATH &> /dev/null
  ./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_rp-hosts-config" --to "/usr/lib/lde/config-management/apos_rp-hosts-config"
  if [ $? -ne 0 ]; then
    apos_abort "failure while deploying apos_rp-hosts-config"
  fi

  ./apos_insserv.sh /usr/lib/lde/config-management/apos_rp-hosts-config
  if [ $? -ne 0 ]; then
    apos_abort "failure while creating symlink to file apos_rp-hosts-config"
  fi

  popd &> /dev/null
##
fi
#END : vBSC : RP-VM SSH KEYS MANAGEMENT

# R1A06 -> R1B
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_14 R1B
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

