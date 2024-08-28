#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_profile-local.sh
# Description:
#       A script to configure /etc/profile.local file on AP2 installations.
##
# Output:
#       None.
##
# Changelog:
# - Mon Jan 31 2022 - Sowjanya Medak (xsowmed)
#   Removed Telnet ports for mts server connection
# - Thu May 02 2019 - Suryanarayana Pammi (xpamsur)
#   	Adapting COM environmental variables for remote ip address and port number
# - Mon Jan 13 2017 - Avinash Gundlapally (xavigun)
#	Impacts for ssh subsystem support.
# - Fri Mat 11 2016 - Antonio Buonocunto (eanbuon)
#       Fix for mss.
# - Sat Feb 6 2016 - Antonio Buonocunto (eanbuon)
#       Adaptation to system-oam group.
# - Mon Feb 29 2016 - Baratam Swetha (xswebar)
# Fix for TR HU53683
# - Wed Sep 09 2015 - Francesco D'Errico (xfraerr)
# Impacts for BackPlane hardening (OP#423 Issue 2).
# - Thu June 30 2015 - Antonio Buonocunto (eanbuon)
# LA PH0 Adaptation.
# - Wed Mar 03 2013 - Francesco Rainone (efrarai)
# First AP2-specialized version.
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


# Common variables
TRUE=\$( true; echo \$? )
FALSE=\$( false; echo \$? )
LDAPGNAME="system-oam"
TSADMGRP="tsadmin"
USERID=\$(id -u)
USER_IS_CACHED=\$FALSE

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
          exec /opt/com/bin/cliss
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
