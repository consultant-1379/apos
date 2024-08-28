#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2018 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#      "get_passive_comp.sh" 
# Description:
#       A script to fetch passive components using apg-adm command and stores
#       in cluster path.
#
# Note:
#       None.
##
# Output:
#       None.
##
# Changelog:
#
# - Wed June 30 2021 - xkomala
#        In case of upgrade scenario, even though passive_blocks file exist,
#        it should be updated with the latest list of passive blocks. 
# - Wed Sep 19 2018 - zgxxnav
#       First version.
#

STORAGE_PATH_APOS="/storage/system/config/apos"
PASSIVE_COMP=$STORAGE_PATH_APOS/passive_blocks
PHYTHON="/usr/bin/python"
APGADM="/opt/ap/apos/bin/apg-adm.py"

$PHYTHON $APGADM --get passive  > $PASSIVE_COMP
echo "passive_blocks file updated in $STORAGE_PATH_APOS"
