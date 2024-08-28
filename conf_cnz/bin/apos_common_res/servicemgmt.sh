#!/bin/bash
##
# -----------------------------------------------------------------------------
#             Copyright (C) 2015 Ericsson AB. All rights reserved.
# -----------------------------------------------------------------------------
##
# Name:
#   servicemgmt.sh
# Description:
#   A common library to ease administer the OS services.
# Note:
#   This file is intended to be sourced by the apos_common.sh routines so it
#   MUST be compliant with the bash syntax and his name must end with ".sh"
##
# Usage:
#apos_service_mgmt	    enable          <SERVICE_NAME> [-s|--start]
#                       disable         <SERVICE_NAME> [-s|--stop]
#                       is_active       <SERVICE_NAME>
#                       is_enabled      <SERVICE_NAME>
#                       is_failed       <SERVICE_NAME>
#                       is_running      <SERVICE_NAME>
#                       list            <all| service| socket>
#                       reload          <SERVICE_NAME> --type=[config| service]
#			                  restart         <SERVICE NAME>
#                       start           <SERVICE NAME> [-f|--force]
#                       status          <SERVICE NAME>
#                       stop            <SERVICE NAME> [-f|--force]
#                       subscribe       <SERVICE_NAME> "<ACTION>" "<COMMAND>"
##
# Output:
#   None.
##
# Changelog:
# - Mon Mar 14 2022 - Sowjanya GVL (xsowgvl)
#   Restarting rsyslog service using lde-syslog api.
# - Mon Oct 17 2016 - Francesco Rainone (efrarai)
#   Verbosity improvement.
# - Fri Nov 20 2015 - Antonio Buonocunto (eanbuon)
#   First version.
##
CMD_SYSTEMCTL='/usr/bin/systemctl'
CMD_ECHO='/usr/bin/echo'

# Usage: log_error <message_string> [<verbose_error_file>]
# It logs, using the apos_log function, the string <message> as well as the
# content of the optional file <verbose_error_file>.
function log_error(){
  local logprio='user.crit'
  local message_string="$1"
  local verbose_error_file="$2"
  apos_log $logprio "$message_string"
  if [ -n "${verbose_error_file}" ]; then
    if [ -r "$verbose_error_file" ]; then
      apos_log $logprio "BEGIN: $verbose_error_file"
      while read line; do
        apos_log $logprio "$line"
      done < $verbose_error_file
      apos_log $logprio "END: $verbose_error_file"
    else
      apos_log $logprio "file \"${verbose_error_file}\" not found or not readable."
    fi
  fi
}

# The function returns if the action is supposed to return a status or not.
# This is used for the retry mechanism to understand if a non-zero return code
# is to be treated as a retry condition or not.
function not_a_status_action(){
  case $1 in
    is_active|is_failed|is_enabled|is_running|status)
      return $FALSE
    ;;
  esac
  return $TRUE
}

# Function apos_servicemgmt_is_input_enabled requires:
# two parameters (short and long version) of the option that should be checked
function apos_servicemgmt_is_input_enabled(){
  if [ -z "$1" ] || [ -z "$2" ];then
    apos_abort "Invalid usage for function apos_servicemgmt_is_input_enabled"
  fi
  local OPTION="$FALSE"
  for i in $OPT_INPUT;do
    if [ "$i" = "$1" ] || [ "$i" = "$2" ];then
      OPTION="$TRUE"
    fi
  done
  echo $OPTION
}

function apos_servicemgmt(){
  local SERVICEMGMT_TMP_FILE=$(mktemp --tmpdir apos_servicemgmt.XXXXX)
  local MAX_ATTEMPTS=4;
  local OPT_ACTION="$1"
  if [ -z "$OPT_ACTION" ];then
    apos_abort "No argument specified for function apos_servicemgmt"
  fi
  local OPT_SERVICE="$2"
  if [ -z "$OPT_SERVICE" ];then
    apos_abort "No service(s) specified for function apos_servicemgmt"
  fi

  OPT_INPUT=$(echo $@|awk '{print substr($0, index($0,$3))}')
  adhoc_function="apos_servicemgmt_${OPT_ACTION}"

  # this routine tries to execute the adhoc function for at most MAX_ATTEMPTS
  # times before giving up (only once if it's a status function, instead).
  for ((attempt=0; attempt<$MAX_ATTEMPTS; attempt++)); do
    # Check if $adhoc_function is defined, otherwise throw an error.
    if type -t ${adhoc_function} | grep -q '^function$'; then      
      ${adhoc_function} $OPT_INPUT
      return_code=$?
    else
      apos_abort "Invalid action $OPT_ACTION specified"
    fi
    
    # if the return code is non-zero and the action is not supposed to return a
    # status, then log an error and try again (otherwise break the cycle).
    if [ $return_code -ne $TRUE ] && not_a_status_action $OPT_ACTION; then
      log_error "failure while executing \"${adhoc_function}\" (return code is ${return_code}). Retrying"
    else
      break
    fi
    # sleep_time increases exponentially from 1 second to 2^$MAX_ATTEMPTS seconds.
    sleep_time=$(echo "2 ^ $attempt"|bc)
    sleep $sleep_time  
  done
  rm $SERVICEMGMT_TMP_FILE &>/dev/null
  return $return_code
}

