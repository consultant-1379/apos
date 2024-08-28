#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2014 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_nscd-conf.sh
##
# Description:
#       A script implementing settings for nscd.conf.
##
# Changelog:
# - Fri Nov 27 2015 - Antonio Buonocunto (EANBUON)
#	apos servicemgmt adaptation
# - Tue Jul 01 2014 - Antonio Buonocunto (EANBUON)
#       Cache invalidated in case of duration equal to 0.
# - Tue Jun 10 2014 - Francesco Rainone (EFRARAI)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Variables
NSCD_FILE=/etc/nscd.conf
NSCD_FILE_CLUSTERED=/cluster/etc/nscd.conf
SRC=/opt/ap/apos/etc/deploy

# deploy nscd.conf to /cluster/etc/nscd.conf
/opt/ap/apos/conf/apos_deploy.sh --from "${SRC}/${NSCD_FILE}" --to "${NSCD_FILE_CLUSTERED}" || \
  apos_abort "failure when deploying ${TEMP_LOCATION} to ${NSCD_FILE_CLUSTERED}"

# restart nscd
apos_servicemgmt restart nscd.service &> /dev/null || apos_abort "failure while restarting nscd daemon"

apos_outro $0
exit $TRUE

# End of file
