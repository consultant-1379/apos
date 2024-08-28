#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_comconf.sh
# Description:
#       A script to setup parameters for COM.
# Note:
#   To be executed on both nodes.
##
# Usage:
#   None.
##
# Output:
#       None.
##
# Changelog:
# - Mon May 02 2024 - Surya Mahit (zsurjon)
#       Fix for TR IA80841
# - Mon Jan 02 2024 - Swpanika Baradi (xswapba)
#       Fix for TR IA69600
# - Mon Jul 15 2019 - Yeswanth Vankayala (xyesvan)
#       Fix for TR HX78973 and HX79009
# - Tue Apr 30 2019 - Suman Kumar Sahu (zsahsum)
# - 	Improvement in port values for Ftp over Tls
# - Mon Apr 08 2019 - Suman kumar sahu (zsahsum)
# -	Updated the script to handle FTP over TLS
# - Wed Mar 29 2018 - Harika bavana (xharbav)
#       Handled OAM-SA configuration
# - Thu Dec 27 2017 - Rajashekar Narla (xcsrajn)
#       Added logging mechanism during cofiguration file cleanup from storage area.
# - Fri Sep 01 2016 - Dharma Teja (xdhatej)
#       Fix included for TR:HW16938
# - Fri Apr 28 2016 - Yeshwanth Vankayala (xyesvan)
#       Adopted impacts for COM 7.1 CP3 Integration 
# - Mon Jun 16 2016 - Avinash Gundlapally (xavigun)
#       smart libcli_extension_subshell.cfg file for all configurations.
# - Mon May 23 2016 - Avinash Gundlapally (xavigun)
#       Handled libcli_extension_subshell.cfg file for vAPZ.
# - Thu Jan 14 2016 - Antonio Buonocunto (eanbuon)
#       Configure COMSA imm syncr timeout.
# - Fri May 7 2015 - Antonio Buonocunto (eanbuon)
#       Move access mgmt configuration to apos_ldapconf.
# - Fri Mar 14 2014 - Antonio Buonocunto (eanbuon)
#       added ap2_oam handling.
# - Thu Feb 25 2014 - Antonio Buonocunto (eanbuon)
#       added libcom_cli_agent handling.
# - Fri Jun 21 2013 - Francesco Rainone (efrarai)
#   	Removed libcom_cli_agent.cfg (move to apos_finalize.sh).
# - Wed Mar 20 2013 - Vincenzo Conforti (qvincon)
#   	Changed to manage AP2 configuration
# - Thu Jan 06 2013 - Francesco Rainone (efrarai)
#   	Added libcom_access_mgmt.cfg to configure LDAPS on port 636 in COM.
# - Fri Nov 23 2012 - Paolo Palmieri (epaopal)
#   	Added --exlo option to manage exclusive lock when destination is a file under /cluster.
# - Tue Nov 14 2012 - Francesco Rainone (efrarai)
#   	First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
pushd '/opt/ap/apos/conf/' >/dev/null
DEST_DIR='/opt/com/'
SA_FILES=''
COMSA_IMMA_SYNCR_TIMEOUT="360000"
PSO_FOLDER=$( apos_check_and_cat $STORAGE_CONFIG_PATH)
COM_FOLDER="$PSO_FOLDER/com-apr9010443/lib/comp"
COMSA_CONFIG_PSO="$PSO_FOLDER/comsa_for_coremw-apr9010555/etc"
OAM_SA_STORAGE_FOLDER="$PSO_FOLDER/bsc-sa/"
FIND="/usr/bin/find"
INTR_ROOT_PATH='/data/opt/ap/nbi_fuse'
VSFTPD_FILE=/opt/com-vsftpd/etc/com-vsftpd.conf
IMMFIND_FTPTLSSERVER='ftpTlsServerId=1,ftpServerId=1,fileTPMId=1'
IMMLIST='/usr/bin/immlist'

# Removes all the configuration files from COM's storage area                                #
function cleanup() {
  STORAGE_COM_CONF_FILES='libcli_extension_subshell.cfg
                          libcom_cli_agent.cfg
                          libcom_authorization_agent.cfg
                          libcom_tlsd_manager.cfg
                          libcom_tls_proxy.cfg'
  for file in $STORAGE_COM_CONF_FILES
  do
    if [ -f $COM_FOLDER/$file ]; then
      apos_log  " $file available in $COM_FOLDER\. Removing the file from storage path."
      rm -f $COM_FOLDER/$file
      apos_log "removal completed"
    else
      apos_log "$file not available in $COM_FOLDER\.Skipping the changes!!"
    fi
  done

}