# Function apos_servicemgmt_status returns:
#       0 - if service is running
#       1 - if service is not running
# A service is considered running if:
#       LoadState=loaded
#       ActiveState=active
#       SubState=exited
function apos_servicemgmt_status(){
  local LOAD_STATE=$($CMD_SYSTEMCTL show --property=LoadState $OPT_SERVICE | awk -F'=' '{print $2}')
  local ACTIVE_STATE=$($CMD_SYSTEMCTL show --property=ActiveState $OPT_SERVICE | awk -F'=' '{print $2}')
  local SUB_STATE=$($CMD_SYSTEMCTL show --property=SubState $OPT_SERVICE | awk -F'=' '{print $2}')
  local SUB_STATE_RESULT="NOTOK"
  if [[ $OPT_SERVICE =~ .*.socket$ ]]; then
    if [ "$SUB_STATE" = "listening" ];then
      SUB_STATE_RESULT="OK"
    fi
  elif [[ $OPT_SERVICE =~ .*.service$ ]]; then
    if [ "$SUB_STATE" = "running" ];then
      SUB_STATE_RESULT="OK"
    fi
  fi
  if [ "$LOAD_STATE" = "loaded" ] && [ "$ACTIVE_STATE" = "active" ] && [ "$SUB_STATE_RESULT" = "OK" ];then
    apos_log "apos_servicemgmt status for $OPT_SERVICE: Ok"
    echo $TRUE
    return 0
  else
    log_error "apos_servicemgmt status for $OPT_SERVICE: Not Ok"
    echo $FALSE
    return 1
  fi
}

# Function apos_servicemgmt_stop returns:
#       0 - if service is successfully stopped
#       1 - if service is not successfully stopped
# with option --force the "no-block" flag will be added.
# Do not synchronously wait for the requested operation to finish. If
# this is not specified, the job will be verified, enqueued and
# systemctl will wait until it is completed. By passing this
# argument, it is only verified and enqueued.
function apos_servicemgmt_stop(){
  local OPT_FORCE=$(apos_servicemgmt_is_input_enabled -f --force)
  if [ "$OPT_FORCE" = "$TRUE" ];then
        $CMD_SYSTEMCTL stop $OPT_SERVICE --no-block &> $SERVICEMGMT_TMP_FILE
  else
        $CMD_SYSTEMCTL stop $OPT_SERVICE &> $SERVICEMGMT_TMP_FILE
  fi
  if [ $? -eq 0 ];then
    apos_log "apos_servicemgmt stop $OPT_FORCE for $OPT_SERVICE: Done"
    echo $TRUE
    return 0
  else
    log_error "apos_servicemgmt stop $OPT_FORCE for $OPT_SERVICE: Failed" $SERVICEMGMT_TMP_FILE
    echo $FALSE
    return 1
  fi
}

