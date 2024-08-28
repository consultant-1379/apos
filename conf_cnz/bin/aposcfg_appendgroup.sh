#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2016 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       aposcfg_appendgroup-conf.sh
# Description:
#       A script to append new group to already existing process.
##
# Changelog:
# - Fri Mar 04 2016 - Antonio Buonocunto (eanbuon)
#       First version.
# - Tue Feb 18 2020 - Harika Bavana (xharbav)
#       Added cmw-imm-users group to wwwrun, ftpsecure users
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

CMD_GETENT="/usr/bin/getent"
USERMGMT="/opt/ap/apos/bin/usermgmt/usermgmt"
USER_LIST_TO_CONFIGURE="sec-cert:CERTGRP
                      com-core:AUDTLOGGRP|BCKPRESTGRP|CERTGRP|CPFILEGRP|CPMMLGRP|CPPRNTGRP|DATATRNSGRP|HELTHCHKGRP|LICENSEGRP|STSSCRGRP|SUPPTDATGRP|SWPKGGRP|TOOLSGRP
                      wwwrun:sec-credu-users|sec-crypto-users|sec-uai-users|cmw-imm-users
		      ftpsecure:cmw-imm-users"
for ITEM in $USER_LIST_TO_CONFIGURE;do
  ITEM_PROCESS="$(echo $ITEM| awk -F':' '{print $1}')"
  ITEM_PROCESS_GROUP_LIST="$($USERMGMT group list --user=$ITEM_PROCESS | awk -F':' '{print $2}')"
  ITEM_ADDITIONAL_GROUP_LIST="$(echo $ITEM| awk -F':' '{print $2}'| sed "s@|@ @g")"
  if [ $? -ne 0 ];then
    apos_abort "Failure while fetching group list for user $ITEM_PROCESS"
  fi
  for ITEM_ADDITIONAL_GROUP in $ITEM_ADDITIONAL_GROUP_LIST;do
    IS_GROUP_ASSIGNED="$FALSE"
    for ITEM_PROCESS_GROUP in $ITEM_PROCESS_GROUP_LIST;do
      if [ "$ITEM_ADDITIONAL_GROUP" = "$ITEM_PROCESS_GROUP" ];then
        IS_GROUP_ASSIGNED="$TRUE"
      fi
    done
    if [ "$IS_GROUP_ASSIGNED" = "$TRUE" ];then
      apos_log "Group $ITEM_ADDITIONAL_GROUP already assigned to $ITEM_PROCESS"
    else
      #check if group exists
      $CMD_GETENT group $ITEM_ADDITIONAL_GROUP &> /dev/null
      RC="$?"
      if [ $RC -eq 0 ];then
        $USERMGMT user modify --appendgroup --secgroups=$ITEM_ADDITIONAL_GROUP --uname=$ITEM_PROCESS
        if [ $? -ne 0 ];then
          apos_abort "Failure while adding group $ITEM_ADDITIONAL_GROUP to $ITEM_PROCESS user"
        fi
        apos_log "Group $ITEM_ADDITIONAL_GROUP assigned to $ITEM_PROCESS"
      elif [ $RC -eq 2 ];then
        apos_log "Group $ITEM_ADDITIONAL_GROUP not exists, skipping"
      else
        apos_abort "Failure while checking group $ITEM_ADDITIONAL_GROUP"
      fi
    fi
  done
done

apos_outro $0
exit $TRUE

