#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2022 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_conf.sh
# Description:
#       A script to call in the right order all the APOS configuration scripts.
# Note:
#	The present script is executed during the %post phase of the OSCONFBIN
#	rpm activation.
##
# Usage:
#	None.
##
# Output:
#       None.
##
# Changelog:
# - Tue May 02 2023 - Pravalika P (zprapxx)
#   Disabling unused filesystem as part of CISCAT Improvements 
# - Mon Oct 03 2022 - Naveen Kumar G (zgxxnav)
# - Wed Aug 03 2022 - Amrutha Padi (zpdxmrt)
#   Fix for TR HZ59046
# - Mon Jun 06 2022 - P S SOUMYA (zpsxsou)
#        Fix for mml stream
# - Tue Apr 12 2022 - P S SOUMYA (zpsxsou)
#        Fix for TR HZ75192
# - Mon Apr 11 2022 - Anjali M(xanjali)
#        Modified apos_rp-hosts-config file trigger
# - Thu Mar 03 2022 - Rajeshwari Padavala (xcsrpad)
#       changes for vBSC: Chrony support
# - Wed Sep 29 2021 - Swapnika Baradi (xswapba)
#       Fix for SSU WA
# - Thu Sep 02 2021 - Swapnika Baradi (xswapba)
#       Fix for TR HZ28738
# - Mon Aug 02 2021 - Anjali M(xanjali
#       Changes for vBSC: RP-VM Handling
# - Fri Jun 18 2021 - Dharma Theja (xdhatej)
#	Fix for TR HZ10718
# - Fri Jan 08 2021 - Swapnika Baradi (xswapba)
#       Fix for TR HY77682
# - Thu Dec 12 2020 - Yeswanth Vankayala (xyesvan)
#       Removed function align_sshd_algorithms as we are taking 
#       default value of ciphers provided by SEC
# - Tue Dec 1 2020 - Swapnika Baradi (xswapba)
#       Fix for TR HY37046
# - Mon Nov 16 2020 -Sowjanya Medak(xsowmed)
#	Work around removal for HY57569
# - Mon Oct 26 2020 -Sowjanya GVL(xsowgvl)
#       changes done to align to audit rules NBC of SLES12 SP5
# - Fri Aug 14 2020 -Sindhuja Palla(xsinpal)/Paolo Palmieri(epaopal)
#       Fix for TR HY55333
# - Wed Aug 05 2020 - Poorna Chandra Gorle (zgorpoo)
#       Fix for TR HY54767
# - Thu Aug 13 2020 - Roshini Chilukoti (ZCHIROS)
#	Fix for TR HY40656 & HY44809
# - Fri Apr 17 2020 - Swapnika Baradi(Xxswapba)
#       Fix for TR HY35412
# - Tue Nov 05 2019 - Pravalika P(zprapxx)/Paolo Palmieri(epaopal)
#       Added function to align the SEC SSH MO with 
#       Ssh server configuration properties in APG
# - Mon Nov 11 2019 - Swapnika Baradi(xswapba)
#	Fix for TR HX28643
# - Wed May 08 2019 - Pratap Reddy Uppada(xpraupp)
#       Added function to disable the postfix service
# - Wed Mar 20 2019 - Neelam Kumar(xneelku)
# 	Removed Workaround included for HW49279
# - Thu Jan 3 2019 - Nazeema Begum (xnazbeg)
#	Included apos_cba_workarounds.sh
#	Journald memory fix has been extended for GEP2 as well
#       Removed the WA of masking systemd-journald-audit.socket
# - Mon Dec 03 2018 - Pratap Reddy Uppada(xpraupp)
# 	Workaround included for journald memory fix       
# - Tue Sep 18 2018 - Suman Kumar Sahu (zsahsum)
#	Invoking function update_pso_params for Virtual environment.
# - Fri Jul 06 2018 - Pratap Reddy Uppada (xpraupp)
#       Removed apg_gid-checker service related impacts 
#       as LDE 4.5 provided fix for GID missing issue
# - Tue May 22 2018 - Crescenzo Malvone (ecremal)
#       Included apg_gid-checker service
# - Fri Jul 21 2017 - Pratap Reddy Uppada (xpraupp)
#       SEC ldap case insensitivity handling: 
#       Included apos_sec-ldapconf.sh script
# - Wed Mar 08 2017 - Baratam Swetha (xswebar)
#   Added deploy of atftp files on AP2 
# - Tue Aug 8 2017 - Yeswanth Vankayala (xyesvan)
#       TR fix for HV97093
# - Mon Feb 13 2017 - Avinash Gundlapally (xavigun)
#	Added impacts for ssh subsystem in APG
# - Mon Jan 23 2017 - Franco D'Ambrosio (efradam)
#       Added the invocation of apos_guest.sh script
# - Fri Dec 16 2016 - Francesco Rainone (EFRARAI)
#       added creation of .node_id file under /boot
# - Tue Nov 22 2016 - Pratap Reddy Uppada(xpraupp)
#       added deployment of dhcpd.conf.local_vm file 
# - Thu May 05 2016 - Alessio Cascone (ealocae)
#       Added creation of the restore flag.
# - Fri Apr 15 2016 - Antonio Buonocunto (eanbuon)
#       Handling of smartd service.
# - Tue Mar 29 2016 - PratapReddy Uppada (xpraupp)
#       USA impacts for rsyslog.service
# - Fri Mar 04 2016 - Antonio Buonocunto (eanbuon)
#       New script aposcfg_appendgroup.sh for SUGAR.
# - Tue Feb 02 2015 - Pratap Reddy Uppada (xpraupp)
#   updated to deploy system configuration in case of vAPG
# - Thu Jan 26 2016 - Antonio Buonocunto (eanbuon)
#       Bug fix
# - Mon Jan 25 2016 - Franco D'Ambrosio (efradam)
#       Modified rsyslogd reload call
# - Sat Jan 23 2016 - Antonio Buonocunto (eanbuon)
#       Bug fix
# - Thu Jan 21 2016 - Franco D'Ambrosio (efradam)
#       Modified the list of files to deploy for the introduction of systemd
#       Modified services management for the introduction of systemd
# - Mon Jan 18 2016 - Fabio Ronca (efabron)
#       Removed invocation of aposcfg_inittab.sh script
#       Added Disabling of CTRL+ALT+CANC for SLES12 
# - Sat Jan 16 2016 - Fabio Ronca (efabron)
#       updated with GRUB2 impact for SLES12 introduction
# - Thu Dec 10 2015 - Pratap Reddy Uppada (xpraupp)
#       Updated with parmtool to fetch parameters
#- Mon Nov 16 2015 - PratapReddy Uppada(XPRAUPP)
#	TR fix: HU34736
# - Thu Sep 08 2015 - Antonio Buonocunto (eanbuon)
#       vsftpd improvement.
# - THU AUG 06 2015 - Dharma Teja (xdhatej)
#       Added deploy of apos_ftp-config file	
# - Mon 11 MAY 2015 - Sindhuja Palla (XSINPAL)
#	Added new script to set vlan QoS settings like PCP/DSCP setting
# - Wed Mar 04 2015 - Furquan Ullah (xfurull)
#       Added deploy of apos_sshd-config file
# - Thu May 20 2014 - Antonio Nicoletti (eantnic)
#       Added deploy of openldap file on AP1
# - Thu Mar 13 2014 - Antonio Buonocunto (eanbuon)
#       Added handling of ap2_oam option
# - Thu Feb 25 2014 - Antonio Buonocunto (eanbuon)
#       Move apos_comconf.sh from apos_conf.sh to apos_finalize.sh
# - Wed Jan 22 2014 - Malangsha Sahik (xmalsha)
#	Added support for 10G introduction
# - Mon Dec 30 2013 - Fabrizio Paglia (xfabpag)
#   	Added patch to remove notice message at racoon startup
# - Fri Oct 18 2013 - Fabio Ronca (efabron)
#   	Removed LDE patch for udev rules on GEP5
#	Removed Bonding mode setting
# - Tue Sep 10 2013 - Fabio Ronca (efabron)
#   	Modified to apply LDE patch for udev rules on GEP5
# - Tue Jul 16 2013 - Pratap Reddy (xpraupp)
#   	Modified to support both MD and DRBD
# - Mon Mar 25 2013 - ealfatt,edaebao
#	internal_root folder creation as workaround for APOS reduced.
# - Fri Nov 23 2012 - Paolo Palmieri (epaopal)
#	Overall adaptation to use the exclusive lock feature when destination is a file under /cluster.
# - Tue Nov 13 2012 - Francesco Rainone (efrarai)
#	Added the invocation of aposcfg_common-session.sh, apos_rootlock.sh and
#	apos_comconf.sh
# - Fri Nov 09 2012 - Paolo Palmieri (epaopal)
#	Adding the ossrc-eam terminal type like the vt100 one.
# - Thu Nov 08 2012 - Paolo Palmieri (epaopal)
#	Introduction of iptables configuration.
# - Wed Oct 17 2012 - Francesco Rainone (efrarai)
#	Forcing invocation of aposcfg_group.sh and aposcfg_motd.sh on node 1
#	only.
# - Tue Oct 09 2012 - Antonio Buonocunto (eanbuon)
#       Move Sec Configuration in apos_finalize.
# - Tue Oct 02 2012 - Paolo Palmieri (epaopal)
#	Introduced hooks for DR.
# - Fri Sep 06 2012 - Francesco Rainone (efrarai)
#	syncd service stop/start to fix an issue while updating /etc/sudoers.
# - Tue Aug 21 2012 - Francesco Rainone (efrarai)
#	Removed the workaround for usr/sbin/lde-ip.
# - Tue Jul 17 2012 - Francesco Rainone (efrarai) & Antonio Buonocunto (eanbuon)
#	Moving libcli_extension_subshell.cfg and libcom_cli_agent.cfg from here
#	to apos_finalize.sh.
# - Fri Jun 29 2012 - Francesco Rainone (efrarai) & Antonio Buonocunto (eanbuon)
#	Fix.
# - Thu Jun 14 2012 - Fabio Ronca (efabron)
#	APOS R1A16 updates: update the deploy list with the new name for dhcpd
#	network start/stop configuration file
# - Thu Jun 14 2012 - Antonio Buonocunto (eanbuon)
#	APOS R1A16 updates: add /usr/sbin/lde-ip in deploy list.
# - Tue May 8 2012 - Fabio Ronca (efabron)
#	APOS R1A15 release: add Node hardening scripts
# - Thu Apr 19 2012 - Alfonso Attanasio (ealfatt)
#	APOS R1A14 updates: removal of restart of auditd.
# - Mon Apr 02 2012 - Paolo Palmieri (epaopal)
#	APOS R1A14 updates: removal of apos_models_conf.sh execution.
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	APOS R1A14 updates: configuration scripts rework.
# - Fri Dec 12 2011 - Francesco Rainone (efrarai)
#	APOS R1A13 updates
# - Wed Nov 16 2011 - Francesco Rainone (efrarai)
#	APOS R1A12 updates
# - Wed Nov 02 2011 - Paolo Palmieri (epaopal)
#	APOS R1A11 updates
# - Thu Sep 08 2011 - Paolo Palmieri (epaopal)
#	APOS R1A09 updates
# - Fri May 27 2011 - Paolo Palmieri (epaopal)
#	Rework for LOTC 4.0!
# - Thu Feb 17 2011 - Paolo Palmieri (epaopal)
#	Some improvement
# - Tue Dec 21 2010 - Francesco Rainone (efrarai)
#	Massive rework.
# - ??? ??? ?? 2010 - Madhu Aravabhumi
#	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

