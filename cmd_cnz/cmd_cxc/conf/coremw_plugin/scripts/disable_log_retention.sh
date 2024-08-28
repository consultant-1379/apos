#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       disable_log_retention.sh
# Description:
#       A script to disable log retention for registered LogM log streams
#
# Note:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Mon Jul 6 2021 - zprapxx
#       First version.
##

# Load apos common functions
. /opt/ap/apos/conf/apos_common.sh


CMD_CUT='/usr/bin/cut'
CMD_CAT='/usr/bin/cat'
CMD_GREP='/usr/bin/grep'
disable_logretention()
{ 

apos_log "Entering the function disable_logretention()"

local logstreams=""
local rcode=""
local stream=""
local cmd_immcfg='/usr/bin/immcfg'
local cmd_immfind='/usr/bin/immfind'
#checking for the presence of log streams
logstreams=$(kill_after_try 2 1 2 $cmd_immfind | $CMD_GREP ^"logId=".*",CmwLogMlogMId=1" | $CMD_CUT -d "=" -f 2 | $CMD_CUT -d "," -f 1 2>/dev/null)
rcode=$?

if [[ -n $logstreams && $rcode -eq 0 ]]; then

   for stream in ${logstreams[@]}; do
     rcode=1
     rcode= $(kill_after_try 2 1 2 $cmd_immcfg -a logRetentionHousekeeping=0 logId=$stream,CmwLogMlogMId=1 2>/dev/null)
     if [[  $rcode -eq 0 ]]; then
       apos_log "Log retention for $stream LOCKED successfully"
     else
       apos_log "Disabling Log retention for $stream unsuccessful"
     fi
   done
else
  apos_log "Unable to fetch the log streams from LogM MO"
fi

}


#### M A I N #####

apos_intro "$0"

logm_file="/opt/ap/apos/conf/logm_info.conf"

if [ -e $logm_file ]; then

  logm_result=$($CMD_CAT $logm_file | $CMD_GREP "LOGM_FIRST_UPGRADE" | $CMD_CUT -d : -f 2 )
  if [[ -n $logm_result && "$logm_result" == "YES" ]]; then
    apos_log "Disable log retention for LogM registered streams"

    disable_logretention

    #reset the value in logm_conf.sh file
   sed -i 's/LOGM_FIRST_UPGRADE:YES/LOGM_FIRST_UPGRADE:NO/' $logm_file
   if [ $? -ne 0 ]; then
        apos_log "Failure setting the value in logm_info.conf file "
   else
        apos_log "Successfully modified the value in logm_info.conf file"
   fi

  else
    apos_log "Do not disable the log retention, LogM framework already present"
  fi
else
   apos_log "$logm_file file not present" 
fi

apos_outro "$0"

exit $TRUE

#END

