#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_password_hardenrules.sh
# Description:
#       A script to handle the hardening of PAM password rules.
# Note:
#       None.
##
# Usage:
#       apos_password_hardenrules <-e/-d>
#
#       <-e option enables the password hardening rules 
#       <-d option disables the password hardening rules
##
# Output:
#       None.
##
# Changelog:
# - Thr Jul 21 2021 - Sowjanya Medak (xsowmed)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
CFG_PATH="/opt/ap/apos/conf"
PAM_FILENAME="/etc/pam.d/acs-apg-password-local"
SED_COMMAND="/usr/bin/sed"

function slog() {
   /bin/logger -t apos_password_hardenrules "$@"
}

function getPasswordStatus(){
   grep -q "lde_pam_pwquality.so" $PAM_FILENAME
   if [ $? -ne 0 ] ; then
      return 1 # disabled
   else
      return 0 # enabled
   fi
}

function disablePasswordRules(){
   slog "entered disablePasswordRule"
   getPasswordStatus
   status=$?
   if [ $status -eq 0 ] ; then
      # disabling the password rules for tsuser and tsadmin by replacing lde_pam_pwquality.so with pam_cracklib.so
      $SED_COMMAND -i 's/lde_pam_pwquality.so usersubstr=4 enforce_for_root/pam_cracklib.so/g' $PAM_FILENAME
      if [ $? -ne 0 ] ; then
         slog "sed command to disable new rules for tsuser and tsadmin in PAM configuration file failed"
      fi
   else
      slog "Password rules are already disabled"
   fi

}

function enablePasswordRules() {
   slog "entered enablePasswordRule"
   getPasswordStatus
   status=$?
   if [ $status -ne 0 ] ; then
      # enabling the password rules for tsuser by replacing pam_cracklib.so with lde_pam_pwquality.so
      $SED_COMMAND -i '/reject_username/s/pam_cracklib.so/lde_pam_pwquality.so usersubstr=4 enforce_for_root/' $PAM_FILENAME
      if [ $? -ne 0 ] ; then
         echo "sed command to replace pam_cracklib.so with lde_pam_pwquality.so for tsuser in PAM configuration file failed"
      fi
      # enabling the password rules for tsadmin by replacing pam_cracklib.so with lde_pam_pwquality.so
      /usr/bin/sed -i '/success=3/{n;s/pam_cracklib.so/lde_pam_pwquality.so usersubstr=4 enforce_for_root/;}' $PAM_FILENAME
      if [ $? -ne 0 ] ; then
         echo "sed command to replace pam_cracklib.so with lde_pam_pwquality.so for tsadmin in PAM configuration file failed"
      fi
   else
      echo "Password rules are already enabled"
   fi
}

function parse_args() {
   if [[ $# != 1 ]] ; then
      slog "Incorrect usage" 
   fi
   case "$1" in
      -e)
         slog "INFO: password enabled Invoked"
         enablePasswordRules
       ;;
       -d)
         slog "INFO: password disabled Invoked"
         disablePasswordRules
        ;;
        *)
          slog "INFO: Incorrect usage" 
        ;;
   esac
}

# main function

parse_args "$@"