# Common variables
CFG_PATH="/opt/ap/apos/conf"

TMP_FILE='/tmp/tlsdTraceFile.log'
SUDOERS_FILE="/etc/sudoers"
LDE_SUDO_FILE="/etc/sudoers.d/lde-sudo-config"
HW_TYPE=$(/opt/ap/apos/conf/apos_hwtype.sh)
[ -z "$HW_TYPE" ] && apos_abort 1 'HW_TYPE not found'
DD_REPLICATION_TYPE=$(get_storage_type)
AP_TYPE=$(apos_get_ap_type)
SHELF_ARCH=$(get_shelf_architecture)
CACHE_DURATION=$(apos_get_cached_creds_duration)
SSSD_LDAP_CACHE_FILE_PATH="$(apos_create_brf_folder clear)/cache_ldap"
SYSLOG_PATH=$(</etc/syslog-logstream.d)
function isAP2(){
  [ "$AP_TYPE" == "$AP2" ] && return $TRUE
  return $FALSE
}

function isMD(){
  [ "$DD_REPLICATION_TYPE" == "MD" ] && return $TRUE
  return $FALSE
}

#function isBSP to fetch Node Architecture
function isBSP(){
  [ "$SHELF_ARCH" == "DMX" ] && return $TRUE
  return $FALSE
}

