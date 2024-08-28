#!/bin/bash
##
# -----------------------------------------------------------------------------
#             Copyright (C) 2015 Ericsson AB. All rights reserved.
# -----------------------------------------------------------------------------
##
# Name:
#   monitor_exec.sh
# Description:
#   A common library to ease the monitoring of the execution of applications
#   and commands.
# Note:
#   This file is intended to be sourced by the apos_common.sh routines so it
#   MUST be compliant with the bash syntax and his name must end with ".sh".
#   It might also be sourced directly and for this reason it MUST NOT depend on
#   variables and functions defined in apos_common.sh
##
# Usage:
#   None.
##
# Output:
#   None.
##
# Changelog:
# - Tue Sep 15 2015 - Francesco Rainone (efrarai)
#	First version.
##

# global variables
EXHAUSTED=255
[ -z "$TRUE" ] && export TRUE=$(true; echo $?)
[ -z "$FALSE" ] && export FALSE=$(false; echo $?)


# script_builder
##
# The function builds a bash script (under /tmp directory) with the string(s) it
# receives as parameter and prints this script's filename on stdout.
# The created script also contains the sourcing of the present file (this is to
# allow kill_after_try function to nest invocation of try and kill_after
# functions).
# The function also tries to guarantee escape sequences or special characters
# (in particular "\", "\\" and "$") to be preserved.
function script_builder(){
  # str_escape (nested function)
  ##
  # The function operates the following transformation on the input string:
  #   \ character becomes \\
  #   \\ sequence becomes \\\\
  #   $ character becomes \$
  function str_escape(){
    echo -E "$*" | sed -e 's@\\@\\\\@g' -e 's@\\\\@\\\\\\\\@g' -e 's@\$@\\\$@g'
  }

  local tmpscript=$(mktemp -t ${FUNCNAME}_XXXX.sh)
  chmod +x ${tmpscript}
  echo "#!/bin/bash" >${tmpscript}
  echo ". /opt/ap/apos/conf/apos_common_res/monitor_exec.sh" >>${tmpscript}
  echo -e "$(str_escape $*)" >>${tmpscript}
  echo "exit \$?" >>${tmpscript}
  echo ${tmpscript}
}


# try
##
# usage:
#   try <attempts> <interval> <command> [<argument1> ... <argumentN>]
##
# The function executes <command> for a maximum of <attempts> times and waits
# <interval> seconds between each attempt. It returns <command>'s return code
# upon completion, $EXHAUSTED in the case the command has failed for all
# available attempts, $FALSE in the case of wrong usage.
function try(){
  if [ $# -lt 3 ]; then
    echo "wrong number of parameters ($#)" >&2
    return $FALSE
  elif [[ ! $1 =~ ^[0-9]+$ ]]; then
    echo "positive integer expected (found \"$1\")" >&2
    return $FALSE
  elif [[ ! $2 =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "positive decimal expected (found \"$2\")" >&2
    return $FALSE
  else
    local MAX_ATTEMPTS=$1
    local SLEEP_TIME=$2
    shift; shift
    local COMMANDLINE=$@
    local script=$(script_builder "$COMMANDLINE")
    
    for ((i=0; i<${MAX_ATTEMPTS}; i++)); do
      ${script}
      local RETCODE=$?
      if [ $RETCODE -eq $TRUE ]; then
        rm -f ${script}
        return $RETCODE
      fi
      sleep ${SLEEP_TIME}
    done
    rm -f ${script}
    return $EXHAUSTED
  fi
}


# kill_after
##
# usage:
#   kill_after <timeout> <command> [<argument1> ... <argumentN>]
##
# The function executes <command> and awaits for its completion for a maximum of
# <timeout> seconds before interrupting (SIGINT) the process.
# If after <timeout>+2 seconds the process is still executing (SIGINT has not 
# successfully interrupted it), SIGKILL gets sent.
# The function returns 124 if timeout has expired before command completion,
# $FALSE in the case of wrong usage or the return code of $COMMAND otherwise.
function kill_after(){
  if [ $# -lt 2 ]; then
    echo "wrong number of parameters ($#)" >&2
    return $FALSE
  elif [[ ! $1 =~ ^[0-9]+$ ]]; then
    echo "positive integer expected (found \"$1\")" >&2    
    return $FALSE
  else
    local SIGINT_TMOUT=$1
    shift
    local SIGKILL_TMOUT=$((${SIGINT_TMOUT}+2))
    local COMMANDLINE=$@
    local script=$(script_builder "$COMMANDLINE")
    /usr/bin/timeout --signal=INT --kill-after=${SIGKILL_TMOUT} ${SIGINT_TMOUT} ${script}
    local return_code=$?
    rm -f ${script}
    return ${return_code}
  fi
}


# kill_after_try
##
# usage:
#   kill_after_try <attempts> <interval> <timeout> <command> [<argument1> ... <argumentN>]
##
# The function executes <command> for a maximum of <attempts> times and waits
# <interval> seconds between each attempt. If each command invocation does not
# terminate after <timeout> seconds, it gets interrupted (SIGINT).
# If after <timeout>+2 seconds the process is still executing (SIGINT has not 
# successfully interrupted it), SIGKILL gets sent.
# The function returns 124 if timeout has expired before command completion,
# 255 ($EXHAUSTED) if the command doesn't suceed after <attempts> attempts,
# $FALSE in the case of wrong usage or the return code of $COMMAND otherwise.
function kill_after_try(){
  if [ $# -lt 4 ]; then
    echo "wrong number of parameters ($#)" >&2
    return $FALSE
  else
    local MAX_ATTEMPTS=$1
    local SLEEP_TIME=$2
    local SIGINT_TMOUT=$3
    shift; shift; shift
    local COMMANDLINE=$@
    local script=$(script_builder "$COMMANDLINE")
    try $MAX_ATTEMPTS $SLEEP_TIME kill_after $SIGINT_TMOUT ${script}
    local return_code=$?
    rm -f ${script}
    return ${return_code}
  fi
}
