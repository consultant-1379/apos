#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apg-ldap.sh
# Description:
#       A script to start the LDAP Server (slapd) daemon.
# Note:
#       The present script is executed during the start phase of the 
#       apg-ldap.service
##
# Usage:
#       None.
##
# Output:
#       None.
##
# Changelog:
# - Thu Jan 21 2016 - Antonio Nicoletti (eantnic) - Crescenzo Malvone (ecremal)
#       First version.
##


# Determine the base and follow a runlevel link name.
base=${0##*/}
link=${base#*[SK][0-9][0-9]}

test -f /etc/sysconfig/openldap && . /etc/sysconfig/openldap

SLAPD_BIN=/usr/lib/openldap/slapd
LDAP_URLS=""
LDAPS_URLS=""
LDAPI_URLS=""
SLAPD_CONFIG_ARG="-F /etc/openldap/slapd.d"
SLAPD_PID_DIR="/var/run/slapd/"

test -x $SLAPD_BIN || exit 5

function init_ldap_listener_urls(){
    case "$OPENLDAP_START_LDAP" in
        [Yy][Ee][Ss])
            if [ -n "$OPENLDAP_LDAP_INTERFACES" ]
            then
                for iface in $OPENLDAP_LDAP_INTERFACES ;do
                    LDAP_URLS="$LDAP_URLS ldap://$iface"
                done
            else
                LDAP_URLS="ldap:///"
            fi
        ;;
    esac
}

function init_ldapi_listener_urls(){
    case "$OPENLDAP_START_LDAPI" in
        [Yy][Ee][Ss])
            if [ -n "$OPENLDAP_LDAPI_INTERFACES" ]
            then
                for iface in $OPENLDAP_LDAPI_INTERFACES ;do
                    esc_iface=`echo "$iface" | sed -e s/\\//\\%2f/g`
                    LDAPI_URLS="$LDAPI_URLS ldapi://$esc_iface"
                done
            else
                LDAPI_URLS="ldapi:///"
            fi
        ;;
    esac
}

function init_ldaps_listener_urls(){
    case "$OPENLDAP_START_LDAPS" in
        [Yy][Ee][Ss])
            if [ -n "$OPENLDAP_LDAPS_INTERFACES" ]
            then
                for iface in $OPENLDAP_LDAPS_INTERFACES ;do
                    LDAPS_URLS="$LDAPS_URLS ldaps://$iface"
                done
            else
                LDAPS_URLS="ldaps:///"
            fi
        ;;
    esac
}

function check_connection(){
        SLAPD_TIMEOUT=10
        START=$( date +%s)
        while [ $(( $( date +%s) - ${START} )) -lt ${SLAPD_TIMEOUT} ]; do
                ldapsearch -x -H "$LDAP_URLS $LDAPI_URLS $LDAPS_URLS" -b "" -s base &>/dev/null
                LDAPSEARCH_RC=$?
                if [ ${LDAPSEARCH_RC} -ge 0 ] && [ ${LDAPSEARCH_RC} -le 80 ] ; then break
                else sleep 1
                fi
        done
}

depth=0;

function chown_database_dirs_bconfig() {
        ldapdir=$(find $1 -type f -name "olcDatabase*" | xargs grep -i olcdbdirectory | awk '{print $2}')
        for dir in $ldapdir; do
                [ -d "$dir" ] && [ -n "$OPENLDAP_USER" ] && \
                        chown -R $OPENLDAP_USER $dir 2>/dev/null
                [ -d "$dir" ] && [ -n "$OPENLDAP_GROUP" ] && \
                        chgrp -R $OPENLDAP_GROUP $dir 2>/dev/null
        done
}

function chown_database_dirs() {
        ldapdir=`grep ^directory $1 | awk '{print $2}'`
        for dir in $ldapdir; do
                [ -d "$dir" ] && [ -n "$OPENLDAP_USER" ] && \
                        chown -R $OPENLDAP_USER $dir 2>/dev/null
                [ -d "$dir" ] && [ -n "$OPENLDAP_GROUP" ] && \
                        chgrp -R $OPENLDAP_GROUP $dir 2>/dev/null
        done
        includes=`grep ^include $1 | awk '{print $2}'`
        if [ $depth -le 50 ]; then
                depth=$(( $depth + 1 ));
                for i in $includes; do
                        chown_database_dirs "$i" ;
                done
        fi
}

