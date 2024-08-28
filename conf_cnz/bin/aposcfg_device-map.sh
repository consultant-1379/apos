#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_device-map.sh
# Description:
#       A script to set the APG43L boot options.
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
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Tue Dec 21 2010 - Francesco Rainone (efrarai)
#	Introduced static-file copy mechanism.
# - Mon Dec 20 2010 - Paolo Palmieri (epaopal)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Modifying device.map 
cat > /boot/grub/device.map << EOF
(hd0) /dev/sda
(hd1) /dev/sdb
(hd2) /dev/sdc
(hd3) /dev/sdd
EOF

apos_outro $0
exit $TRUE

# End of file