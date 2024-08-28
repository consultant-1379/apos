#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2011 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_opasswd.sh
# Description:
#       A script to create the /etc/opasswd file.
# Note:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Tue May 08 2012 - Fabio Ronca (efabron)
#	Configuration scripts rework.
# - Tue Jan 31 2012 - Satya Deepthi Gopisetti (xsatdee)
#	First version.
## 

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common commands
SED=$(which sed)
GREP=$(which grep)
TOUCH=$(which touch)
CHMOD=$(which chmod)

# Config files
PSWD_HISTORY_FILE="/etc/security/opasswd"

# Main
if [ ! -f $PSWD_HISTORY_FILE ]
then
        $TOUCH $PSWD_HISTORY_FILE
        $CHMOD u+w $PSWD_HISTORY_FILE
fi

apos_outro $0
exit $TRUE

# End of file