function deploy_files(){
STORAGE_COM_CONF_FILES='libcom_cli_agent.cfg
                          libcom_authorization_agent.cfg
                          libcom_tlsd_manager.cfg
                          libcom_tls_proxy.cfg'


if [ -x /opt/ap/apos/conf/apos_deploy.sh ]; then
  [ ! -d $DEST_DIR ] && apos_abort 1 'unable to retrieve COM configuration folder'
  #checking if /opt/ap/apos/conf/apos_lib_subshell_config.sh is executable.
  if [ ! -x /opt/ap/apos/conf/aposcfg_libcli_extension_subshell.sh ]; then
    apos_abort 1 "\"aposcfg_libcli_extension_subshell.sh\" does not exist or does not have execute permission"
  fi
  #generate libcli_extension_subshell.cfg
  ./aposcfg_libcli_extension_subshell.sh
  if [ $? -ne 0 ]; then
    apos_abort 1 "\"aposcfg_libcli_extension_subshell.sh\" exited with non-zero return code"
  fi

  for file in $STORAGE_COM_CONF_FILES
  do
    ./apos_deploy.sh --from /opt/ap/apos/conf/$file --to $DEST_DIR/lib/comp/$file
    if [ $? -ne 0 ]; then
      apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code for $file"
    fi
    ./apos_deploy.sh --from /opt/ap/apos/conf/$file --to $COM_FOLDER/$file
    apos_log "$file file replaced in COM and PSO paths"
  done
else
  apos_abort 1 '/opt/ap/apos/conf/apos_deploy.sh not found or not executable'
fi

}

function ftp_port_conf () {
  res=$(immfind |grep $IMMFIND_FTPTLSSERVER)
  if [ $? -eq 0 ] ; then
    apos_log "Found FtpTlsServer MO, configuring port values for Ftp over Tls"
    port_val=$( $IMMLIST -a port ftpTlsServerId=1,ftpServerId=1,fileTPMId=1 | cut -d= -f 2 )
    max_port_val=$( $IMMLIST -a maxDataPort ftpTlsServerId=1,ftpServerId=1,fileTPMId=1 | cut -d= -f 2 )
    min_port_val=$($IMMLIST -a minDataPort ftpTlsServerId=1,ftpServerId=1,fileTPMId=1 | cut -d= -f 2)
    if [[ -z "$port_val"  ||  $port_val -ne 990 ]]; then
        kill_after_try 3 3 4 immcfg -a port='990' $IMMFIND_FTPTLSSERVER || apos_abort 1 "Failed to configure port for Ftp over Tls"
    fi
    if [[ -z "$max_port_val"  ||  $max_port_val -ne 30300 ]]; then
        kill_after_try 3 3 4 immcfg -a maxDataPort='30300' $IMMFIND_FTPTLSSERVER || apos_abort 1 "Failed to configure maximum data port for Ftp over Tls"
    fi
    if [[ -z "$min_port_val"  ||  $min_port_val -ne 30200 ]]; then
        kill_after_try 3 3 4 immcfg -a minDataPort='30200' $IMMFIND_FTPTLSSERVER || apos_abort 1 "Failed to configure minimum data  port for Ftp over Tls"
    fi
    apos_log "Configuration of port is completed for Ftp over Tls."
  else
    apos_log "$IMMFIND_FTPTLSSERVER not found, port value can't be configure for Ftp over Tls."
  fi
}

function com_tls_conf() {
  CLUSTER_MI_PATH='/cluster/mi/installation'
  app_type=$( $CMD_PARMTOOL get --item-list apt_type 2>/dev/null | awk -F'=' '{print $2}')
  if [ -z "$app_type" ]; then
    app_type=$( cat $CLUSTER_MI_PATH/apt_type)
    [ -z "$app_type" ] && apos_log"axe_application parameter not found!"
  fi

  if [ "$app_type" == BSC ]; then
    apos_log "BEGIN: Modifying renegotiation values for BSC Application"
    sed -i 's/<renegotiation>TRY/<renegotiation>NEVER/' /opt/com/lib/comp/libcom_tlsd_manager.cfg
    sed -i 's/<renegotiationTime>86400/<renegotiationTime>0/' /opt/com/lib/comp/libcom_tlsd_manager.cfg
    apos_log "END: Modifying renegotiation values for BSC Application"
  fi
}