function isvAPG(){
  [[ "$SHELF_ARCH" == "VIRTUALIZED" && "$HW_TYPE" == "VM" ]] && return $TRUE
  return $FALSE
}

#function isSMX to fetch Node Architecture
function isSMX(){
  [ "$SHELF_ARCH" == "SMX" ] && return $TRUE
  return $FALSE
}

function is10G(){
  local NETWORK_BW=''
  NETWORK_BW=$( $CMD_PARMTOOL get --item-list drbd_network_capacity 2>/dev/null | \
  awk -F'=' '{print $2}')
  [ -z "$NETWORK_BW" ] && NETWORK_BW='1G'

  [ "$NETWORK_BW" == '10G' ] && return $TRUE
  return $FALSE
}

# The function stores node_id (as retrieved at rpm installation time) in
# /boot/.node_id. This is to ease some virtualization use-cases like, for
# example, dynamic MAC address handling.
function store_node_id(){
  local source_file=/etc/cluster/nodes/this/id
  local destination_file=/boot/.node_id
  local id=''
  if [ ! -r $source_file ]; then
    apos_abort "file $source_file not found or not readable"
  else
    id=$(<$source_file)
    if [[ ! "$id" =~ ^[0-9]+$ ]]; then
      apos_abort "non-valid node it retrieved: \"$id\""
    fi
  fi
  echo "$id" > $destination_file || apos_abort "failure while populating $destination_file"
}

# APG doesn't provide mailing service, So  postfix server running on APG 
# is meaning less.Hence postfix server is completely disabled.
function disable_postfix_service() {
  local postfix_service_file='/usr/lib/systemd/system/postfix.service'
  if [ -f ${postfix_service_file} ]; then
    if apos_servicemgmt is_running postfix.service &>/dev/null; then
      apos_log 'Stopping the postfix service... '
      apos_servicemgmt stop postfix.service &>/dev/null || apos_abort 'failure while stopping postfix service'
      apos_log 'Done'
    else
      apos_log 'postfix service is already stopped'
    fi
    # Disable the postfix service from run levels
    apos_log 'Disabling postfix service... '
    if [ -x /sbin/chkconfig ]; then
      /sbin/chkconfig postfix off &>/dev/null || apos_abort 'failure while disbaling the postfix service'
    else
      apos_servicemgmt disable postfix.service &>/dev/null || apos_abort 'failure while disabling postfix service'
    fi
    apos_log 'Done'
  else
    apos_log 'postfix service file not found in systemd. Skipping disabling of postfix service'
  fi
}

function setWatchdogInterval(){
	SOURCEFILE="/storage/system/config/apos/lde-watchdogd-config"
        if [ -f $SOURCEFILE ];then
         interval_value=$(awk -F "=" '{print $2}' $SOURCEFILE )
         rCode=$?
         if [ $rCode -ne 0 ]; then
                $ECHO "Error when executing (General Fault)"
                apos_abort  $exit_gen "Error while setting the interval. Exiting..."
         fi
	
	 if [ -z "$interval_value" ]; then
	         $ECHO "Interval Value Cannot be Empty."
                apos_abort  $exit_gen "Error while setting the interval. Exiting..."
         fi

         cmd=$(echo "sed -i '0,/WATCHDOG_DAEMON_OPTIONS=.*/s//WATCHDOG_DAEMON_OPTIONS=\"\$WATCHDOG_DAEMON_OPTIONS -i $interval_value\"/' /usr/lib/lde/inithooks/lde-watchdogd")
        eval "$cmd"
        rCode=$?
        if [ $rCode -ne 0 ]; then
                $ECHO "Error when executing (General Fault)"
                apos_abort  $exit_gen "Error while setting the interval. Exiting..."
        fi

         apos_servicemgmt restart lde-watchdogd.service &>/dev/null || apos_abort 'failure while stopping watchdog service'
         apos_log 'Done'
        fi
}


