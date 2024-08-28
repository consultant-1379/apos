#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_menu-lst.sh
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

# Copy the right menu.lst file
APOS_HW_TYPE=`./apos_hwtype.sh`
if [ ! -z "$APOS_HW_TYPE"  ]; then
	cp boot_"$APOS_HW_TYPE".conf /boot/grub/menu.lst
else
	apos_abort 1 "found unsupported hardware type" >&2	
fi

apos_outro $0
exit $TRUE

# End of file