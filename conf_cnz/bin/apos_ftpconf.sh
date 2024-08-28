#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_ftpconf.sh
# Description:
#       A script to set the vsftpd daemon.
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
# - Mon Jun 20 2016 - Antonio Buonocunto (eanbuon)
#       FTP on Public moved in apos_operations.
# - Thu Jan 21 2016 - Antonio Buonocunto (eanbuon)
#       systemd adaptation.
# - Fri Mar 22 2013 - Vincenzo Conforti (qvincon)
#	Changed to manage AP2 configuration
# - Fri Jun 29 2012 - Francesco Rainone (efrarai) & Antonio Buonocunto (eanbuon)
#	Fix.
# - Wed Jun 27 2012 - Alfonso Attanasio (ealfatt)
#	Adaptation to BRF.
# - Tue May 14 2012 - Paolo Palmieri (epaopal)
#	Configuration of NBI folder on default ftp site.
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Tue Oct 18 2011 - Francesco Rainone (efrarai)
#       Bugfix.
# - Mon Sep 26 2011 - Francesco Rainone (efrarai)
#       Bugs correction.
# - Mon Sep 05 2011 - Paolo Palmieri (epaopal)
#       Bugs correction.
# - Thu Jul 19 2011 - Paolo Palmieri (epaopal)
#       Definition of the APG FTP sites and related virtual directories.
# - Mon Mar 14 2011 - Francesco Rainone (efrarai)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0


# Main
LFTP_CONF_FILE="/etc/lftp.conf"
# Update the NBI folder for the "Default FTP Site"
echo "Configuring external nbi folder"
EXTERNAL_ROOT=$(<$(apos_create_brf_folder config)/nbi_filem_root.conf)
[ -z ${EXTERNAL_ROOT} ] && apos_abort 1 'failure while getting external root directory from nbi_filem_root.conf'
DEF_FTP_DIR=$EXTERNAL_ROOT
# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)

FILE=/opt/ap/apos/conf/vsftpd/vsftpd.conf
if [ -f $FILE ]; then
	KEYWORD="local_root="
	NEW_ROW="local_root=$DEF_FTP_DIR"
	cat "$FILE" | sed "s@$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
	mv "$FILE.new" "$FILE"
else
	apos_abort 1 "File ${FILE} not found!"
fi

# Disable ssl verification in lftp client
sed -i "s@.*set ssl:ca-file.*@#set ssl:ca-file "/etc/ssl/ca-bundle.pem"@g" $LFTP_CONF_FILE
if [ $? -ne 0 ];then
  apos_abort "Failure while configuring $LFTP_CONF_FILE"
fi

apos_outro $0
exit $TRUE

# End of file
