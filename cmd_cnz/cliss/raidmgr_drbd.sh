#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2013 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       raidmgr_drbd.sh
# Description:
#       A script to wrap the invocation of raidmgr from the COM CLI.
# Note:
#       None.
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Wed Apr 03 2013 - Malangsha Shaik (xmalsha)
#       First version.
##

# extract the user-name
Gid=$(/usr/bin/id -g)
if [[ $Gid -eq 0 || $Gid -eq 110 ]] ; then
	# root-user and tsadmin
	C_USER='C_USER=root-user'
else
	# if command is invoked from COM-CLI
	C_USER='C_USER=ldap-user'
	Gids=$(/usr/bin/id -G)
	[[ "$Gids" =~ 111 ]] && {
		count=$( echo \"$Gids\" | wc -w)
		if test $count -gt 1 ; then
			# command is launched from BASH,
			# treat this case as root user,as we want
			# give root permission to BASH ts user
			C_USER='C_USER=root-user'
		else
			# command is launched from COM CLI
			C_USER='C_USER=ts-user'
		fi
    }
fi

umask 002
/usr/bin/sudo /opt/ap/apos/bin/raidmgr "$C_USER" "$@"
exit $?