#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|
#


#To clean all the configuration files from storage area
cleanup

#To deploy the com configuration files in storage and com path
deploy_files

  #OAM-SA libraries Spillover 7 ENM support
  if [ -d "$OAM_SA_STORAGE_FOLDER" ]; then
    SA_FILES=$($FIND $OAM_SA_STORAGE_FOLDER -name "*.so" -o -name "*.cfg")
    for LIB_PATH in $SA_FILES
    do
      ./apos_deploy.sh --from $LIB_PATH --to $DEST_DIR/lib/comp/
      if [ $? -ne 0 ]; then
        apos_abort 1 "\"apos_deploy.sh\" exited with non-zero return code for OAM-SA libraries"
      fi
    done
  fi

  # Configure imma syncr timeout for comsa.cfg
  # The unit of time is 10 milliseconds. The minimum allowed value is 10 (0.1 seconds).        
  for COMSA_CONFIG_PATH in $DEST_DIR/etc $COMSA_CONFIG_PSO
  do 
    COMSA_CONFIG_FILE="$COMSA_CONFIG_PATH/comsa.cfg"
    if [ -f "$COMSA_CONFIG_FILE" ]; then 
      sed -i "s@[[:space:]]*imma_syncr_timeout=.*@imma_syncr_timeout=$COMSA_IMMA_SYNCR_TIMEOUT@g" $COMSA_CONFIG_FILE 2>/dev/null
      if [ $? -ne 0 ]; then
        apos_abort 1 "Configuration of imma_syncr_timeout failed."
      else
        apos_log "imma_syncr_timeout configured to $COMSA_IMMA_SYNCR_TIMEOUT."
      fi 
    else
      apos_log "File [ $COMSA_CONFIG_FILE ] does not exist, skipping the configuration."
    fi
  done 

  # Configuring <lockMoForConfigChange> attribute to true in coremw-com-sa.cfg files
  #  In MI, during APOS installation, only local folder is available(i.e /opt/lib/com/). 
  #  COM storage path is available only after COM instantiation(i.e /storage/system/config/com-apr9010443/lib/comp)
  #  So, during MI, PSO path configuration is skipped. During restore and upgrade of APOS,  both paths are available and 
  #  configuration parameter updated on both path for file coremw-com-sa.cfg.

  for FILE_PATH in $DEST_DIR/lib/comp $COM_FOLDER
  do
    CONFIG_FILE="$FILE_PATH/coremw-com-sa.cfg"
    if [ -f $CONFIG_FILE ]; then
      sed -i 's#\(<lockMoForConfigChange>\)false\(</lockMoForConfigChange>\)#\1'true'\2#g' $CONFIG_FILE 2>/dev/null
      if [ $? -ne 0 ]; then
        apos_abort 1  "Failed to Configure <lockMoForConfigChange> attribute in $CONFIG_FILE"
      else
        apos_log "lockMoForConfigChange attribute set to TRUE in $CONFIG_FILE file."
      fi
    else
      apos_log "File [ $CONFIG_FILE ] does not exist, skipping the configuration."
    fi
  done

popd &>/dev/null

#Configuring home directory for ftp over tls to internal_root
if [ -f $VSFTPD_FILE ]; then
     apos_log "$VSFTPD_FILE is found, able to configure with sed fo com-vsftpd.conf"
     KEYWORD1='local_root='
     NEW_ROW1="local_root=$INTR_ROOT_PATH"
     PATH_VAL=$(cat $VSFTPD_FILE | grep -i $KEYWORD1 | cut -d = -f 2)
     if [ $INTR_ROOT_PATH != $PATH_VAL ]; then
        sed -i "s@$KEYWORD1.*@$NEW_ROW1@g" $VSFTPD_FILE
     fi	
else
  apos_log "$VSFTPD_FILE is not present, so not able to update the file using sed command"
fi

#Configuring port for Ftp over Tls
ftp_port_conf

com_tls_conf

apos_outro $0

exit $TRUE

# End of file
