#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2013 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_logindenial.sh
# Description:
#       A script to deny login to ldap users on port 4422.
##
# Changelog:
# - Tue Dec 18 2012 - Francesco Rainone (efrarai)
#	First version.
##

#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|
#

/bin/logger -t 'sshd' -i -p 'authpriv.alert' "user \"${USER:-<UNKNOWN_USER>}\" has been rejected access to TS-session"
/bin/kill -HUP $PPID
/bin/kill -HUP $$

# End of file
