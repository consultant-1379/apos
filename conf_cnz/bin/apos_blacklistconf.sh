#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2013 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_blacklistconf.sh
# Description:
#       A script to patch /etc/modprobe.d/blacklist in order to avoid a notice message
#       at racoon startup
# Note:
#	This script is called by apos_conf.sh
#	during the %post phase of the OSCONFBIN rpm activation.
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Mon Jan 25 2016 - Gianluca Santoro
#       blacklist filename updated. Syntax improved.
# - Mon Dec 30 2013 - Fabrizio Paglia (xfabpag)
#   	First version
##

BLACKLIST_FILE="/etc/modprobe.d/50-blacklist.conf"

patch_string="blacklist padlock_sha"

if ! grep -q "$patch_string" "$BLACKLIST_FILE"; then
	echo -e "\n$patch_string" >> "$BLACKLIST_FILE"
fi

