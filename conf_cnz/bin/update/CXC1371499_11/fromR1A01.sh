#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2019 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       fromR1A01.sh
# Description:
#       A script to update APOS_OSCONFBIN from the next version.
# Note:
#       None.
##
# Changelog:
# - Tue Dec 3 2019 - Yeswanth Vankayala (xyesvan)
#      COM Shipment Integration
# - Tue Nov 26  2019 - Sowmya Pola (xsowpol) 
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

#Common variables
CFG_PATH='/opt/ap/apos/conf'
SRC='/opt/ap/apos/etc/deploy'

# This function will align the SEC SSH MO with ssh server configurations in APG
# The below function is framing and triggering an IMM query

function align_sshd_algorithms()
{
local immcfg_cmd="/usr/bin/cmw-utility immcfg"

# Default Ciphers configured in APG sshd configuration files 
local ciphers="aes128-ctr aes256-ctr arcfour256 arcfour"
local csadm_cbc_file='/opt/ap/acs/conf/acs_asec_sshcbc.conf'
local csadm_value=0

if [ -e $csadm_cbc_file ] ; then
    csadm_value=`cat $csadm_cbc_file`
fi

if [ $csadm_value -eq 1 ] ; then
    ciphers=$ciphers" aes128-cbc aes256-cbc"
fi

apos_log 'Aligning the SEC SSH MO with the sshd server properties in APG'

# Framing an IMM query to update the Ciphers in Ssh MO under SecM
temp_str=$immcfg_cmd
for ITEM in $ciphers;do
  temp_str=$temp_str" -a selectedCiphers=$ITEM"
done

temp_str=$temp_str" sshId=1,SecSecMsecMId=1"

apos_log $temp_str

#Triggering IMM query 
kill_after_try 5 1 5 $temp_str &>/dev/null || apos_abort 'Unable to update the SEC SSH MO'

}

# BEGIN: ssh -s support impacts in APG 
pushd $CFG_PATH &> /dev/null
./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_22 --to /etc/ssh/sshd_config_22
if [ $? -ne 0 ]; then
  apos_abort 1 "failure while deploying \"sshd_config_22\" file"
fi

./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_4422 --to /etc/ssh/sshd_config_4422
if [ $? -ne 0 ]; then
  apos_abort 1 "failure while deploying \"sshd_config_4422\" file"
fi

./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_830 --to /etc/ssh/sshd_config_830
if [ $? -ne 0 ]; then
  apos_abort 1 "failure while deploying \"sshd_config_830\" file"
fi

./apos_deploy.sh --from $SRC/etc/ssh/sshd_config_mssd --to /etc/ssh/sshd_config_mssd
if [ $? -ne 0 ]; then
  apos_abort 1 "failure while deploying \"sshd_config_mssd\" file"
fi

./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_sshd-config" --to "/usr/lib/lde/config-management/apos_sshd-config"
if [ $? -ne 0 ]; then
        apos_abort 1 "failure while deploying \"apos_sshd-config\" file"
fi

./apos_insserv.sh /usr/lib/lde/config-management/apos_sshd-config
if [ $? -ne 0 ]; then
        apos_abort "failure while creating symlink to file apos_sshd-config"
fi
popd &>/dev/null

align_sshd_algorithms

# END: ssh -s support impacts in APG

HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
[ -z "$HW_TYPE" ] && apos_abort 1 'HW_TYPE not found'
SHELF_ARCH=$(get_shelf_architecture)


##
# WORKAROUND FOR TR:HX28643 BEGIN
if [ "$HW_TYPE"  == "GEP5" ] && [ "$SHELF_ARCH"  == "SCB" ]; then
        eri-ipmitool wbcsgep5 -b 18 0x30
fi
# WORKAROUND FOR TR:HX28643 END
##

# BEGIN: com configuration handling
pushd $CFG_PATH &>/dev/null
apos_check_and_call $CFG_PATH apos_comconf.sh
popd &>/dev/null
# END: com configuration handling


# R1A01 -> R1A02
#------------------------------------------------------------------------------#
pushd /opt/ap/apos/conf &>/dev/null
./apos_update.sh CXC1371499_11 R1A02
popd &>/dev/null
#------------------------------------------------------------------------------#

apos_outro $0
exit $TRUE

# End of file
