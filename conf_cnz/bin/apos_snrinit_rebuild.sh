#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#               apos_snrinit_rebuild.sh
# Description:
# This command is used to start server and the client process during single 
# node recovery rebuild case.
#
# Usage : apos_snrinit_rebuild.sh --start-server
#         apos_snrinit_rebuild.sh --start-client
#         apos_snrinit_rebuild.sh --is-server-running
#
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

# - Wednesday Sep 21 2016 - Raghavendra Koduri (XKODRAG)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
# ------------------------------------------------------------------------
# script-wide variables
THIS_ID=$(</etc/cluster/nodes/this/id)
PEER_ID=$(</etc/cluster/nodes/peer/id)
THIS_IP=$(</etc/cluster/nodes/all/$THIS_ID/networks/internal/primary/address)
PEER_IP=$(</etc/cluster/nodes/all/$PEER_ID/networks/internal/primary/address)
PORT=1717
SNR_MESSAGE='SNR'
EXIT_CODE=$FALSE
ATTEMPTS=5
INTERVAL=2

# ------------------------------------------------------------------------
# command-list
CMD_NC='/usr/bin/nc'
CMD_RM='/usr/bin/rm'
CMD_NETSTAT='/bin/netstat'
CMD_GREP='/usr/bin/grep'

#------------------------------------------------------------------------------
function is_server_running() {

  try $ATTEMPTS $INTERVAL  "$CMD_NETSTAT -nl | grep -qP "[[:space:]]${THIS_IP//./\\.}:${PORT}[[:space:]]""
  if [ $? -eq 0 ]; then
    return $TRUE
  fi
  
  return $FALSE
}

#------------------------------------------------------------------------------
function kill_opened_sessions(){
  # kill all the sessions opened by us
  count=$( $CMD_NETSTAT -nl  | grep '^tcp' | grep -qP "[[:space:]]${THIS_IP//./\\.}:${PORT}[[:space:]]" | wc -l)
  apos_log "snrinit: found opened sessions: [$count]"

  if [ $count -ne 0 ]; then
    for index in $count; do
      $CMD_NC $PEER_IP $PORT 2>/dev/null
      ((index ++))
    done
  fi

  # check opened sessions now
  count=$( $CMD_NETSTAT -nl  | grep '^tcp' | grep -qP "[[:space:]]${THIS_IP//./\\.}:${PORT}[[:space:]]" | wc -l)
  if [ $count -ne 0 ]; then 
    apos_log "snrinit: failed to close opened sessions. Found [$count] opened sessions"
    return $FALSE
  else
    apos_log "snrinit: all opened sessions are closed now"
  fi

  return $TRUE
}

#------------------------------------------------------------------------------
function start_server()
{
  apos_log "snrinit: start_server ($THIS_IP:$PORT)"  
  local eCode=0

  if ! kill_opened_sessions; then 
    apos_log "snrinit: open sessions found... exiting without starting the server"
    return $FALSE
  fi

  # start server: this call blocks till the client is connected
  # once client is connected it sends SNR strig to client
  try $ATTEMPTS $INTERVAL "echo $SNR_MESSAGE | $CMD_NC -l $THIS_IP $PORT 2>/dev/null"
  eCode=$?
  if [ $eCode -eq 0 ]; then
    apos_log "snrinit: client is connected.. exiting the server"
  else
    apos_log "WARNING (snrinit): server start failed with exit code ($eCode)."
    return $FALSE
  fi

  return $TRUE
}

#------------------------------------------------------------------------------
function start_client()
{
  apos_log "snrinit: start_client ($PEER_IP:$PORT)"
  
  local attempts=3
  local interval=2
  #connect client
  local RESP=$( try $attempts $interval "$CMD_NC $PEER_IP $PORT 2>/dev/null" )

  apos_log "DEBUG (snrinit): response received [$RESP]"
  if [[ -n "$RESP" &&  "$SNR_MESSAGE" == "$RESP" ]]; then
    apos_log "snrinit: client received the response"
  else
    apos_log "snrinit: client has not received the input from server."
    return $FALSE
  fi

  return $TRUE
}

#------------------------------------------------------------------------------
#|    _ _   _  .  _    |
#|   | ) ) (_| | | )   |
#|_____________________|
# Here begins the "main" function...
# Set the interpreter to exit if a non-initialized variable is used.
case $1 in
  --start-server)
    start_server
    EXIT_CODE=$?
    ;;
  --start-client)
    start_client
    EXIT_CODE=$?
    ;;
  --is-server-running)
    is_server_running
    EXIT_CODE=$?
    ;;
  *)
    apos_abort 1 "invalid option."
    ;;
esac

apos_outro $0

exit $EXIT_CODE

# End of file
