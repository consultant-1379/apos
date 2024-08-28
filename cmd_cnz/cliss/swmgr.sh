#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       swmgr.sh
# Description:
#       A script to wrap the invocation of swmgr from the COM CLI.
# Note:
# None.
##
# Usage:
# None.
##
# Output:
#       None.
##
# Changelog:
# - Mon Apr 23 2018 - Malangsha Shaik (XMALSHA)
#   added --apply-patch option
# - Thu Jan 19 2017 - Mallikarjuna Rao (xmalrao)
# First version.
##

if [ "$( echo "$1")" == '--apply-patch' ]; then 
  /usr/bin/sudo /opt/ap/apos/bin/swmgr "$@"
else
  /usr/bin/sudo -u apgswmgr /opt/ap/apos/bin/swmgr "$@"
fi

exit $?
