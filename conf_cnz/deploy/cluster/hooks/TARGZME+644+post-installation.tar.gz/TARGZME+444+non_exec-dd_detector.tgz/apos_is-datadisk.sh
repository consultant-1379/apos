#!/bin/bash
# -----------------------------------------------------------
#     Copyright (C) 2015 Ericsson AB. All rights reserved.
# -----------------------------------------------------------
# Name:
#       apos_is-datadisk.sh
#
# Description:
#   A script to find the data disk available in VM instance


# global variable-set
TRUE=$( true; echo $? )
FALSE=$( false; echo $? )

function is_system_disk(){
  local SD=''
  if [ -L /dev/disk_boot ]; then
    SD=$(basename $(/usr/bin/readlink /dev/disk_boot))
  else
    SD=$(basename $(/sbin/blkid -t LABEL=lde-boot | /usr/bin/awk -F: '{print $1}' | /usr/bin/sed -r 's@[0-9]*$@@g'))
  fi

  if [[ "$DISK" == "$SD" ]]; then
    return $TRUE
  else
    return $FALSE
  fi
}

function is_config_drive(){
  local LABEL_LIST=''
  for PART in /dev/$DISK*; do
    LABEL_LIST="$LABEL_LIST $(/sbin/blkid -s LABEL -p $PART -o value 2>/dev/null)"
  done
  for LABEL in $LABEL_LIST; do
    if [[ "$LABEL" == 'config-2' ]]; then
      return $TRUE
    fi
  done
  return $FALSE
}

# M A I N
if [ -z "$1" ]; then
  exit $FALSE
else
	DISK=$(/bin/echo ${1} | /usr/bin/sed -r 's@[0-9]*$@@g')
fi

if is_system_disk; then
  exit $FALSE
elif is_config_drive; then
  exit $FALSE
else
  exit $TRUE
fi
