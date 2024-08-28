#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_sysconf.sh
# Description:
#       A script for system configuration scripts deployment in vAPG
# Note:
#	None.
##
# Usage:
#	    apos_sysconf.sh
##
# Output:
#       None.
##
# Changelog:
# - Tue Feb 02 2016 - Raghavendra Koduri (xpraupp)
#      Added apos-recover-conf.service for snr.
# - Tue Feb 02 2016 - Pratap Reddy (xpraupp)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

function deploy(){
	echo -n 'Deploying APG system configuration files: --apos blk'
	CFG_PATH='/opt/ap/apos/conf'
  SERV_PATH='/opt/ap/apos/etc/deploy/usr/lib/systemd/system'
  SCRIPT_PATH='/opt/ap/apos/etc/deploy/usr/lib/systemd/scripts'
  SERV_FILES="$SERV_PATH/apos-system-config.service
              $SERV_PATH/apos-early-system-config.service
              $SERV_PATH/apos-finalize-system-config.service
              $SERV_PATH/apos-recovery-conf.service"
  SCRIPT_FILES="$SCRIPT_PATH/apos-system-conf.sh
                $SCRIPT_PATH/apos-finalize-system-conf.sh
                $SCRIPT_PATH/apos-recovery-conf.sh"

  [ ! -x $CFG_PATH/apos_deploy.sh ] && apos_abort 1 "apos_deploy.sh not found or not executable"

  for FILE in $SCRIPT_FILES; do
    [ ! -f "$FILE" ] && apos_abort 1 "\"$FILE\" file not found"
    chmod 755 $FILE
    BASE_FILE=$(/usr/bin/basename $FILE)
    $CFG_PATH/apos_deploy.sh --from $FILE --to /usr/lib/systemd/scripts/$BASE_FILE
    [ $? -ne $TRUE ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
  done

  for FILE in $SERV_FILES; do
		[ ! -f "$FILE" ] && apos_abort 1 "\"$FILE\" file not found"
  	chmod 644 $FILE
    BASE_FILE=$(/usr/bin/basename $FILE)
		$CFG_PATH/apos_deploy.sh --from $FILE --to /usr/lib/systemd/system/$BASE_FILE
		[ $? -ne $TRUE ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"

    apos_servicemgmt enable "$BASE_FILE" &>/dev/null
    [ $? -ne $TRUE ] && apos_abort 1 "Failure while enabling \"$BASE_FILE\""
  done

	echo '...done'
}
echo "In apos_sysconf.sh --apos blk"
deploy

apos_outro $0
exit $TRUE
