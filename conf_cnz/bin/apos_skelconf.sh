#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_skelconf.sh
# Description:
#       A script to setup skeleton files for new defined users.
# Note:
#	None.
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Tue Dec 18 2012 - Francesco Rainone (efrarai)
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

pushd '/opt/ap/apos/conf/' >/dev/null

FILE='/etc/skel/.bashrc'
if ! grep -Eqs '^# apos_skelconf.sh: ' $FILE; then
        apos_log "setting custom PATH to $FILE..."
        cat >>$FILE << "HEREDOC"
# apos_skelconf.sh: adding custom PATH settings to new-created users
DIR_LIST='/sbin /usr/sbin'
for DIR in $DIR_LIST; do
        if [[ ! "$PATH" =~ ^${DIR}/*:|:${DIR}/*:|:${DIR}/*$ ]]; then
                export PATH=${PATH}:${DIR}
        fi
done
HEREDOC
        apos_log "done"
else
        apos_log "custom PATH setting in $FILE already present!"
fi

popd &>/dev/null

apos_outro $0

exit $TRUE

# End of file
