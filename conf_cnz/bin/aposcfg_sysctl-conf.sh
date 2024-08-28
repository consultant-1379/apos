#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_sysctl-conf.sh
# Description:
#       A script to configure the /etc/sysctl.conf file.
# Note:
#	None.
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Mon Aug 28 2017 - Rajashekar Narla (xcsrajn)
#       Modified the size of ipsec connection routing table.
# - Thu Jul 05 2012 - Antonio Buonocunto (eanbuon)
#       Add reload of configuration.
# - Wed Feb 01 2012 - Paolo Palmieri (epaopal)
#	Configuration scripts rework.
# - Wed Oct 19 2011 - Paolo Palmieri (epaopal)
#	Added hardening options.
# - Mon Mar 14 2011 - Francesco Rainone (efrarai)
#	Added ipv4 configuration statements. Script name changed.
# - Wed Jan 26 2011 - Francesco Rainone (efrarai)
#	Massive rework.
# - Mon Dec 20 2010 - Madhu Aravabhumi
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
FILE="/etc/sysctl.conf"
KEYWORD=""
NEW_ROW=""

# Keyword 1 search and replace
KEYWORD="kernel.core_uses_pid"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then	
	NEW_ROW="kernel.core_uses_pid = 1"
	cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
	mv "$FILE.new" "$FILE"
else	
	NEW_ROW="\n\n# Controls whether core dumps will append the PID to the core filename.\n# Useful for debugging multi-threaded applications.\nkernel.core_uses_pid = 1"
	echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 2 search and replace
KEYWORD="kernel.core_pattern"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then	
	NEW_ROW="kernel.core_pattern = /var/log/core/core-%e-%p-%t"	
	cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
	mv "$FILE.new" "$FILE"
else	
	NEW_ROW="\n# Controls how and where to store the core dumps\nkernel.core_pattern = /var/log/core/core-%e-%p-%t"
	echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 3 search and replace
KEYWORD="net.ipv4.tcp_keepalive_intvl"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then	
	NEW_ROW="net.ipv4.tcp_keepalive_intvl = 3"	
	cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
	mv "$FILE.new" "$FILE"
else	
	NEW_ROW="\n# The interval between subsequential keepalive probes\nnet.ipv4.tcp_keepalive_intvl = 3"
	echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 4 search and replace
KEYWORD="net.ipv4.tcp_keepalive_probes"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then	
	NEW_ROW="net.ipv4.tcp_keepalive_probes = 3"	
	cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
	mv "$FILE.new" "$FILE"
else	
	NEW_ROW="\n# The number of unacknowledged probes to send before considering the connection dead\nnet.ipv4.tcp_keepalive_probes = 3"
	echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 5 search and replace
KEYWORD="net.ipv4.tcp_keepalive_time"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then	
	NEW_ROW="net.ipv4.tcp_keepalive_time = 3"	
	cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
	mv "$FILE.new" "$FILE"
else	
	NEW_ROW="\n# The interval between the last data packet sent and the first keepalive probe\nnet.ipv4.tcp_keepalive_time = 3"
	echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 6 search and replace
KEYWORD="net.ipv4.ip_local_port_range"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then	
	NEW_ROW="net.ipv4.ip_local_port_range = 54002 63000"	
	cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
	mv "$FILE.new" "$FILE"
else	
	NEW_ROW="\n# The range of the local available ports\nnet.ipv4.ip_local_port_range = 54002 63000"
	echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 7 search and replace for hardening
KEYWORD="net.ipv4.conf.all.forwarding"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then
        NEW_ROW="net.ipv4.conf.all.forwarding = 0"
        cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
        mv "$FILE.new" "$FILE"
else
        NEW_ROW="\n# To disable IP forwarding\nnet.ipv4.conf.all.forwarding = 0"
        echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 8 search and replace for hardening
KEYWORD="net.ipv4.icmp_echo_ignore_broadcasts"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then
        NEW_ROW="net.ipv4.icmp_echo_ignore_broadcasts = 1"
        cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
        mv "$FILE.new" "$FILE"
else
        NEW_ROW="\n# To prevent response to Broadcast Requests\nnet.ipv4.icmp_echo_ignore_broadcasts = 1"
        echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 9 search and replace for hardening
KEYWORD="net.ipv4.conf.all.accept_source_route"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then
        NEW_ROW="net.ipv4.conf.all.accept_source_route = 0"
        cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
        mv "$FILE.new" "$FILE"
else
        NEW_ROW="\n# To disable IP source routing\nnet.ipv4.conf.all.accept_source_route = 0"
        echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 10 search and replace for hardening
KEYWORD="net.ipv4.tcp_syncookies"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then
        NEW_ROW="net.ipv4.tcp_syncookies = 1"
        cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
        mv "$FILE.new" "$FILE"
else
        NEW_ROW="\n# To enable TCP SYN Cookie protection.\n# A SYN attack is a kind of Denial of Service attack\nnet.ipv4.tcp_syncookies = 1"
        echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 11 search and replace for hardening
KEYWORD="net.ipv4.conf.all.accept_redirects"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then
        NEW_ROW="net.ipv4.conf.all.accept_redirects = 0"
        cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
        mv "$FILE.new" "$FILE"
else
        NEW_ROW="\n# To disable ICMP redirect\nnet.ipv4.conf.all.accept_redirects = 0"
        echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 12 search and replace for hardening
KEYWORD="net.ipv4.conf.all.send_redirects"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then
        NEW_ROW="net.ipv4.conf.all.send_redirects = 0"
        cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
        mv "$FILE.new" "$FILE"
else
        NEW_ROW="\n# To disable ICMP redirect\nnet.ipv4.conf.all.send_redirects = 0"
        echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 13 search and replace for hardening
KEYWORD="net.ipv4.conf.all.rp_filter"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then
        NEW_ROW="net.ipv4.conf.all.rp_filter = 1"
        cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
        mv "$FILE.new" "$FILE"
else
        NEW_ROW="\n# To enable IP spoofing protection\nnet.ipv4.conf.all.rp_filter = 1"
        echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 14 search and replace for hardening
KEYWORD="net.ipv4.tcp_timestamps"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then
        NEW_ROW="net.ipv4.tcp_timestamps = 0"
        cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
        mv "$FILE.new" "$FILE"
else
        NEW_ROW="\n# To disable TCP timestamp support\nnet.ipv4.tcp_timestamps = 0"
        echo -e "$NEW_ROW" >> $FILE
fi

# Keyword 15 search and replace for ipsec 
KEYWORD="net.ipv4.xfrm4_gc_thresh"
if [ "`cat $FILE | grep \"$KEYWORD\"`" ]; then
  NEW_ROW="net.ipv4.xfrm4_gc_thresh = 32768"
  cat "$FILE" | sed "s@^$KEYWORD.*@$NEW_ROW@g" > "$FILE.new"
  mv "$FILE.new" "$FILE"
else
  NEW_ROW="\n# To increase size of ipsec connection routing table\nnet.ipv4.xfrm4_gc_thresh =32768 "
  echo -e "$NEW_ROW" >> $FILE
fi


#Reload configuration of sysctl
/sbin/sysctl -p &> /dev/null
if [ $? -ne 0  ]; then
  apos_abort "Failure while reloading configuration of sysctl!"
fi

apos_outro $0
exit $TRUE

# End of file