# Usage: apos_servicemgmt_subscribe subscribe "<unit_file>" "<unit_action>" "<unit_commandline>"
# Function apos_servicemgmt_subscribe returns:
#       0 - if command is successfully subscribed in unit file for the specified
#           action.
#       1 - in the case of unrecoverable failure.
function apos_servicemgmt_subscribe(){
  local unit_name="$OPT_SERVICE";
  local unit_action="$1";
  shift
  local unit_commandline="$*";
  local unit_dirs="/usr/lib/systemd/system/ /etc/systemd/system"
  local unit_action_regex='^(Exec)?(StartPre$|StartPost$|StopPost$)'
  local unit_command=$(echo $unit_commandline| awk '{print $1}')  
  
  local unit_file=$(find $unit_dirs -name "$unit_name"|head -1);
  if [ -z "$unit_file" ]; then
    log_error "no unit file named \"$unit_name\" found in $unit_dirs"
    echo $FALSE
    return 1
  else
    apos_log "unit file found at the following path: $unit_file"
  fi
  
  if [[ ! "$unit_action" =~ $unit_action_regex ]]; then
    log_error "action \"$unit_action\" doesn't match regex \"$unit_action_regex\""
    echo $FALSE
    return 1
  else
    apos_log "\"$unit_action\" is recognized as a valid action"
  fi
  
  if [ ! -x "$unit_command" ]; then
    apos_log "WARNING: command \"$unit_command\" not found or not executable."
  else
    apos_log "command \"$unit_command\" is recognized as a valid executable"
  fi
  local return_code=0;
  case $unit_action in
    *StartPre)
      sed -i -r "/ExecStart=/ i ExecStartPre=-$unit_commandline" $unit_file &>$SERVICEMGMT_TMP_FILE
      return_code=$?
    ;;
    *StartPost)
      sed -i -r "/ExecStart=/ a ExecStartPost=-$unit_commandline" $unit_file &>$SERVICEMGMT_TMP_FILE
      return_code=$?
    ;;
    *StopPost)
      sed -i -r "/ExecStop=/ a ExecStopPost=-$unit_commandline" $unit_file &>$SERVICEMGMT_TMP_FILE
      return_code=$?
    ;;
  esac  
  if [ $return_code -eq 0 ];then
    apos_log "apos_servicemgmt subscribe for $OPT_SERVICE: Done"
  else
    log_error "apos_servicemgmt subscribe for $OPT_SERVICE: Failed" $SERVICEMGMT_TMP_FILE
    echo $FALSE
    return 1
  fi

  apos_servicemgmt reload $unit_name --type=service
  if [ $? -eq 0 ];then
    apos_log "apos_servicemgmt reload for $unit_name: Done"
  else
    log_error "apos_servicemgmt reload for $unit_name: Failed" $SERVICEMGMT_TMP_FILE
    echo $FALSE
    return 1
  fi

  echo $TRUE
  return 0
}

# Function apos_servicemgmt_start returns:
#       0 - if service is successfully started
#       1 - if service is not successfully started
# with option --force the "no-block" flag will be added.
# Do not synchronously wait for the requested operation to finish. If
# this is not specified, the job will be verified, enqueued and
# systemctl will wait until it is completed. By passing this
# argument, it is only verified and enqueued.
function apos_servicemgmt_start(){
  local OPT_FORCE=$(apos_servicemgmt_is_input_enabled -f --force)
  if [ "$OPT_FORCE" = "$TRUE" ];then
        $CMD_SYSTEMCTL start $OPT_SERVICE --no-block &> $SERVICEMGMT_TMP_FILE
  else
        $CMD_SYSTEMCTL start $OPT_SERVICE &> $SERVICEMGMT_TMP_FILE
  fi
  if [ $? -eq 0 ];then
    apos_log "apos_servicemgmt start $OPT_FORCE for $OPT_SERVICE: Done"
    echo $TRUE
    return 0
  else
    log_error "apos_servicemgmt start $OPT_FORCE for $OPT_SERVICE: Failed" $SERVICEMGMT_TMP_FILE
    echo $FALSE
    return 1
  fi
}

# Function apos_servicemgmt_is_enabled returns:
#+------------------+---------------------+--------------+
#|Printed string    | Meaning             | Return value |
#+------------------+---------------------+--------------+
#|"enabled"         | Enabled through a   |              |
#+------------------+ symlink in .wants   |              |
#|"enabled-runtime" | directory           | 0            |
#|                  | (permanently or     |              |
#|                  | just in /run).      |              |
#+------------------+---------------------+--------------+
#|"linked"          | Made available      |              |
#+------------------+ through a symlink   |              |
#|"linked-runtime"  | to the unit file    | 1            |
#|                  | (permanently or     |              |
#|                  | just in /run).      |              |
#+------------------+---------------------+--------------+
#|"masked"          | Disabled entirely   |              |
#+------------------+ (permanently or     | 1            |
#|"masked-runtime"  | just in /run).      |              |
#+------------------+---------------------+--------------+
#|"static"          | Unit file is not    | 0            |
#|                  | enabled, and has no |              |
#|                  | provisions for      |              |
#|                  | enabling in the     |              |
#|                  | "[Install]"         |              |
#|                  | section.            |              |
#+------------------+---------------------+--------------+
#|"indirect"        | Unit file itself is | 0            |
#|                  | not enabled, but it |              |
#|                  | has a non-empty     |              |
#|                  | Also= setting in    |              |
#|                  | the "[Install]"     |              |
#|                  | section, listing    |              |
#|                  | other unit files    |              |
#|                  | that might be       |              |
#|                  | enabled.            |              |
#+------------------+---------------------+--------------+
#|"disabled"        | Unit file is not    | 1            |
#|                  | enabled.            |              |
#+------------------+---------------------+--------------+
function apos_servicemgmt_is_enabled(){
  $CMD_SYSTEMCTL is-enabled $OPT_SERVICE --quiet
  if [ $? -eq 0 ];then
    apos_log "apos_servicemgmt service $OPT_SERVICE is enabled : True"
    echo $TRUE
    return 0
  else
    apos_log "apos_servicemgmt service $OPT_SERVICE is enabled : False"
    echo $FALSE
    return 1
  fi
}

