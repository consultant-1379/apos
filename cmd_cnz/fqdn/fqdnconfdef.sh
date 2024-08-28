#!/bin/bash
# ------------------------------------------------------------------------------
# Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------------
##
# Name:
#      fqdnconfdef.sh
# Description:
#       A command to map an IP address with a Fully Qualified Domain Name (FQDN)
#       in /cluster/etc/cluster.conf (and in /etc/hosts, done by LDEwS).
# Note:
#       None.
##
# Usage:
#       .
##
# Output:
#       Cluster configuration for System Controllers is updated.
##
# Changelog:
# - 01/08/21 - Paolo Palmieri (epaopal)
#       First version.
##

. ${AP_HOME:-/opt/ap}/apos/conf/apos_common.sh

function usage() {
  echo "Incorrect usage"
  echo -e "Usage: fqdndef host1_ip host1_fqdn [host2_ip host2_fqdn]\n"
}


function valid_ip()
{
  local ip=$1
  local stat=$FALSE

  if [ `echo $ip | grep "^-"` ]; then
   usage
   exit 4
  fi

  if echo "$ip" | grep -E '[0-9a-f]+:+' >/dev/null; then
     if is_vAPG; then
        isValidIPv6 $ip && stat=$TRUE
     fi
  else
     isValidIPv4 $ip && stat=$TRUE
  fi

  if [ $stat -eq $FALSE ]; then
    echo -e "IP address not valid\n"
    exit 3
  fi
}


function valid_name()
{
  local name=$1
  local stat=1
  if [ `echo $name | grep "^-"` ]; then
    usage
    exit 5
  fi
  if [[ $name =~ ^[0-9|a-z|A-Z]{1}[0-9|a-z|A-Z\\-]{0,31}\.{0,1}([0-9|a-z|A-Z\\-]{1,31}\.{0,1}){1,}[0-9|a-z|A-Z]{1}$ ]]; then
    OIFS=$IFS
    IFS='.'
    name=($name)
    IFS=$OIFS
    stat=$?
  fi
  if [ $stat == 1 ]; then
    echo -e "Fully qualified domain name not valid\n"
    exit 3
  fi
}

# MAIN

num_arg=$#
# check command line arguments
if [ $num_arg != 2 -a $num_arg != 4 ]; then
   #echo
   usage
   exit 2
fi
host1_ip=$1
host1_fqdn=$2

valid_ip $host1_ip
valid_name $host1_fqdn

if [ $num_arg == 4 ]; then
        host2_ip=$3
        host2_fqdn=$4
        valid_ip $host2_ip
        valid_name $host2_fqdn
fi


pushd /opt/ap/apos/bin/clusterconf/ &>/dev/null

#Delete all existing host rules
NUM_HOSTS_ROW="$(./clusterconf host -D | grep " control " | wc -l)"
if [ $NUM_HOSTS_ROW -gt 0 ]; then
  for ((i=0;i<$NUM_HOSTS_ROW;i++)); do
    # to retrieve latest snapshot from cluster configuration file
    HOSTS_ROWS="$(./clusterconf host -D | grep " control ")"
    # to retrieve the index in the row at "i" position
    idx=$(echo "$HOSTS_ROWS" | awk 'NR == 1' | awk -F ' ' '{print $1}')
    # to delete the row accordingly
    ./clusterconf host -d $idx &>/dev/null
    if [ $? -ne 0 ];then
      echo -e "Error when executing (general fault)\n"
          exit 1
    fi
  done
fi

#Add host entry in cluster.conf file
./clusterconf host --add control $host1_ip $host1_fqdn &>/dev/null
if [ $? -ne 0 ];then
  echo -e "Error when executing (general fault)\n"
  exit 1
fi

if [ $num_arg == 4 ]; then
  # Add regular ip server entry
  ./clusterconf host --add control $host2_ip $host2_fqdn &>/dev/null  
  if [ $? -ne 0 ]; then
    echo -e "Error when executing (general fault)\n"
    exit 4
  fi
fi

popd &>/dev/null

exit 0
