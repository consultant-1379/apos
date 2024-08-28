#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos-system-conf.sh
# Description:
#       A script to configure system parameters during first deployment 
#       only in case of vAPG
# Note:
#       The present script is executed during the start/stop phase of the
#       apos-system-config.service
##
# Usage:
#       apos-system-conf.sh [early|late]
##
# Output:
#       None.
##
# Changelog:
# - Fri Dec 16 2016 - Francesco Rainone (EFRARAI)
#   Script restructured to comply with the new early/late stage division.
# - Mon Dec 12 2016 - Francesco Rainone (EFRARAI)
#   Escalating failures to the invoking unit file and echoing messages on stderr
#   to overcome the fact that syslog is not available when this script is
#   executed.
# - Fri Mar 25 2016 - PratapReddy Uppada (xpraupp)
#   First Version
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

is_boot_mounted() {
  /usr/bin/mountpoint --quiet /boot/
  local return_code=$?
  if [ $return_code -ne $TRUE ]; then
    echo "/boot not mounted --apos blk"
  fi
  return $return_code
}

function mount_boot() {
  if /usr/bin/mount --label 'lde-boot' /boot; then
    echo "/boot correctly mounted --apos blk"
  else
    echo "ABORT: failure while mounting /boot --apos blk" >&2
    exit $FALSE
  fi
}

function umount_boot() {
  if /usr/bin/umount /boot; then
    echo "/boot correctly unmounted --apos blk"
  else
    echo "ABORT: failure while unmounting /boot --apos blk" >&2
  fi
}

#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|
#

# if /boot is not mounted, let's mount it (later we will unmount it).
# This is for the "early" case, that usually gets executed when /boot is not
# mounted.
was_boot_mounted=$TRUE
if ! is_boot_mounted; then
  was_boot_mounted=$FALSE
  mount_boot
fi

HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)

stage=$1
if [[ ! "$stage" =~ ^(early)|(late)$ ]]; then
  echo "ABORT: unsupported value: $stage" >&2
  exit $FALSE
fi
if [[ "$HW_TYPE" == 'VM' ]]; then
  if is_system_configuration_allowed; then
    echo "applying APG initial configuration --apos blk"
    if [ ! -x /opt/ap/apos/conf/apos_system_conf.sh ]; then
      echo "ABORT: apos_system_conf.sh not found or not executable --apos blk" >&2
      exit $FALSE
    fi
    /opt/ap/apos/conf/apos_system_conf.sh $stage
    return_code=$?
    if [ $return_code -ne $TRUE ] ; then
      echo "ABORT: failure while applying APG initial configuration --apos blk(return code: $return_code)" >&2
      exit $return_code
    fi
  fi
fi


# if /boot was not mounted when the present script started, let's unmount it.
if [ $was_boot_mounted -eq $FALSE ]; then
  umount_boot
fi

echo "APG initial configuration successfully completed --apos blk"
exit $TRUE