# Function apos_servicemgmt_is_failed returns:
#       0 - if service is failed
#       1 - if service is not in failed state
function apos_servicemgmt_is_failed(){
  #systemctl returns:
  # 1 in case of active or inactive
  # 0 only in case of failed
  $CMD_SYSTEMCTL is-failed $OPT_SERVICE --quiet
  if [ $? -eq 0 ];then
    apos_log "apos_servicemgmt service $OPT_SERVICE is failed : True"
    echo $TRUE
    return 0
  else
    apos_log "apos_servicemgmt service $OPT_SERVICE is enabled : False"
    echo $FALSE
    return 1
  fi
}

# Function apos_servicemgmt_is_active returns:
#       0 - if service is active
#       1 - if service is not active
function apos_servicemgmt_is_active(){
  #systemctl returns:
  # 0 in case of active(running) and active(exited)
  # 3 in case of inactive
  $CMD_SYSTEMCTL is-active $OPT_SERVICE --quiet
  if [ $? -eq 0 ];then
    apos_log "apos_servicemgmt service $OPT_SERVICE is active : True"
    echo $TRUE
    return 0
  else
    apos_log "apos_servicemgmt service $OPT_SERVICE is active : False"
    echo $FALSE
    return 1
  fi
}

# Function apos_servicemgmt_is_running returns:
#       0 - if service is running (SubState=running)
#       1 - if service is not running (SubState!=running)
function apos_servicemgmt_is_running(){
  local SUB_STATE=$($CMD_SYSTEMCTL show --property=SubState $OPT_SERVICE | awk -F'=' '{print $2}')
  if [ "$SUB_STATE" = "running" ];then
    apos_log "apos_servicemgmt service $OPT_SERVICE is running : True"
    echo $TRUE
    return 0
  else
    apos_log "apos_servicemgmt service $OPT_SERVICE is running : False"
    echo $FALSE
    return 1
  fi
}

# Function apos_servicemgmt_restart returns:
#       0 - if service is successfully restarted
#       1 - if service is not successfully restarted
function apos_servicemgmt_restart(){
  LDE_SYSLOG_API=lde-syslog
  if [ "$OPT_SERVICE" = "rsyslog.service" ];then
    apos_log "apos_servicemgmt restart for $OPT_SERVICE using lde-syslog api : Done"
    $LDE_SYSLOG_API restart &> $SERVICEMGMT_TMP_FILE 
  else
  #systemctl returns always 0 also if process is not able to run after restart
  $CMD_SYSTEMCTL restart $OPT_SERVICE &> $SERVICEMGMT_TMP_FILE
  fi
  if [ $? -eq 0 ];then
    apos_log "apos_servicemgmt restart for $OPT_SERVICE : Done"
    echo $TRUE
    return 0
  else
    log_error "apos_servicemgmt restart for $OPT_SERVICE : Failed" $SERVICEMGMT_TMP_FILE
    echo $FALSE
    return 1
  fi
}

# Function apos_servicemgmt_enable returns:
#       0 - if service is successfully enabled
#       1 - if service is not successfully enabled
#Enable one or more unit files or unit file instances, as specified
#on the command line. This will create a number of symlinks as
#encoded in the "[Install]" sections of the unit files. After the
#symlinks have been created, the systemd configuration is reloaded
#(in a way that is equivalent to daemon-reload) to ensure the
#changes are taken into account immediately. Note that this does not
#have the effect of also starting any of the units being enabled. If
#this is desired, a separate start command must be invoked for the
#unit.
function apos_servicemgmt_enable(){
  local OPT_START=$(apos_servicemgmt_is_input_enabled -s --start)
  $CMD_SYSTEMCTL enable $OPT_SERVICE --force &> $SERVICEMGMT_TMP_FILE
  if [ $? -eq 0 ];then
    if [ "$OPT_START" = "$TRUE" ];then
      apos_servicemgmt_start $OPT_SERVICE
    else
      apos_log "apos_servicemgmt enable for $OPT_SERVICE : Done"
      echo $TRUE
      return 0
    fi
  else
    log_error "apos_servicemgmt enable for $OPT_SERVICE : Failed" $SERVICEMGMT_TMP_FILE
    echo $FALSE
    return 1
  fi
}