if [ -d $CFG_PATH ]; then
  pushd $CFG_PATH &> /dev/null
  
  # Store installation-time node_id under /boot/.node_id for easing some
  # virtualization use-cases.
  store_node_id
  
  # Support for the ossrc-eam terminal (vt100-like)
  pushd /usr/share/terminfo/o &> /dev/null
  ln -f -s ../v/vt100 ossrc-eam || apos_abort 1 'creation of ossrc-eam terminal failed'
  popd &> /dev/null

  # Disabling Ctrl+Alt+Del
  pushd /usr/lib/systemd/system &> /dev/null
  ln -f -s /dev/null ctrl-alt-del.target || apos_abort 1 'disabling of Ctrl+Alt+Del failed'
  popd &> /dev/null

  # iptables configuration
  #[ $HN_THIS = $HN_FIRST ] && apos_check_and_call $CFG_PATH apos_iptables.sh
  apos_log 'calling apos_iptables.sh'
  apos_check_and_exlocall $CFG_PATH apos_iptables.sh
  
  # /etc/bash.bashrc.local file set up - bash prompt configuration
  apos_check_and_call $CFG_PATH aposcfg_bash-bashrc-local.sh
 
  # Create system disk folders
  apos_check_and_call $CFG_PATH apos_mkdir_sd.sh
  
  # /usr/share/filem/internal_filem_root.conf file set up
  # /usr/share/filem/nbi_filem_root.conf file set up
  #
  # NOTE: this configuration file MUST be executed before any other
  # configuration file depending on the EXTERNAL/INTERNAL nbi root.
  # For example: aposcfg_sshd_config.sh, apos_ftpconf.sh.
  
  apos_check_and_call $CFG_PATH apos_fuseconf.sh
  
  # /etc/profile.local file set up
  if isAP2; then
    apos_check_and_call $CFG_PATH aposcfg_profile-local_AP2.sh
  else
    apos_check_and_call $CFG_PATH aposcfg_profile-local.sh
  fi
  
  # root remote login forbiddance
  apos_log 'calling apos_rootlock.sh'
  apos_check_and_exlocall $CFG_PATH apos_rootlock.sh
  
  # /etc/sysctl.conf file set up
  apos_check_and_call $CFG_PATH aposcfg_sysctl-conf.sh
  
  # /etc/init.d/boot.local file set up
  apos_check_and_call $CFG_PATH aposcfg_boot-local.sh
  
  #/etc/sysconfig/auditd file set up
  apos_check_and_call $CFG_PATH aposcfg_auditd.sh
 
  #modifying Gep1 performance parameters
  apos_check_and_call $CFG_PATH apos_cba_workarounds.sh 
  
  # /etc/audisp/plugins.d/syslog.conf file set up
  apos_check_and_call $CFG_PATH aposcfg_syslog-conf.sh
   
  # /etc/login.defs file set up - set Maximum Password Age, Minimum Password
  # Age, and ability to give information from previous login  
  apos_check_and_call $CFG_PATH aposcfg_login-defs.sh

  apos_check_and_call $CFG_PATH apos_certgrp.sh

  
  # vBSC: Handling RP-VM keys for SSH management
  # BEGIN: RP-VM Handling
  if isvBSC; then
    apos_check_and_call $CFG_PATH aposcfg_rp_sshkey_mgmt.sh
  else
    apos_log "Nothing to do as apt_type is not BSC"
  fi
  # END : RP-VM Handling
  
  # /etc/syncd.conf file set up
  apos_check_and_call $CFG_PATH aposcfg_syncd-conf.sh
  
  # /etc/pam.d/common-password file set up 
  apos_check_and_call $CFG_PATH aposcfg_common-password.sh

  # /etc/security/opasswd file set up - If not preset create the file for
  # storing old user password
  apos_check_and_call $CFG_PATH aposcfg_opasswd.sh
  
  # /etc/pam.d/common-account file set up
  apos_check_and_call $CFG_PATH aposcfg_common-account.sh
  
  # /etc/pam.d/common-auth file set up
  apos_check_and_call $CFG_PATH aposcfg_common-auth.sh
  
  # /etc/pam.d/common-session file set up
  apos_check_and_call $CFG_PATH aposcfg_common-session.sh

  # simlink between /etc/pam.d/sshd and /etc/pam.d/login
  ln -f -s /etc/pam.d/sshd /etc/pam.d/login || apos_abort 1 'creation of simlink /etc/pam.d/login failed'
  
  # simlink between /etc/pam.d/sshd and /etc/pam.d/vsftpd
  ln -f -s /etc/pam.d/sshd /etc/pam.d/vsftpd || apos_abort 1 'creation of simlink /etc/pam.d/vsftpd failed'

  # simlink between /etc/pam.d/sshd and /etc/pam.d/remote
  ln -f -s /etc/pam.d/sshd /etc/pam.d/remote || apos_abort 1 'creation of simlink /etc/pam.d/remote failed'
  
  # /cluster/etc/motd file set up - set welcome Message for SSH and Telnet (ONLY on node1)
  #[ $HN_THIS = $HN_FIRST ] && apos_check_and_call $CFG_PATH aposcfg_motd.sh
  apos_log 'calling aposcfg_motd.sh'
  apos_check_and_exlocall $CFG_PATH aposcfg_motd.sh
  
  # /etc/nscd.conf setup for cached credentials implementation
  ! isAP2 && apos_check_and_call $CFG_PATH aposcfg_nscd-conf.sh
  
  # /etc/profile file set up - set inactivity Timer
  apos_check_and_call $CFG_PATH aposcfg_profile.sh
  
  # /etc/securetty file set up - to remove unneeded terminals (all TTYs except TTYS0)
  apos_check_and_call $CFG_PATH aposcfg_securetty.sh
  
  # /cluster/etc/group file set up - cluster root group set up
  #apos_check_and_call $CFG_PATH aposcfg_group.sh
  apos_log 'calling aposcfg_group.sh'
  apos_check_and_exlocall $CFG_PATH aposcfg_group.sh
 
  #apos_check_and_call $CFG_PATH aposcfg_appendgroup.sh
  apos_log 'calling aposcfg_appendgroup.sh'
  apos_check_and_exlocall $CFG_PATH aposcfg_appendgroup.sh
 
  # set the disk naming rules for APG
  apos_check_and_call $CFG_PATH apos_udevconf.sh
  
  # new user skeletons setup
  apos_check_and_call $CFG_PATH apos_skelconf.sh
  
  # smart disk handling
  apos_check_and_call $CFG_PATH apos_smartdisk.sh

  # failoverd framework adoptations
  apos_check_and_call $CFG_PATH apos_failoverd_conf.sh
  
  # Configuration files deployment routines.
  if [ -x /opt/ap/apos/conf/apos_deploy.sh ]; then
     
    # check AP type
    if ! isAP2; then
      # AP1 files deployment
      LIST='etc/audit/rules.d/901-apg-users.rules
	    etc/openldap/slapd.conf
            etc/openldap/schema/euac-extended.schema
            etc/ssh/sshd_config_22
            etc/ssh/sshd_config_4422
            etc/ssh/sshd_config_mssd
            etc/ssh/sshd_config_830
            etc/sysconfig/atftpd
            etc/sysconfig/auditd
            etc/sysconfig/openldap
            etc/systemd/system/dhcpd.service.d/lde.conf
            etc/dhcpd.conf.local
            usr/lib/lde/config-management/apos_dhcpd-config
            usr/lib/lde/config-management/apos_drbd-config
            usr/lib/lde/config-management/apos_exports-config
            usr/lib/lde/config-management/apos_ftp-config
            usr/lib/lde/config-management/apos_grub-config
            usr/lib/lde/config-management/apos_ip-config
            usr/lib/lde/config-management/apos_logrotd-config
            usr/lib/lde/config-management/apos_rhosts-config
            usr/lib/lde/config-management/apos_secacs-config
            usr/lib/lde/config-management/apos_sshd-config
            usr/lib/lde/config-management/apos_syslog-config
            usr/lib/systemd/scripts/apg-atftps.sh
            usr/lib/systemd/scripts/apg-auditd.sh
            usr/lib/systemd/scripts/apg-clearchipwdog.sh
            usr/lib/systemd/scripts/apg-dhcpd.sh
            usr/lib/systemd/scripts/apg-ldap.sh
            usr/lib/systemd/system/apg-atftpd@.service
            usr/lib/systemd/system/apg-atftps.service
            usr/lib/systemd/system/apg-clearchipwdog.service
            usr/lib/systemd/system/apg-dhcpd.service
            usr/lib/systemd/system/apg-ldap.service
            usr/lib/systemd/system/apg-netconf-beep@.service
            usr/lib/systemd/system/apg-netconf-beep.socket
            usr/lib/systemd/system/apg-rsh@.service
            usr/lib/systemd/system/apg-rsh.socket
            usr/lib/systemd/system/apg-vsftpd@.service
            usr/lib/systemd/system/apg-vsftpd.socket
            usr/lib/systemd/system/apg-vsftpd-nbi@.service
            usr/lib/systemd/system/apg-vsftpd-nbi.socket
            usr/lib/systemd/system/apg-vsftpd-APIO_1@.service
            usr/lib/systemd/system/apg-vsftpd-APIO_1.socket
            usr/lib/systemd/system/apg-vsftpd-APIO_2@.service
            usr/lib/systemd/system/apg-vsftpd-APIO_2.socket
            usr/lib/systemd/system/auditd.service
            usr/lib/systemd/system/dhcpd.service
            usr/share/filem/internal_filem_root.conf
            usr/share/filem/nbi_filem_root.conf'
    else
      # AP2 files deployment
      LIST='etc/audit/rules.d/901-apg-users.rules
	    etc/sysconfig/atftpd
	    usr/lib/systemd/scripts/apg-atftps.sh
	    usr/lib/systemd/system/apg-atftpd@.service
	    usr/lib/systemd/system/apg-atftps.service
	    etc/openldap/slapd.conf
            etc/openldap/schema/euac-extended.schema
            etc/sysconfig/auditd
            etc/systemd/system/dhcpd.service.d/lde.conf
            etc/ssh/sshd_config_22
            etc/ssh/sshd_config_830   
            etc/ssh/sshd_config_4422
            etc/dhcpd.conf.local
            usr/lib/lde/config-management/apos_drbd-config
            usr/lib/lde/config-management/apos_exports-config
            usr/lib/lde/config-management/apos_ftp-config
            usr/lib/lde/config-management/apos_grub-config
            usr/lib/lde/config-management/apos_ip-config
            usr/lib/lde/config-management/apos_logrotd-config
            usr/lib/lde/config-management/apos_rhosts-config
            usr/lib/lde/config-management/apos_secacs-config
            usr/lib/lde/config-management/apos_sshd-config
            usr/lib/lde/config-management/apos_syslog-config
            usr/lib/systemd/scripts/apg-auditd.sh
            usr/lib/systemd/scripts/apg-clearchipwdog.sh
            usr/lib/systemd/scripts/apg-dhcpd.sh
            usr/lib/systemd/system/apg-clearchipwdog.service
            usr/lib/systemd/system/apg-dhcpd.service
            usr/lib/systemd/system/apg-rsh@.service
            usr/lib/systemd/system/apg-rsh.socket
            usr/lib/systemd/system/apg-vsftpd@.service
            usr/lib/systemd/system/apg-vsftpd.socket
            usr/lib/systemd/system/apg-vsftpd-nbi@.service
            usr/lib/systemd/system/apg-vsftpd-nbi.socket
            usr/lib/systemd/system/auditd.service
            usr/lib/systemd/system/dhcpd.service
            usr/share/filem/internal_filem_root.conf
            usr/share/filem/nbi_filem_root.conf'
    fi
    
    SRC='/opt/ap/apos/etc/deploy'
    for ITEM in $LIST; do
      $(echo $ITEM | grep -q "apos_drbd" ) && {
        isMD && continue
      }
      ./apos_deploy.sh --from $SRC/$ITEM --to /$ITEM
      [ ! $? = 0 ] && apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code"
    done
    
    if [ $CACHE_DURATION -ne 0 ] && is_restore; then
      # Only executed if cached credentials is enabled and this script is executed after a restore.
      # Invalidate the LDAP Cache with SSSD (truncate it)
      /usr/bin/truncate --size=0 $SSSD_LDAP_CACHE_FILE_PATH || apos_abort 'Failure while erasing the LDAP cache'
    fi
    
    # /etc/ssh/sshd_config file set up - SSH server configuration for external networks
    apos_check_and_call $CFG_PATH aposcfg_sshd_config.sh

    # deploy 10g enabled drbd configuration file if required.
    is10G && ./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_drbd-config_10g" --to "/usr/lib/lde/config-management/apos_drbd-config"

    # Following configuration files are deployed in case of virtualized environment (ECS, VMWare)
    # 1. deployment of apos_drbd-config_VM 
    # 2. deployment of dhcpd.conf.local_vm
    # 3. deployment of ntp.conf.local and apos_ntp-config 
    if isvAPG; then 
      ./apos_deploy.sh --from "$SRC/etc/dhcpd.conf.local_vm" --to "/etc/dhcpd.conf.local"
      ./apos_deploy.sh --from "$SRC/etc/ntp.conf.local" --to "/etc/ntp.conf.local" 
      ./apos_deploy.sh --from "$SRC/etc/chrony.conf.local" --to "/etc/chrony.conf.local" 
      ./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_ntp-config" --to "/usr/lib/lde/config-management/apos_ntp-config" 
      ./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_rp-hosts-config" --to "/usr/lib/lde/config-management/apos_rp-hosts-config"
      ./apos_deploy.sh --from "$SRC/usr/lib/lde/config-management/apos_drbd-config_VM" --to "/usr/lib/lde/config-management/apos_drbd-config"
    fi
  
    # deploy /etc/services based on the replication type
    if isMD; then
      ./apos_deploy.sh --from "$SRC/etc/services_md" --to "/etc/services" 
    else
      ./apos_deploy.sh --from "$SRC/etc/services_drbd" --to "/etc/services" 
    fi
    
    ./apos_deploy.sh --from "$SRC/etc/bindresvport.blacklist" --to "/etc/bindresvport.blacklist"

    apos_servicemgmt stop lde-syncd.service &>/dev/null || apos_abort 'failure while stopping lde-syncd service'
    if isMD; then
      ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_md" --to "/etc/sudoers.d/APG-comgroup"
      ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_md" --to "/etc/sudoers.d/APG-tsgroup"
    else
      ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-comgroup_drbd" --to "/etc/sudoers.d/APG-comgroup"
      ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsgroup_drbd" --to "/etc/sudoers.d/APG-tsgroup"
    fi
    ./apos_deploy.sh --from "$SRC/etc/sudoers.d/APG-tsadmin" --to "/etc/sudoers.d/APG-tsadmin"
    apos_servicemgmt start lde-syncd.service &>/dev/null || apos_abort 'failure while starting lde-syncd service'
