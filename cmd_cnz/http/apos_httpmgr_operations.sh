#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_httpmgr_operations.sh
# Description:
#       A script to configure the listen.conf file.
# Note:
#	This script is a plugin.The prior check of apache server is configured or not 
#	shoud be done from the base script along with the validation of the arguments passed. 
##
# Usage:
#       apos_httpmgr_operations.sh <Old_cluster_IP> <New_cluster_IP> <Folder_Location>
##
# Changelog:
# - Mon Jul 28 2015 - Roni Newatia (xronnew)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

# log script starting
apos_intro $0
CMD_CAT="/bin/cat"
HTTP_CONFIGURATION_FILE="http_config_file"
HTTP_LISTEN_CONF="http_files/listen.conf"
exit_fail="1"

function console_abort(){
apos_abort $1
echo -e "Error when executing (general fault)"
exit "$2"
}
OLD_IP="$1"
NEW_IP="$2"
HTTP_CONF_FOLDER="$3"
[ ! -f "$HTTP_CONF_FOLDER$HTTP_LISTEN_CONF" ] && console_abort "Netdef_apache: configuration file missing" $exit_fail 
LISTEN_IP=$($CMD_CAT $HTTP_CONF_FOLDER$HTTP_LISTEN_CONF|grep -E '^[[:space:]]*Listen[[:space:]]+'|awk '{print $2}'|awk -F":" '{print $1}')
[ -z "$LISTEN_IP" ] && console_abort "Netdef_apache:Invalid value" $exit_fail
if [ "$LISTEN_IP" == "$OLD_IP" ];then
	sed -i "s/${OLD_IP}/${NEW_IP}/" $HTTP_CONF_FOLDER$HTTP_LISTEN_CONF &>/dev/null
	[ $? -ne 0 ] && console_abort "Error when executing (general fault)" $exit_fail 
fi

# log succesful script execution 
apos_outro $0

exit $TRUE
# End of file