# Function apos_servicemgmt_disable returns:
#       0 - if service is successfully disabled
#       1 - if service is not successfully disabled
#Disables one or more units. This removes all symlinks to the specified unit files from the unit configuration directory,
#and hence undoes the changes made by enable. Note however that this removes all symlinks to the unit files (i.e. including manual additions),
#not just those actually created by enable.
#This call implicitly reloads the systemd daemon configuration after completing the disabling of the units.
#Note that this command does not implicitly stop the units that are being disabled
#If this is desired, either --now should be used together with this command, or an additional stop command should be executed afterwards.
function apos_servicemgmt_disable(){
  local OPT_STOP=$(apos_servicemgmt_is_input_enabled -s --stop)
  $CMD_SYSTEMCTL disable $OPT_SERVICE --force &> $SERVICEMGMT_TMP_FILE
  if [ $? -eq 0 ];then
    if [ "$OPT_STOP" = "$TRUE" ];then
      apos_servicemgmt_stop $OPT_SERVICE
    else
      log_error "apos_servicemgmt disable for $OPT_SERVICE : Done" $SERVICEMGMT_TMP_FILE
      echo $TRUE
      return 0
    fi
  else
    apos_log "apos_servicemgmt disable for $OPT_SERVICE : Failed"
    echo $FALSE
    return 1
  fi
}

# Function apos_servicemgmt_reload returns:
#       0 - if service is successfully reloaded
#       1 - if service is not successfully reloaded.
# If type is equal to:
#       config:         a reload will be called causing the reload of the service-specific configuration, not the unit configuration file of systemd.
#       service:        a daemon-reload will be called causing the Reload the systemd manager configuration.
#                       This will rerun all generators (see systemd.generator(7)), reload all unit files, and recreate the entire dependency tree.
#                       While the daemon is being reloaded, all sockets systemd listens on behalf of user configuration will stay accessible.
function apos_servicemgmt_reload(){
  local OPT_TYPE=$(echo $1 | awk -F'=' '{print $2}')
  if [ "$OPT_TYPE" != "config" ] && [ "$OPT_TYPE" != "service" ];then
    apos_abort "Invalid option specified for apos_servicemgmt_reload: $OPT_TYPE"
  fi
  if [ "$OPT_TYPE" = "config" ];then
    $CMD_SYSTEMCTL reload $OPT_SERVICE --force &> $SERVICEMGMT_TMP_FILE
  elif [ "$OPT_TYPE" = "service" ];then
    $CMD_SYSTEMCTL daemon-reload --force &> $SERVICEMGMT_TMP_FILE
  fi
  if [ $? -eq 0 ];then
    apos_log "apos_servicemgmt reload $OPT_TYPE for $OPT_SERVICE : Done"
    echo $TRUE
    return 0
  else
    log_error "apos_servicemgmt reload $OPT_TYPE for $OPT_SERVICE : Failed" $SERVICEMGMT_TMP_FILE
    echo $FALSE
    return 1
  fi
}

# Function apos_servicemgmt_list returns:
#       0 - if services are successfully printed
#       1 - if services are not successfully printed.
function apos_servicemgmt_list(){
  if [ -e $SERVICEMGMT_TMP_FILE ];then
    if [ "$OPT_SERVICE" = "all" ];then
      $CMD_SYSTEMCTL -l --all &> $SERVICEMGMT_TMP_FILE
    elif [ "$OPT_SERVICE" = "service" ];then
      $CMD_SYSTEMCTL -l --type=service  &> $SERVICEMGMT_TMP_FILE
    elif [ "$OPT_SERVICE" = "socket" ];then
      $CMD_SYSTEMCTL -l --type=socket  &> $SERVICEMGMT_TMP_FILE
    else
      log_error "apos_servicemgmt list failure: Invalid $OPT_SERVICE"
      echo $FALSE
      return 1
    fi
    if [ $? -ne 0 ];then
      log_error "apos_servicemgmt list failed" $SERVICEMGMT_TMP_FILE
      echo $FALSE
      return 1
    fi
    $CMD_CAT $SERVICEMGMT_TMP_FILE
    rm -f $SERVICEMGMT_TMP_FILE
    return 0
  else
    log_error "temporary file \"$SERVICEMGMT_TMP_FILE\" not found"
    echo $FALSE
    return 1
  fi
}

