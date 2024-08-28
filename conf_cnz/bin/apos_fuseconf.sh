#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_fuseconf.sh
# Description:
#       A script to configure nbi and internal root for Fuse.
# Note:
#	None.
##
# Usage:
#       filem_conf.sh 
##
# Output:
#       None.
##
# Changelog:
# - Tue Apr 03 2018 - Paolo Elefante (qpaoele)
#       As part of SwM2.0 adaptations the following functions have been
#       added to make LDE aware about the configuration changes applied 
#       by this script at installation time: restartLdeNbiRootService, activateNbiRootOnControllerNodes
# - Fri May 11 2015 - Fabio Ronca (efabron)
#       Add configuration for LDE NBI FS root path
# - Fri Aug 24 2012 - Antonio Buonocunto (eanbuon)
#       New DNs for Axe Models adaptation
# - Tue Jul 12 2012 - Salvatore Delle Donne (teisdel)
##	added BRF adaptation
# - Tue Apr 24 2012 - Salvatore Delle Donne (teisdel)
##       First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

CFG_PATH="/opt/ap/apos/conf"
fuse_path="/usr/share/filem"
nbi_root_file="nbi_filem_root.conf"
internal_root_file="internal_filem_root.conf"
lde_nbi_fs_path="/usr/share/ericsson/cba/nbi-root-dir"
internalRoot=""
externalRoot=""

# log script starting
apos_intro $0


# Printout the correct command usage in case of
#  wrong input parameter provided at command line
function usage() {
    echo 'the command requires no option'
    echo 'Usage: apos_fuseconf.sh'
    echo
}

#  IF fuse configuration files are already present in the PSO
#  storage area we are in a restore step so copy them to fuse
#  configuration path. 
#  If fuse configuration files are not present in the PSO storage
#  area we are in installation phase so create the fuse conf file
#  retrieving information from NBIFolder model the path for internal 
#  and  external folder for fuse configuration and fill the
#  configurations files. Fuse conf files are also copied to PSO storage
#  area.

function do_conf_fuse() {

  if [ -d $fuse_path ]; then
    apos_log "$fuse_path Folder already exists proceed with configuration"
  else
    apos_log "$fuse_path Folder does not exist create it and proceed with configuration"
    mkdir -p $fuse_path || apos_abort 'not possible to create $fuse_path folder'
  fi

  if [ -f $lde_nbi_fs_path ]; then
    apos_log "$lde_nbi_fs_path File exists proceed with configuration"	
  else
    apos_abort "$lde_nbi_fs_path File not exists. Not possible to configure NBI root FS folder."
  fi

  APOS_CONFIG_PATH=$(apos_create_brf_folder config)

  if [ -f $APOS_CONFIG_PATH/$internal_root_file ]; then
    cp -fp $APOS_CONFIG_PATH/$internal_root_file $fuse_path || apos_abort 'Failed to copy internal root conf file from PSO'
    apos_log "Fuse internal root configuration file restored from PSO storage area"
    cat $APOS_CONFIG_PATH/$internal_root_file > "$lde_nbi_fs_path" || apos_abort 'Failed to update NBI FS root path file from PSO'
  else
    internalRoot=$(immlist -a internalRoot AxeNbiFoldersnbiFoldersMId=1 2>/dev/null | awk -F'=' '{ print($2) }' 2>/dev/null)
    if [ -n "$internalRoot" ]; then
        echo $internalRoot > "$fuse_path/$internal_root_file"
        [ $? -ne $TRUE ] && apos_abort 'Failed to update fuse internal conf file'
				if [ "${NODE_THIS}" == 'SC-2-1' ]; then  
          pushd $CFG_PATH &> /dev/null
          ./apos_deploy.sh --from "$fuse_path/$internal_root_file" --to "$APOS_CONFIG_PATH/$internal_root_file" || \
            apos_abort 'Failed to copy internal root conf file to PSO'
          apos_log "Fuse internal root configuration file created and copied to PSO storage area"
          popd &> /dev/null
				fi 
        echo $internalRoot > "$lde_nbi_fs_path"
        [ $? -ne $TRUE ] && apos_abort 'Failed to update NBI FS root path file'
        apos_log "NBI FS root path configuration updated"
      else
        apos_abort 'internal root does not exist in IMM model'
      fi
  fi

  if [ -f $APOS_CONFIG_PATH/$nbi_root_file ]; then
    cp -fp $APOS_CONFIG_PATH/$nbi_root_file $fuse_path || apos_abort 'not possible to copy nbi root conf file from PSO'
    apos_log "Fuse nbi root configuration file restored from PSO storage area"
  else
    externalRoot=$(immlist -a externalRoot AxeNbiFoldersnbiFoldersMId=1 2>/dev/null | awk -F'=' '{ print($2) }' 2>/dev/null)
    if [ -n "$externalRoot" ]; then
      echo $externalRoot > "$fuse_path/$nbi_root_file"
      [ $? -ne $TRUE ] && apos_abort 'Failed to update fuse nbi root conf file'
			if [ "${NODE_THIS}" == 'SC-2-1' ]; then
        pushd $CFG_PATH &> /dev/null
        ./apos_deploy.sh --from "$fuse_path/$nbi_root_file" --to "$APOS_CONFIG_PATH/$nbi_root_file" --exlo || \
          apos_abort 'Failed to copy nbi root conf file to PSO'
        apos_log "Fuse nbi root configuration file created and copied to PSO storage area"
        popd &> /dev/null
			fi 
    else 
      apos_abort 'external root does not exist in IMM model'
    fi
  fi
}