# APG customized rule for logrotation
 ./apos_deploy.sh --from "$SRC/etc/10-apg-rsyslog-rule" --to "/etc/logrot.d/10-apg-rsyslog-rule"
    apos_servicemgmt restart lde-logrot.service &>/dev/null || apos_abort 'failure while restarting lde-logrot service'

# APG customized rule for mml syslog stream
    apos_log 'checking SYSLOG_PATH'
    if [ -x "$SYSLOG_PATH"]; then
       apos_log 'Syslog Copying 02-lde-syslog-logstream-list.conf file'
       ./apos_deploy.sh --from "$SRC/etc/02-lde-syslog-logstream-list.conf" --to "/etc/syslog-logstream.d/02-lde-syslog-logstream-list.conf"
       apos_log 'Successfully deployed 02-lde syslog-logstream-list.conf file' 
    else
        apos_log 'Syslog path not found,02-lde-syslog-logstream-list.conf file not copied'
        
    fi

apos_log 'Restarting lde log controller'
/usr/bin/amf-adm restart safSu=SC-1,safSg=2N,safApp=ERIC-ldews.logcontroller.sc
/usr/bin/amf-adm  restart safSu=SC-2,safSg=2N,safApp=ERIC-ldews.logcontroller.sc
 
# DR hooks copy
    ./apos_deploy.sh --from "$SRC/cluster/hooks/after-booting-from-disk.tar.gz" --to "/cluster/hooks/after-booting-from-disk.tar.gz" --exlo
    ./apos_deploy.sh --from "$SRC/cluster/hooks/post-installation.tar.gz" --to "/cluster/hooks/post-installation.tar.gz" --exlo
    ./apos_deploy.sh --from "$SRC/cluster/hooks/pre-installation.tar.gz" --to "/cluster/hooks/pre-installation.tar.gz" --exlo
  
  else
    apos_abort 1 '/opt/ap/apos/conf/apos_deploy.sh not found or not executable'
  fi
  
  # apos lde adaptations
  if [ -x /opt/ap/apos/conf/apos_insserv.sh ]; then
    BASEDIR='/usr/lib/lde/config-management'
    APOS_LINKS="$(find $BASEDIR/start -name '[SKC]*[0-9]*apos_*')"
    APOS_LINKS="$APOS_LINKS $(find $BASEDIR/stop -name '[SKC]*[0-9]*apos_*')"
    APOS_LINKS="$APOS_LINKS $(find $BASEDIR/config -name '[SKC]*[0-9]*apos_*')"
    for AL in $APOS_LINKS; do
      apos_log "removing old link: $AL"
      rm $AL || apos_abort "failed to remove $AL"
    done
    APOS_FILES=$(ls -d1 /usr/lib/lde/config-management/apos_*)
    for AF in $APOS_FILES; do
      ./apos_insserv.sh $AF
      if [ $? -ne 0 ]; then
        apos_abort 1 "\"apos_insserv.sh\" exited with non-zero return code"
      fi
    done
    
    # Work around to mitigate race condition during restore.
    # When a cluster reload is executed simultaneously
    # such reload will fail. Below is WA to mitigate this case.

    kill_after_try 3 30 360 "cluster config --reload &>/dev/null" 2>/dev/null || apos_abort 1 'ERROR: Failed to reload cluster configuration'
  else
    apos_abort 1 '/opt/ap/apos/conf/apos_insserv.sh not found or not executable'
  fi
 
  # rsh server configuration 
  apos_log 'executing aposcfg_rsh.sh --apos blk'
  apos_check_and_call $CFG_PATH aposcfg_rsh.sh

  # Configure COM
  apos_check_and_call $CFG_PATH apos_comconf.sh

  # FTP configuration
  apos_check_and_call $CFG_PATH apos_ftpconf.sh

  # NETCONF configuration
  apos_check_and_call $CFG_PATH apos_netconf.sh
 
  # apos-drbd installation on DRBD nodes
  ! isMD && apos_check_and_call $CFG_PATH apos_drbdconf.sh
  
  # only for virtual environments 
  if isvAPG; then 
    apos_log 'executing apos_sysconf.sh --apos blk'
    # deploy some configuration scripts
    apos_check_and_call $CFG_PATH apos_sysconf.sh 

    # modify service unit file for vmware tools
    apos_check_and_call $CFG_PATH apos_guest.sh 
  fi
  
  # blacklists uneeded, buggy or problematic kernel modules
  apos_check_and_call $CFG_PATH apos_blacklistconf.sh

  # As part of CISCAT improvements feature disabling unused filesystems 
  # Deploying lde-disable-unused-filesystems.conf file during Installation
  ./apos_deploy.sh --from "$SRC/etc/modprobe.d/lde-disable-unused-filesystems.conf" --to "/etc/modprobe.d/lde-disable-unused-filesystems.conf"
  apos_log 'Successfully deployed lde-disable-unused-filesystems.conf file'
  
  # new script to set vlan QoS settings like PCP/DSCP setting
  if isBSP || isSMX ; then
    apos_check_and_call $CFG_PATH apos_vlanqos.sh
  fi
  
  # New script to disable ldap case sensitivity
  apos_check_and_call $CFG_PATH apos_sec-ldapconf.sh
  
  ################################################################
  ##                                                            ##
  # Services setup to avoid a reboot after the APOS installation #
  ##                                                            ##
  ################################################################
  # apos_servicemgmt reload <SERVICE> --type=service, Internally the value .<SERVICE>. is ignored and
  # it is always invoked systemctl daemon-reload that is applicable for the entire system
  apos_servicemgmt reload APOS --type=service &>/dev/null || apos_abort 'failure while reloading system services'
  
  echo 'subscribing watchdog timeout value in lde-watchdog.service file..'
  WATCHDOG_INTERVAL="-s 180"
  apos_servicemgmt subscribe "lde-watchdogd.service" "ExecStartPre" /usr/bin/wdctl $WATCHDOG_INTERVAL || apos_abort 'failure subscribing watchdog timeout..'
  apos_servicemgmt restart lde-watchdogd.service &>/dev/null || apos_abort 'failure while restarting lde-watchdog service'
  echo 'done'
 
  echo 'configuring clearchipwdog startup...'
  apos_servicemgmt enable apg-clearchipwdog.service &>/dev/null || apos_abort 'failure while configuring clearchipwdog startup'
  echo 'done'
 
 
  if isvAPG; then
    echo 'subscribing ExecStartPost in lde-network.service file..'
    apos_servicemgmt subscribe "lde-network.service" "ExecStartPost" /opt/ap/apos/conf/apos_kernel_parameter_change.sh || apos_abort 'failure subscribing kernel parameter change..'
    echo 'done'

    if systemctl -q is-active lde-network.service ; then
      apos_log 'lde-network service is active, executing apos_kernel_parameter_change.sh script '
      apos_check_and_call $CFG_PATH apos_kernel_parameter_change.sh
    fi

    # update default GW for IPv6 
    apos_check_and_call $CFG_PATH apos_add_default_ipv6_gw.sh
  fi
 
  echo 'restarting iptables daemon...'
  apos_servicemgmt restart lde-iptables.service &>/dev/null || apos_abort 'failure while restarting iptables service'
  echo 'done'
  
  echo 'enabling ssh daemon on 4422 port...'
  apos_servicemgmt enable lde-sshd@sshd_config_4422.service &>/dev/null || apos_abort 'failure while enabling sshd_config_4422 service'

  echo 'enabling ssh daemon on 830 port...'
  apos_servicemgmt enable lde-sshd@sshd_config_830.service &>/dev/null || apos_abort 'failure while enabling sshd_config_830 service'

  echo 'enabling ssh daemon on 22 port...'
  apos_servicemgmt enable lde-sshd@sshd_config_22.service &>/dev/null || apos_abort 'failure while enabling sshd_config_22 service'
 
  if ! isAP2; then
    apos_servicemgmt enable lde-sshd@sshd_config_mssd.service &>/dev/null || apos_abort 'failure while enabling sshd_config_mssd service'
  fi
  
  echo 'disabling and stopping ssh daemons on sshd_config file....'
  stop_disable_sshdconfig
 
  apos_servicemgmt restart lde-sshd.target &>/dev/null || apos_abort 'failure while restarting lde-sshd target'
  echo 'done'
  
  echo 'restarting dhcp daemon...'
  apos_servicemgmt restart dhcpd.service &>/dev/null || apos_abort 'failure while restarting dhcpd service'
  echo 'done'
  

  ##
  # WORKAROUND: BEGIN
  # DESCRIPTION: Please uncomment the following lines for when the final solution will be implemented.
  #echo 'changing bonding mode to broadcast...'
  #INTERFACE='bond0'
  #if /bin/ip link ls $INTERFACE &>/dev/null; then
  #  BONDING_MODE='3'
  #  /sbin/ip link set down dev ${INTERFACE} &>/dev/null || apos_abort "failure while shutting down ${INTERFACE}"
  #  echo "$BONDING_MODE" > /sys/class/net/${INTERFACE}/bonding/mode || apos_abort 'failure while setting bonding mode'
  #  /sbin/ip link set up dev ${INTERFACE} &>/dev/null || apos_abort "failure while bringing up ${INTERFACE}"
  #  echo 'done'
  #else
  #  echo 'no bonding interface found, skipping configuration'
  #fi
  # WORKAROUND: END
  ## 

  # USA impacts: Updating Description of rsyslog.service file
  apos_check_and_call $CFG_PATH aposcfg_rsyslog_service.sh

  echo 'performing syslog configuration reload...'
  apos_servicemgmt restart rsyslog.service &>/dev/null || apos_abort 'failure while restarting syslog service'
  echo 'done'

 # /etc/audit/audit.rules file set up
  apos_check_and_call $CFG_PATH aposcfg_audit-rules.sh
 
  echo 'starting auditd daemon...'
  apos_servicemgmt restart auditd.service &>/dev/null || apos_abort 'failure while restarting auditd service'
  echo 'done'

  # Group check of the LDAP deamon
  GRP_N=$(getent group sec-credu-users|wc -l)
  [ "$GRP_N" -ne 1 ] && apos_abort 'failure while checking for the group "sec-credu-users" existance'
  
  popd &> /dev/null
