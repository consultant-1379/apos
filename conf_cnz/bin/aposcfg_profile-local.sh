#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_profile-local.sh
# Description:
#       A script to configure /etc/profile.local file.
##
# Output:
#       None.
##
# Changelog:
# - Mon Jan 31 2022 - Sowjanya Medak (xsowmed)
#   Removed Telnet ports for mts server connection
# - Thu Sep 10 2020 - Dharma Theja (xdhatej)
#   TR HY62092 Abonormal behavior of LDAP user
# - Tue Feb 18 2020 - Harika Bavana (xharbav)
#   Adding sudo to simucliss command inorder to allow access for IMM.
#   This change is because of CMW NBC for IMM Access Control mode
# - Thu May 02 2019 - Suryanarayana Pammi (xpamsur)
#   Adapting COM environmental variables for remote ip address and port number
# - Tue Feb 28 2017 - Francesco Rainone (efrarai)
#   Moved cached_creds_duration to a local directory (for ensuring login of
#   troubleshooting users also in the case of /cluster unavailability).
# - Mon Feb 13 2017 - Avinash Gundlapally (xavigun)
# Impacts for ssh subsystem support in APG
# - Tue Mar 29 2016 - Alessio Cascone (ealocae)
# Impacts for Cached Credentials in SLES12.
# - Sat Mar 12 2016 - Fabio Ronca (efabron)
# Rebase from APG43L_DM_3_0_5
# - Fri Mat 11 2016 - Antonio Buonocunto (eanbuon)
# Fix for mss.
# - Sat Feb 6 2016 - Antonio Buonocunto (eanbuon)
# Adaptation to system-oam group.
# - Mon Feb 29 2016 - Baratam Swetha (xswebar)
# Fix for TR HU53683
# - Wed Sep 09 2015 - Francesco D'Errico (xfraerr)
# Impacts for BackPlane hardening (OP#423 Issue 2).
# - Thu June 30 2015 - Antonio Buonocunto (eanbuon)
# LA PH0 Adaptation.
# - Fri Jun 13 2014 - Francesco Rainone (efrarai)
# Impacts for cached credentials implementation.
# - Wed Mar 03 2013 - Francesco Rainone (efrarai)
# Login denial for ldap users on serial console.
# - Thu Jan 24 2013 - Francesco Rainone (efrarai)
# Login denial on port 4422 improvement.
# - Wed Nov 13 2012 - Francesco Rainone (efrarai)
# Aliases for tsadmin user added.
# - Fri Sep 14 2012 - Claudia Atteo (eattcla) 
# Fuction added for signals trapping 
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
# Configuration scripts rework.
# - Tue Dec 20 2011 - Francesco Rainone (efrarai)
# Rework to handle telnet sessions.
# - Wed Nov 02 2011 - Paolo Palmieri (epaopal)
# Rework to manage double ssh server configuration.
# - Mon Sep 26 2011 - Paolo Palmieri (epaopal)
# First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Creating the /etc/profile.local file
cat > /etc/profile.local << EOF
#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##

function exit_func() {
  exit 1
}
    
trap exit_func SIGINT SIGTERM SIGHUP

