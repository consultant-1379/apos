#!/bin/bash  
#Changelog:
# # - Fri Aug 06 2021 - Paolo Palmieri (epaopal) 
#       Changes for RSYSLOG Adoption feature
# # - Wed Mar 04 2020 - Bipin Polabathina (XBIPPOL)
#       LDAP IPv6 adaptations for vAPG
#
# # - Fri Sept 02 2015 - Antonio Buonocunto  (EANBUON)
#       LDAP Local Authentication PH0 adaptation
#       First version.
##
# print usage of the command

. ${AP_HOME:-/opt/ap}/apos/conf/apos_common.sh

function usage() {
  echo "Incorrect usage"
  echo -e "Usage: ldapdef ldap_ip ldap_common_name [ldapfallback_ip ldapfallback_common_name]\n"
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
    echo -e "Common name not valid\n"
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
ip_addr_ldap=$1
ip_hostname_ldap=$2

valid_ip $ip_addr_ldap
valid_name $ip_hostname_ldap
	
if [ $num_arg == 4 ]; then
   	ip_addr_ldapfallback=$3
   	ip_hostname_ldapfallback=$4
	valid_ip $ip_addr_ldapfallback
	valid_name $ip_hostname_ldapfallback	
fi
pushd /opt/ap/apos/bin/clusterconf/ &>/dev/null

#Delete all existing host rules
NUM_HOSTS_ROW="$(./clusterconf host -D | grep " all " | wc -l)"
if [ $NUM_HOSTS_ROW -gt 0 ]; then
  for ((i=0;i<$NUM_HOSTS_ROW;i++)); do
    # to retrieve latest snapshot from cluster configuration file
    HOSTS_ROWS="$(./clusterconf host -D | grep " all ")"
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

# Add LDAP ip server entry
./clusterconf host --add all $ip_addr_ldap $ip_hostname_ldap &>/dev/null
if [ $? -ne 0 ];then
  echo -e "Error when executing (general fault)\n"
  exit 1
fi
if [ $num_arg == 4 ]; then
  # Add Fallback LDAP ip server entry
  ./clusterconf host --add all $ip_addr_ldapfallback $ip_hostname_ldapfallback &>/dev/null	
  if [ $? -ne 0 ]; then
    echo -e "Error when executing (general fault)\n"
    exit 4
  fi 
fi
popd &>/dev/null

exit 0