else
  apos_abort "the folder $CFG_PATH cannot be found!"
fi

##
# WORKAROUND FOR JOURNALD SOCKET MEMORY FIX: BEGIN
if [ "$HW_TYPE"  == 'GEP1' ] || [ "$HW_TYPE"  == 'GEP2' ]; then 
  [ ! -f /etc/systemd/journald.conf ] && apos_abort 'journald.conf file not found'
  if grep -q '^#Storage=.*$' /etc/systemd/journald.conf 2>/dev/null; then 
    sed -i 's/#Storage=.*/Storage=none/g' /etc/systemd/journald.conf 2>/dev/null || \
      apos_abort 'Failure while updating journald.conf file with Storage=none parameter'
    # Re-start the systemd-journald.service
    apos_servicemgmt restart systemd-journald.service &>/dev/null || apos_abort 'failure while restarting systemd-journald service'
  else
    apos_log 'WARNING: Storage value found different than auto. Skipping configuration changes'
  fi 

  # Cleanup of Journal directory
  if [ -d /run/log/journal ]; then 
    /usr/bin/rm -rf '/run/log/journal' 2>/dev/null || apos_log 'failure while cleaning up journal folder'
  fi 
fi
# WORKAROUND FOR JOURNALD SOCKET MEMORY FIX: END
##

