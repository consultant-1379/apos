#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_audit-rules.sh
# Description:
#       audit.rules file set up.
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
# - Mon Oct 26 2020 - Sowjanya GVL (xsowgvl)
#       Changes done to align to audit rules NBC introduced in SLES12 SP5
#	From SP5, audit.rules file will be dynamically generated using the files present under /etc/audit/rules.d folder
# - Tue Jan 30 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Wed Nov 16 2011 - Francesco Rainone (efrarai)
#	Changes to be update-compliant.
# - Thu Sep 08 2011 - Paolo Palmieri (epaopal)
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0


echo "Loading augen rules in apscfg_audit-rules.sh"
/sbin/augenrules --load 
[ $? -ne 0 ] && apos_abort "failed to load augenrules"

apos_outro $0
exit $TRUE

# End of file
