#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2024 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_bash-bashrc-local.sh
# Description:
#       A script to set bash-related configuration.
# Note:
#       None.
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Thu Jan 11 2024 - Pravalika (zprapxx)
#       Adding the bash built-in command logging changes(TR IA72765 Fix)
# - Mon Oct 09 2023 - Pravalika (zprapxx)
#       Removing bash built-in command logging changes 
# - Mon Aug 28 2023 - Pravalika (zprapxx)
#       Added changes to enable bash built-in command logging 
# - Mon Jan 04 2016 - Pratap Reddy (xpraupp)
#       Updated with parmtool impacts
# - Tue May 20 2014 - Nikhila Sattala (xniksat)
#       Bash Prompt configuration
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#       Configuration scripts rework.
# - Tue Apr 05 2011 - Paolo Palmieri (epaopal)
#       Prompt fix for TR HN96951.
# - Tue Mar 15 2011 - Francesco Rainone (efrarai)
#       Prompt fix.
# - Tue Dec 21 2010 - Francesco Rainone (efrarai)
#       Massive rework.
# - Tue Dec 21 2010 - Madhu Aravabhumi
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

function check_special_characters()
{
   if [[ "$NODE_NAME" =~ "$" ]]; then
      apos_log "Node Name consists $ special character."

      # Adding Two Back Slashes before $.
      NODE_NAME=$(echo $NODE_NAME | sed 's:[\$]:\\\\&:g')
   fi
   if [[ "$NODE_NAME" =~ '`' ]]; then
      apos_log "Node Name consists back quote."

      # Adding One Back Slash before back quote.
      NODE_NAME=$(echo $NODE_NAME | sed 's:`:\\&:g')
   fi
   if [[ "$NODE_NAME" =~ "'" ]]; then
      apos_log "Node Name consists single quote."

      NODE_NAME=$(echo $NODE_NAME | sed "s:':\'\"\'\"&:g")
   fi
   apos_log "Node name with special characters is '$NODE_NAME'"
}

function get_node_name()
{
   if [ $NODE -eq 1 ]; then
			# get managed element name stored into nodeA_MEId file
			NODE_NAME="$NODE_A_ME"
			if [ -z "$NODE_NAME" ]; then
				apos_log "nodeA_MEId file is empty. Resetting to default value ($DEFAULT_VALUE)"
				NODE_NAME=$DEFAULT_VALUE
			fi
   else
			# get managed element name stored into nodeB_MEId file
			NODE_NAME="$NODE_B_ME"
			if [ -z "$NODE_NAME" ]; then
				apos_log "nodeB_MEId file is empty. Resetting to default value ($DEFAULT_VALUE)"
				NODE_NAME=$DEFAULT_VALUE
			fi
   fi
}

function get_prompt()
{
   ROOT_PROMPT="'"$NODE_NAME"-\h:\003# '"
   apos_log "Prompt for root users $ROOT_PROMPT"

   NON_ROOT_PROMPT="'"$NODE_NAME"-\h:\003$ '"
   apos_log "Prompt for non root users $NON_ROOT_PROMPT"
}

### Main

APHOME="/opt/ap"

DEFAULT_VALUE='1'

NODE_A_ME=$( $CMD_PARMTOOL get --item-list nodeA_MEId \
2>/dev/null | awk -F'=' '{print $2}') 

NODE_B_ME=$( $CMD_PARMTOOL get --item-list nodeB_MEId \
2>/dev/null | awk -F'=' '{print $2}') 

NODE=$( cat /etc/cluster/nodes/this/id)

[ -z $NODE ] && apos_abort "Node Id is empty"

# Get Node Name from node<A/B>_MEId files.
get_node_name

# Handle Special characters in Node Name
check_special_characters

# Get Root and Non-Root Prompts
get_prompt

# Modifying bash.bashrc.local
cat > /etc/bash.bashrc.local << EOF
export AP_HOME="$APHOME"

if test "\$UID" = 0; then
   export PS1=$ROOT_PROMPT
else
   export PS1=$NON_ROOT_PROMPT
fi

#TR IA72765 Fix
#Logging for Bash built-in commands 
if [ -f /etc/bash.bashrc.local.lde-audit-bash-builtin ]; then
      . /etc/bash.bashrc.local.lde-audit-bash-builtin
fi
EOF

source /etc/bash.bashrc.local

apos_outro $0
exit $TRUE

# End of file
