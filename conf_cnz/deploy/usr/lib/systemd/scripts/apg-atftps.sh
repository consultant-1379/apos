#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apg-atftps.sh
# Description:
#       A script to start the AFTP daemon.
# Note:
#       The present script is executed during the start and stop phases of the 
#       apg-atftps.service
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

. /opt/ap/apos/conf/apos_common.sh

start_atftpd_server() {

	if [[ -n "$ATFTPD_BIND_ADDRESSES_SC1" && -n "$ATFTPD_BIND_ADDRESSES_SC2" ]]; then
		THIS=$(cat /etc/cluster/nodes/this/id)
		if [ $THIS  == '1' ]; then
			ATFTPD_BIND_ADDRESSES=$ATFTPD_BIND_ADDRESSES_SC1
		else
			ATFTPD_BIND_ADDRESSES=$ATFTPD_BIND_ADDRESSES_SC2
		fi
		for IP in $ATFTPD_BIND_ADDRESSES; do
			echo "Starting Advanced Trivial FTP server on $IP"
			# Check if the IP address is assigned to an interface
			if [ $(ifconfig | grep $IP | wc -l) == '0' ]; then
				panic "IP address $IP is not assigned to an interface"
			fi
            apos_servicemgmt start apg-atftpd\@$IP.service &>/dev/null 
    done
	else
		echo "Starting Advanced Trivial FTP server FAILED!!!!"
		return 1
		
	fi
	
}

stop_atftpd_server() {
	
	if [[ -n "$ATFTPD_BIND_ADDRESSES_SC1" && -n "$ATFTPD_BIND_ADDRESSES_SC2" ]]; then
		THIS=$(cat /etc/cluster/nodes/this/id)
		if [ $THIS  == '1' ]; then
			ATFTPD_BIND_ADDRESSES=$ATFTPD_BIND_ADDRESSES_SC1
		else
			ATFTPD_BIND_ADDRESSES=$ATFTPD_BIND_ADDRESSES_SC2
		fi
		for IP in $ATFTPD_BIND_ADDRESSES; do
			echo "Stopping Advanced Trivial FTP server on $IP"
			apos_servicemgmt stop apg-atftpd\@$IP.service &>/dev/null 
		done
	else
		echo "Stopping Advanced Trivial FTP server FAILED!!!"
		return 1
		
	fi
}

status_atftpd_server() {
	
	if [[ -n "$ATFTPD_BIND_ADDRESSES_SC1" && -n "$ATFTPD_BIND_ADDRESSES_SC2" ]]; then
		THIS=$(cat /etc/cluster/nodes/this/id)
		if [ $THIS  == '1' ]; then
			ATFTPD_BIND_ADDRESSES=$ATFTPD_BIND_ADDRESSES_SC1
		else
			ATFTPD_BIND_ADDRESSES=$ATFTPD_BIND_ADDRESSES_SC2
		fi
		for IP in $ATFTPD_BIND_ADDRESSES; do
			echo "Checking for Advanced Trivial FTP server on $IP:"
			apos_servicemgmt status apg-atftpd\@$IP.service
		done
	else
		echo "WARNING: Checking for Wrong Advanced Trivial FTP server!!!"
		return 1
	fi
}


case $1 in
	start)
		
		# Start APG-ATFTP servers
		if ! start_atftpd_server; then
				exit 1
		fi
		;;
	stop)
		# Stop APG ATFTP server
		if ! stop_atftpd_server; then
			exit 1
		fi
		;;

	*)
		exit 1
esac
		
# End of file