USER_CMD=""
GROUP_CMD=""
[ ! "x$OPENLDAP_USER" = "x" ] && USER_CMD="-u $OPENLDAP_USER"
[ ! "x$OPENLDAP_GROUP" = "x" ] && GROUP_CMD="-g $OPENLDAP_GROUP"
[ ! "x$OPENLDAP_CONFIG_BACKEND" = "xldap" ] && SLAPD_CONFIG_ARG="-f /etc/openldap/slapd.conf"


# Return values acc. to LSB for all commands but status:
# 0 - success
# 1 - generic or unspecified error
# 2 - invalid or excess argument(s)
# 3 - unimplemented feature (e.g. "reload")
# 4 - insufficient privilege
# 5 - program is not installed
# 6 - program is not configured
# 7 - program is not running
# 
# Note that starting an already running service, stopping
# or restarting a not-running service as well as the restart
# with force-reload (in case signalling is not supported) are
# considered a success.

if [ -f /etc/openldap/UPDATE_NEEDED ]; then
    echo "  The configuration of your LDAP server needs to be updated."
    echo "  Please see /usr/share/doc/packages/openldap2/README.update"
    echo "  for details."
    echo "  After the update please remove the file:"
    echo "    /etc/openldap/UPDATE_NEEDED"
    exit 6
fi
# chown backend directories if OPENLDAP_CHOWN_DIRS ist set
if [ "$(echo "$OPENLDAP_CHOWN_DIRS" | tr 'A-Z' 'a-z')" = "yes" ]; then
    if [ -n "$OPENLDAP_USER" -o -n "$OPENLDAP_GROUP" ]; then
		if [ -n "$OPENLDAP_CONFIG_BACKEND" -a "$OPENLDAP_CONFIG_BACKEND" = "ldap" ]; then
			chown -R $OPENLDAP_USER /etc/openldap/slapd.d 2>/dev/null
			chgrp -R $OPENLDAP_GROUP /etc/openldap/slapd.d 2>/dev/null
			chown_database_dirs_bconfig "/etc/openldap/slapd.d"
		# assume back-config usage if slapd.conf is not present but slapd.d is
		elif [ ! -f /etc/openldap/slapd.conf -a /etc/openldap/slapd.d ]; then
			chown -R $OPENLDAP_USER /etc/openldap/slapd.d 2>/dev/null
			chgrp -R $OPENLDAP_GROUP /etc/openldap/slapd.d 2>/dev/null
			chown_database_dirs_bconfig "/etc/openldap/slapd.d"
		else
			chown_database_dirs "/etc/openldap/slapd.conf"
			chgrp $OPENLDAP_GROUP /etc/openldap/slapd.conf 2>/dev/null
		fi
		if test -f /etc/sasl2/slapd.conf ; then
                chgrp $OPENLDAP_GROUP /etc/sasl2/slapd.conf 2>/dev/null
                chmod 640 /etc/sasl2/slapd.conf 2>/dev/null
		fi
		if [ -n "$OPENLDAP_KRB5_KEYTAB" ]; then
			keytabfile=${OPENLDAP_KRB5_KEYTAB/#FILE:/}
			if test -f $keytabfile ; then
				chgrp $OPENLDAP_GROUP $keytabfile 2>/dev/null
				chmod g+r $keytabfile 2>/dev/null
			fi
		fi
	fi
fi
if [ -n "$OPENLDAP_KRB5_KEYTAB" ]; then
	export KRB5_KTNAME=$OPENLDAP_KRB5_KEYTAB
fi
case "$OPENLDAP_REGISTER_SLP" in
	[Yy][Ee][Ss])
		SLAPD_SLP_REG="-o slp=on"
		;;
	*)
		SLAPD_SLP_REG="-o slp=off"
		;;
esac

init_ldap_listener_urls
init_ldapi_listener_urls
init_ldaps_listener_urls

if [ ! -d $SLAPD_PID_DIR ]; then
    mkdir -p $SLAPD_PID_DIR
    chown ldap:ldap $SLAPD_PID_DIR
fi

echo "Starting ldap-server"

if ! /bin/bash -c "$SLAPD_BIN -h \"$LDAP_URLS $LDAPS_URLS $LDAPI_URLS\" $SLAPD_CONFIG_ARG $USER_CMD $GROUP_CMD $OPENLDAP_SLAPD_PARAMS $SLAPD_SLP_REG"; then
	echo "Failed to start ldap-server"
	exit 1
fi
