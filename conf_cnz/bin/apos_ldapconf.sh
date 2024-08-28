#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_ldapconf.sh
# Description:
#       A script to set initial values for ldap configuration.
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
# - Thu Oct 12 2020 - Yeswanth Vankayala (xyesvan)
#       SEC 2.16 PRA NBC Impacts removed administrativeState setting
#       to unlock
# - Wed Feb 1 2017 - Praveen Rathod(xprarat)
#       SEC2.1 PRA impacts, removed useTls and filterType 
#       attributes setting
# - Fri Sept 02 2015 - Anna Maria Santonicola  (teisaam)
#       LDAP Local Autentichation PH0 adaptation
# - Fri May 07 2015 - Antonio Buonocunto (eanbuon)
#       IMM based configuration ofr serverPort and tlsMode
# - Fri Jun 06 2014 - Antonio Buonocunto (eanbuon)
#       Adaptation to COM 4.0
# - Fri Mar 14 2014 - Antonio Buonocunto (eanbuon)
#	Added ap2_oam handling.
# - Fri Jan 07 2013 - Francesco Rainone (efrarai)
#	ldapAuthenticationMethodId is now UNLOCKED out-of-the-box during maiden.
# - Wed Nov 14 2012 - Antonio Buonocunto (eanbuon)
#	Move out group handling in aposcfg_group.sh.
# - Mon Nov 06 2012 - Salvatore Delle Donne (teisdel)
#       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

function ldap_attr_set () {
	# the following attributes in Ldap model can be set with a default value
	# profileFilter=ERICSSON_FILTER (1)
	# localAUthorization,administrativeState=UNLOCKED

	##
  # WORKAROUND: BEGIN
  # DESCRIPTION: Please uncomment the following lines once SEC delivers the final solution to fix this in SEC model file.
  if kill_after_try 3 3 4 immcfg -a useTls=0 ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
    apos_log "useTls set to False"
  else
    apos_abort 1 "Failed to set useTls to False"
  fi
	# WORKAROUND: END
  ##

	if kill_after_try 3 3 4 immcfg -a profileFilter=1 ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
		apos_log "profileFilter set to ERICSSON_FILTER"
	else
    apos_abort 1  "Failed to set profileFilter to ERICSSON_FILTER"
	fi

	# unlock TBAC
	if kill_after_try 3 3 4 immcfg -a targetBasedAccessControl=1 ericssonFilterId=1,ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
		apos_log "targetBasedAccessControl UNLOCKED"
	else
    apos_abort 1  "Failed to UNLOCK targetBasedAccessControl"
 	fi

  # configure Server Port to 636
  if kill_after_try 3 3 4 immcfg -a serverPort=636 ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
    apos_log "Ldap server port set to 636"
  else
    apos_abort 1  "Failed to configure LDAP server port"
  fi

  # configure tlsMode to LDAPS( 1 )
  if kill_after_try 3 3 4 immcfg -a tlsMode=1 ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
    apos_log "Ldap tls mode set to LDAPS"
  else
    apos_abort 1  "Failed to configure LDAP tls mode"
  fi
}

function ldap_attr_set_no_oam () {
	# the following attributes in Ldap model can be set with a default value in case of NO option for ap2_oam:
	# profileFilter=ERICSSON_FILTER (2)
	# localAUthorization,administrativeState=UNLOCKED
	# ldapAuthenticationMethodId=1,administratimeState=UNLOCKED
	# ericssonFilterId=1,targetBasedAccessControl=UNLOCKED
	
	local primary_sc_a_AP1=""
	local primary_sc_b_AP1=""

	primary_sc_a_AP1="192.168.169.33"
	primary_sc_b_AP1="192.168.170.33"

	##
  # WORKAROUND: BEGIN
  # DESCRIPTION: Please uncomment the following lines once SEC delivers the final solution to fix this in SEC model file.
  if kill_after_try 3 3 4 immcfg -a useTls=0 ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
    apos_log "useTls set to False"
  else
    apos_abort 1 "Failed to set useTls to False"
  fi
	# WORKAROUND: END
  ##

  # configure profileFilter
  if kill_after_try 3 3 4 immcfg -a profileFilter=1 ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
    apos_log "profileFilter set to ERICSSON_FILTER"
  else
    apos_abort 1  "Failed to set profileFilter to ERICSSON_FILTER"
  fi

	# configure ldapIpAddress
	if kill_after_try 3 3 4 immcfg -a ldapIpAddress=$primary_sc_a_AP1 ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
		apos_log "ldapIpAddress set to $primary_sc_a_AP1"
	else
    		apos_abort 1  "Failed to set ldapIpAddress to $primary_sc_a_AP1"
	fi

	# configure fallbackLdapIpAddress
	if kill_after_try 3 3 4 immcfg -a fallbackLdapIpAddress=$primary_sc_b_AP1 ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
		apos_log "ldapIpAddress set to $primary_sc_b_AP1"
	else
    		apos_abort 1  "Failed to set ldapIpAddress to $primary_sc_b_AP1"
	fi
	
	# unlock TBAC
	if kill_after_try 3 3 4 immcfg -a targetBasedAccessControl=1 ericssonFilterId=1,ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
		apos_log "targetBasedAccessControl UNLOCKED"
	else
    		apos_abort 1  "Failed to UNLOCK targetBasedAccessControl"
 	fi
	
  # configure Server Port to 389
  if kill_after_try 3 3 4 immcfg -a serverPort=389 ldapId=1,SecLdapAuthenticationldapAuthenticationMethodId=1; then
    apos_log "Ldap server port set to 389"
  else
    apos_abort 1  "Failed to configure LDAP server port"
  fi

}

# Main

# get the ap type : AP1 or AP2
AP_TYPE=$(apos_get_ap_type)

# Initial ldap attribute settings
if [ "$AP_TYPE" = "AP2" ]; then
  # get the ap2 oam:  YES | NO
  AP2_OAM=$(apos_get_ap2_oam)
  if [ "$AP2_OAM" = "YES" ]; then
    #AP2 case with YES ap2_oam
    ldap_attr_set
  elif [ "$AP2_OAM" = "NO" ]; then
    #AP2 case with NO ap2_oam
    ldap_attr_set_no_oam
  else
    #AP2 case with a not valid value for ap2_oam
    apos_log "WARNING: Value $AP2_OAM of ap2_oam not valid. Use default value: YES"
    ldap_attr_set
  fi
else
  #AP1 case
  ldap_attr_set
fi

apos_outro $0
exit $TRUE

# End of file