function log() {
  if [ \$# -gt 0 ]; then
    if ! /bin/logger -t 'profile.local' -p 'authpriv.notice' "\$*"; then
      if [[ \$- =~ .*i.* ]]; then
        echo "\$*"
      fi
    fi
  fi
}

function user_has_group(){
        local GROUP="\$1"
        if id -G -n | grep -q -P "^\${GROUP}\$|^\${GROUP}[[:blank:]]|[[:blank:]]\${GROUP}[[:blank:]]|[[:blank:]]\${GROUP}\$"; then
                return \$TRUE
        fi
        return \$FALSE
}

# This function has the purpose to check if the provided user ID belongs to
# a user defined locally (system user, TS user, local user) or remotely on LDAP.
# Syntax: is_ldap_user <user_id>
function is_ldap_user() {
  ### IMPORTANT NOTE ###
  # Change the value of this variable if the lower bound for LDAP users is changed
  local LDAP_USERS_FIRST_UID=1000
  ### IMPORTANT NOTE ###

  local USER_ID=\$1
  if [[ ! "\$USER_ID" =~ ^[0-9]+$ ]]; then
    log "function \$FUNCNAME requires a numeric parameter (found \\\"\${USER_ID}\\\")"
    exit 1
  fi
  if [ \$USER_ID -lt \$LDAP_USERS_FIRST_UID ]; then
    return \$FALSE
  fi
  return \$TRUE
}


# Common variables
TRUE=\$( true; echo \$? )
FALSE=\$( false; echo \$? )
LDAPGNAME="system-oam"
TSADMGRP="tsadmin"
USERID=\$(id -u)
export CLIENT_IP=\$(echo \${SSH_CONNECTION:-\$REMOTEHOST} | /usr/bin/awk '{print \$1}')
export USER_IS_CACHED=\$FALSE
CACHE_DURATION_FILE="/var/home/cached_creds_duration"
CACHE_DURATION=\$(<\$CACHE_DURATION_FILE)

if [[ -n "\$CACHE_DURATION" && \$CACHE_DURATION -ne 0 ]]; then
  if [[ -n \$SSH_CONNECTION || -n \$REMOTEHOST ]]; then
    if is_ldap_user "\$USERID" && [ -x /opt/ap/apos/bin/check_ldap_availability ]; then
      /usr/bin/sudo /opt/ap/apos/bin/check_ldap_availability --retries=1 --timeout=1  
      if [ \$? -eq 1 ]; then
        USER_IS_CACHED=\$TRUE
      fi
    fi    
  fi
fi
  
if [ "\$SSH_CONNECTION" ]; then
  # Read SSH_CONNECTION content
  set -- \$SSH_CONNECTION
  CLIENT_IP=\$1
  CLIENT_PORT=\$2
  SERVER_IP=\$3
  SERVER_PORT=\$4
  SERVER_INTERNAL_IP=\$(cat /etc/cluster/nodes/this/networks/internal/primary/address)
    
  # drop non-root logins on internal network
  if [[ "\$SERVER_IP" == "\$SERVER_INTERNAL_IP" ]]; then
    if [[ \$USERID -ne 0 ]]; then
        log "ERROR: connection to host \$SERVER_IP, port \$SERVER_PORT is not allowed!"
        exit \$FALSE
    fi
  else
    export PORT=\$SERVER_PORT
    case "\$SERVER_PORT" in
      "22")
        if [ "\${BASH_EXECUTION_STRING}" != '/opt/ap/apos/conf/apos_subsystem_wrapper.sh' ]; then
          if [ \$USER_IS_CACHED -eq \$TRUE ]; then
            exec /usr/bin/sudo /opt/ap/apos/bin/simucliss
          else
            exec /opt/com/bin/cliss
          fi
        fi
      ;;
      "830")
        if [ "\${BASH_EXECUTION_STRING}" != '/opt/com/bin/netconf' ]; then
          exec /opt/com/bin/netconf
        fi
      ;;
      "4422")
        CURR_PROC=\$(</proc/\$\$/cmdline)
        if [[ "\$CURR_PROC" =~ .*/opt/ap/apos/conf/apos_logindenial.sh.* ]]; then
                /opt/ap/apos/conf/apos_logindenial.sh
        fi
        unset CURR_PROC

        [[ ! "\$-" =~ .*i.* ]] && exit \$FALSE
        # if group name identifies an ldap/local user, the access on 4422 is denied
        if user_has_group "\$LDAPGNAME"; then
          exit \$FALSE
        fi
      ;;
      "52000")
        [ -x "/usr/bin/mml" ] ||  exit \$FALSE	
        exec /usr/bin/mml
      ;;
      "52001")
        [ -x "/usr/bin/mml" ] ||  exit \$FALSE
        exec /usr/bin/mml -a
      ;;
      "52002")
        [ -x "/usr/bin/mml" ] ||  exit \$FALSE
        exec /usr/bin/mml -n
      ;;
      "52010")
        [ -x "/usr/bin/mml" ] ||  exit \$FALSE
        exec /usr/bin/mml -e
      ;;
      "52011")
        [ -x "/usr/bin/mml" ] ||  exit \$FALSE
        exec /usr/bin/mml -e -a
      ;;
      "52100")
        [ -x "/usr/bin/mml" ] ||  exit \$FALSE
        exec /usr/bin/mml -s
      ;;
      "52101")
        [ -x "/usr/bin/mml" ] ||  exit \$FALSE
        exec /usr/bin/mml -s -a
      ;;
      "52110")
        [ -x "/usr/bin/mml" ] ||  exit \$FALSE
        exec /usr/bin/mml -s -e
      ;;
      "52111")
        [ -x "/usr/bin/mml" ] ||  exit \$FALSE
        exec /usr/bin/mml -s -e -a
      ;;
      *)
        log "ERROR: SSH connection to host \$SERVER_IP, port \$SERVER_PORT is not allowed!"
        exit \$FALSE
      ;;
    esac
  fi
elif [ "\$(/usr/bin/tty)" == '/dev/ttyS0' ]; then
  # if group name identifies an ldap/local user, the access on console is denied
  if user_has_group "\$LDAPGNAME"; then  
    /bin/logger -t 'profile.local' -i -p 'authpriv.alert' "user \"\${USER:-<UNKNOWN_USER>}\" has been rejected access to console session"
    exit \$FALSE
  fi
fi

# reset default handlers for signals
trap - SIGINT SIGTERM SIGHUP

EOF

apos_outro $0
exit $TRUE

# End of file