##
# WORKAROUND FOR TR:HX28643 BEGIN
if [ "$HW_TYPE" == "GEP5" ]; then
	eri-ipmitool wbcsgep5 -b 18 0x30
fi
# WORKAROUND FOR TR:HX28643 END
##

 
# Disable the postfix service 
disable_postfix_service


# Create the flag to be used by next invocations to understand if a restore has been performed
touch $(apos_create_brf_folder clear)/$RESTORE_FLAG || apos_abort 'Failure while creating the restore flag'

#Copy the lde-watchdogd interval file from /storage area to /usr/lin
if [ "$HW_TYPE"  == "VM" ];then
	setWatchdogInterval
fi

# Commenting Defaults secure_path in sudoers file to exexute swmgr command
# without permissions denied issue by apgswmgr user.
sed -e '/Defaults secure_path/ s/^#*/#/' -i $SUDOERS_FILE 2>/dev/null
if [ $? -eq 0 ]; then
  apos_log "Commenting Defaults secure_path in sudoers file success"
else
  apos_log "Commenting Defaults secure_path in sudoers file fail"
fi

# Fix for TR HY77682
sed -i 's/Defaults env_keep = "[^"]*/& USER CLIENT_IP PORT USER_IS_CACHED/' $SUDOERS_FILE 2>/dev/null
if [ $? -eq 0 ]; then
  apos_log "Updating env_keep variable in sudoers file success"