# The function reads the command line argument list 
#  no parameters are expected for this command if
#  provided te command returns usage printout and
#  error code 1
#
function parse_cmdline() {
  if [ $# -gt 0 ]; then
    usage
    apos_abort "Wrong parameters ($1)"
  fi
}

# Restart the LDE NBI Service to make it aware about 
# the just configured new nbi root path. See Jira CC-17633.
# This must be executed on both Controller nodes only at installation time.
# The failure of this operation is not considered a fatal error 
# as it results in a warning at the end of the installation.
#
function restartLdeNbiRootService() {
  apos_log info "Restart the LDE NBI Service to make it aware about the just configured new nbi root path."
  apos_servicemgmt restart lde-nbi-root-dir.service
}

# Restart the LDE NBI Service to make it aware about 
# the just configured new nbi root path. See Jira CC-17633.
# This must be executed only at installation time.
# The failure of this operation is not considered a fatal error 
# as it results in a warning at the end of the installation.
#
function activateNbiRootOnControllerNodes(){
  apos_log info "activate Nbi Root on controller nodes"   
  case $NODE_THIS in
    SC-2-1)
      apos_log info "(1st) amf-adm si-swap safSi=SC-2N,safApp=ERIC-CoreMW"
      amf-adm si-swap safSi=SC-2N,safApp=ERIC-CoreMW
      if [ $? == 0 ];then
          apos_log info "(1st) amf-adm si-swap DONE"
      else
          apos_log err "(1st) amf-adm si-swap FAILED! RC: <$?>"
      fi

      apos_log info "(2nd) amf-adm si-swap safSi=SC-2N,safApp=ERIC-CoreMW"
      amf-adm si-swap safSi=SC-2N,safApp=ERIC-CoreMW
      if [ $? == 0 ];then
          apos_log info "(2nd) amf-adm si-swap DONE"
      else
          apos_log err "(2nd) amf-adm si-swap FAILED! RC: <$?>"
      fi
      apos_log info "done"
    ;;
    SC-2-2)
      apos_log info "NO ACTION ON SC-2-2"
    ;;
    *)
      apos_log err "NO ACTION ON unknown node <$NODE_THIS>"
  esac
}

# Main

NODE_THIS=$(</etc/cluster/nodes/this/hostname)

# Check command format
parse_cmdline $@

# Configure Fuse
do_conf_fuse

# Restart 
is_restore
is_system_restored=$?
if [ $is_system_restored != 0 ]; then
  apos_log info "No need to restart LDE Nbi Root Service ON Restore"
else
  apos_log info "Restart LDE Nbi Root Service ON Installation"
  
  # Make LDE aware about configuration changes
  restartLdeNbiRootService

  # Activate Nbi Root on controller nodes
  activateNbiRootOnControllerNodes
fi

# log succesfull script execution 
apos_outro $0

exit $TRUE

# End of file
