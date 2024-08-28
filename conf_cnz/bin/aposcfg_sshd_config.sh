#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_sshd_config.sh
# Description:
#       A script to configure the ssh daemon.
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
# - Mon JAN 22 2017 - Avinash Gundlapally (xavigun)
#	Applyed the changes needed for SLES12 SP2 adoption
# - Tue Oct 24 2017 - Yeswanth Vankayala (xyesvan)
#	Applying changes for MSSD file in Virtual environment
# - Mon Feb 13 2017 - Avinash Gundlapally (xavigun)
#	Changes made to support ssh subsystem in APG
# - Sat Feb 6 2016 - Antonio Buonocunto (eanbuon)
#       Adaptation to system-oam group.
# - Wed Feb 01 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Wed Nov 16 2011 - Francesco Rainone (efrarai)
#	Changes to be update-compliant.
# - Wed Nov 02 2011 - Paolo Palmieri (epaopal)
#	Rework to manage 4222 port.
# - Mon Sep 26 2011 - Paolo Palmieri (epaopal)
#       Definition of rules for MCS MSS SSH.
# - Wed Aug 03 2011 - Paolo Palmieri (epaopal)
#       Definition of rules for com group.
# - Thu Feb 10 2011 - Francesco Rainone (efrarai)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
MSSD_FILE="/etc/ssh/sshd_config_mssd"
CFG_PATH="/opt/ap/apos/conf"
SRC='/opt/ap/apos/etc/deploy'
APG_SSHD_CONF='apg_sshd.conf'
MASK=644
SRC='/opt/ap/apos/etc/deploy'

LIST='etc/systemd/system/lde-sshd@sshd_config_4422.service.d
      etc/systemd/system/lde-sshd@sshd_config_22.service.d
      etc/systemd/system/lde-sshd@sshd_config_830.service.d
      etc/systemd/system/lde-sshd@sshd_config_mssd.service.d'

HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
[ -z $HW_TYPE ] && apos_abort 1 'HW_TYPE not found'

# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)

if [ "$AP2" != "$AP_TYPE" ]; then
  if [ -f "$MSSD_FILE" ]; then
    # increased the num max of allowed connections for GEP5  and GEP7 for ssh mssd service
    if [[ "$HW_TYPE" == "GEP5" || "$HW_TYPE" == 'VM' || "$HW_TYPE" == "GEP7" ]]; then 
      sed -i "s@MaxStartups 280:30:320@MaxStartups 475:30:768@g" $MSSD_FILE
    fi
  else
    apos_abort 1 "file \"$MSSD_FILE\" not found"
  fi
fi


#Implemented systemd drop-in files for lde-sshd

pushd $CFG_PATH &>/dev/null

for ITEM in $LIST; do
   [ ! -d "/$ITEM" ] && /bin/mkdir -m $MASK -p "/$ITEM"
  ./apos_deploy.sh --from $SRC/$ITEM/$APG_SSHD_CONF --to /$ITEM/$APG_SSHD_CONF
    [ ! $? = 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
done

popd &> /dev/null


apos_outro $0
exit $TRUE

# End of file