else
  apos_log "Updating env_keep variable in sudoers file fail"
fi

# Commenting Defaults use_pty in /etc/sudoers.d/lde-sudo-config file to CBANBC-301 impact in APG

sed -e '/Defaults use_pty/ s/^#*/#/' -i $LDE_SUDO_FILE 2>/dev/null
if [ $? -eq 0 ]; then
  apos_log "Commenting Defaults use_pty in lde-sudo-config file success"
else
  apos_log "Commenting Defaults use_pty in lde-sudo-config file fail"
fi


#Removing tlsdTraceFile.log
if [ -f $TMP_FILE ]; then
  /usr/bin/rm -rf $TMP_FILE 2>/dev/null || apos_log 'tlsdTraceFile.log not available'
fi

#Disable automaticBackup attribute
immcfg -a automaticBackup="0" CmwSwMswMId=1
if [ $? -eq 0 ]; then
  apos_log "automaticBackup is disabled"
else
  apos_log "Failed to disable automaticBackup"
fi

#Disable automaticRestore attribute
immcfg -a automaticRestore="0" CmwSwMswMId=1
if [ $? -eq 0 ]; then
  apos_log "automaticRestore is disabled"
else
  apos_log "Failed to disable automaticRestore"
fi

##Begin: RPC IPV6 impact
touch "/etc/netconfig-try-2-first" || apos_log 'Failure while creating the netconfig file'
##end

apos_outro $0
exit $TRUE

# End of file
