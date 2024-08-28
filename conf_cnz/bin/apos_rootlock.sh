#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_rootlock.sh
# Description:
#       A script to forbid remote root access to the system.
# Note:
#	To be executed only on one node.
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Tue Nov 13 2012 - Francesco Rainone (efrarai)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|
#

pushd /opt/ap/apos/bin/clusterconf/ &>/dev/null

if [ $(./clusterconf ssh.rootlogin --display | wc -l) -eq 1 ]; then
	./clusterconf ssh.rootlogin --add control off
elif [ $(./clusterconf ssh.rootlogin --display | wc -l) -eq 2 ]; then
	RULENO=$(./clusterconf ssh.rootlogin --display | tail -n -1 | awk '{print $1}')
	./clusterconf ssh.rootlogin --modify ${RULENO}:ssh.rootlogin control off
else
	apos_abort "unsupported ssh.rootlogin configuration found in /cluster/etc/cluster.conf"
fi

popd &>/dev/null

apos_outro $0

exit $TRUE

# End of file
