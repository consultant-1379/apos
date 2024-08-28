#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A03.sh
# Description:
#       A script to update APOS_OSCONFBIN from the version R1A03.
# Note:
#	None.
##
# Changelog:
# - Wed Mar 18 2015 - Furquan Ullah (XFURULL)
# Second version.
# - Thu Mar 05 2015 - Nazeema Begum(XNAZBEG)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
SRC='/opt/ap/apos/etc/deploy'
ITEM='etc/dhcpd.conf.local'
CFG_PATH='/opt/ap/apos/conf'
CONFIG_FILE_LIST_AP1='/etc/ssh/sshd_config /etc/ssh/sshd_config_4422 /etc/ssh/mssd_config'
CONFIG_FILE_LIST_AP2='/etc/ssh/sshd_config /etc/ssh/sshd_config_4422'
CACHE_DURATION=$(apos_get_cached_creds_duration)

# R1A03 --> R1A04
#------------------------------------------------------------------------------#
##
cluster_conf_reload() {
  local lcc_name="/usr/bin/cluster"
  $lcc_name config -v &>/dev/null
  local status=$?

  if [ $status -ne $TRUE ]; then
    echo -e "\nSyntax error in the  configuration"
  else
    $lcc_name config -r -a 
  fi

  return $status
}
#------------------------------------------------------------------------------#

# BEGIN: Update of sshd in case of cache.
pushd $CFG_PATH &> /dev/null
if [ "$CACHE_DURATION" != "0" ];then
 ./apos_deploy.sh --from "/opt/ap/apos/etc/deploy/etc/pam.d/sshd_cache" --to "/cluster/etc/pam.d/sshd"
	if [ "$?" != "0" ]; then
		apos_abort "Failure during the update of sshd"
	fi
fi
##

# BEGIN: lde-config script configuration
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_sshd-config" --to "/usr/lib/lde/config-management/apos_sshd-config" || apos_abort "failure while deploying lde-config file"
./apos_insserv.sh /usr/lib/lde/config-management/apos_sshd-config || apos_abort "failure while deploying lde-config file symlink"
popd &>/dev/null
##

# BEGIN: syncd config script configuration
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH aposcfg_syncd-conf.sh 
popd &>/dev/null
# END: deploying syncd configuration 
##
#------------------------------------------------------------------------------#

if [ -f /opt/ap/acs/conf/acs_asec_sshcbc.conf ] ; then 
	cluster_conf_reload
	[ $? -ne $TRUE ] && apos_abort "cluster configuration went wrong!"
else 
	AP_TYPE=$(apos_get_ap_type)
	[ -z "AP_TYPE" ] && apos_abort "AP_TYPE not found"
	CONFIG_FILE_LIST=$CONFIG_FILE_LIST_AP1
	[ "$AP_TYPE" == $AP2 ] && CONFIG_FILE_LIST=$CONFIG_FILE_LIST_AP2
	for FILE in $CONFIG_FILE_LIST
	do
		sed -i 's/,aes128-cbc,aes256-cbc//g' $FILE
		apos_log "$FILE modified with exit code $? " 
	done
	/etc/init.d/sshd restart &>/dev/null 
fi	

# BEGIN: deploying dhcpd.conf.local
pushd /opt/ap/apos/conf &>/dev/null
./apos_deploy.sh --from $SRC/$ITEM --to /$ITEM
[ $? -ne 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
echo 'restarting dhcp daemon...'
service dhcpd restart &>/dev/null || apos_abort 'failure while restarting dhcpd service'
echo 'done'   
popd &>/dev/null
# END: deploying dhcpd.conf.local 
##

# BEGIN: syslog-ng configuration script
pushd $CFG_PATH &>/dev/null
./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_syslog-config" --to "/usr/lib/lde/config-management/apos_syslog-config" || apos_abort "failure while deploying syslog-ng configuration file"
killall -HUP 'syslog-ng' &>/dev/null || apos_abort 'failure while reloading syslog configuration'
popd &>/dev/null
##

# R1A04 -> R1A05
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499 R1A04
[ $? -ne $TRUE ] && apos_abort "failure while executing apos_update.sh R1A04"
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
