#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       logm_export_location.sh
# Description:
#       A script to change temp location for logm export action from temp to /var/log/logm
#       this script handles to set the timout value to export 4GB data
#
# Note:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Wed Mar 6 2024 - zgxxnav
#       set the timout value to export 4GB data 
# - Mon Jul 18 2021 - xcsrpad
#       First version.
##

# Load apos common functions
. /opt/ap/apos/conf/apos_common.sh


logm_dir='/var/log/logm'
logm_timeout='100'
function create_logmdir(){
  # Create the directory /var/log/logm
  if [ ! -d $logm_dir ]; then
    mkdir -p -m 0775 $logm_dir || apos_log "Failure while creating $logm_dir"
  fi
}

function create_temp_log_export(){
    #changing temp location for logm export action from temp to /var/log/logm
  if [ -s /usr/sbin/lde-logm-export-config ] && [ -d $logm_dir ]  ; then
    /usr/sbin/lde-logm-export-config -t $logm_dir || apos_log "Failure while configuring new log export file destination"
  else 
   apos_log "lde-logm-export-config is not present unable to change temp location for logm export action" 
  fi
}

function set_timeout_log_export(){
     # set the timout value to export 4GB data		
  if [ -s /usr/sbin/lde-logm-export-config ]  ; then
    /usr/sbin/lde-logm-export-config -i $logm_timeout || apos_log "Failure while adding log timeout"
  else
   apos_log "lde-logm-export-config is not present unable to change log time out location for logm export action"
  fi
}


#### M A I N #####

apos_intro "$0"

VERSION=$(lde-info  | grep -i Numeric | awk -F ' ' '{print $3}' | awk -F '.' '{print $1"."$2}')
if [[ -n "$VERSION" && "$VERSION" < '4.18' ]];then
    apos_log "LDE VERSION:[$VERSION] skipping creation of temp location for logm export action"
  else
  {
    apos_log "LDE VERSION:[$VERSION]  creating of temp location for logm export action"
    # Create logm directory in /var/log/logm path
    create_logmdir
    # Create temporary location for logm export action
    create_temp_log_export
    # set the timout value to export 4GB data  
    set_timeout_log_export
  }
fi
 
apos_outro "$0"

exit $TRUE

#END
