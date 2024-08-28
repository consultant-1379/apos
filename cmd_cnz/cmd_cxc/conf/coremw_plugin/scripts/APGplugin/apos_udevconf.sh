#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# apos_udevconf.sh
# A script to set the disk naming rules for APG.
##
# Changelog:
# - Thu May 30 2013 - Pratap Reddy Uppada(xpraupp)
#   First version.
##

# Copy the correct board-dependent file.
# Format: <PRIO>-apos_disks.rules
PRIO='66'
CMD_HWTYPE=''
HW_TYPE=''
FOUND=$FALSE
UDEV_RULES=''
NODE_ONE=1
NODE_TWO=2
HOOKS_DIR=''
TMP_RULES='/tmp/apos_disks.rules'
S_HWTYPES='GEP1 GEP2 GEP5 VM'
export VERBOSE=$FALSE
PLUGIN_SCRIPTS_ROOT="$(dirname "$(readlink -f $0)")"
# ------------------------------------------------------------------------
function sanity_check() {

  [ -f $TMP_RULES ] && /bin/rm $TMP_RULES
  UDEV_RULES="${PRIO}-apos_disks.rules"

  # Common functions sourcing
  common_functions="${PLUGIN_SCRIPTS_ROOT}/non_exec-common_functions"
  . ${common_functions}

  HW_TYPE=$(get_hwtype)
  for HW in $S_HWTYPES;do
    [ $HW == $HW_TYPE ] && FOUND=$TRUE
  done
  [ $FOUND -eq $FALSE ] && abort "The Hard-Ware type not supported" 
}

# ------------------------------------------------------------------------
function udev_rules_GEP1() {

  # Create udev rules for diskA and update
  # with header as well
  append_header

  [ $THIS_ID -eq $NODE_ONE ] && {
  cat << HEREDOC >> $TMP_RULES
# -- GEP1
# -- LEFT GED-SASF

KERNEL=="sd?", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="scsi",\
ATTRS{fw_id}=="0x0000", SYMLINK+="eri_diskA"
ENV{DEVTYPE}=="partition", ENV{ID_BUS}=="scsi", ATTRS{fw_id}=="0x0000", \
ENV{ID_PART_ENTRY_NUMBER}=="2", SYMLINK+="eri-meta-part"
ACTION="remove", KERNEL=="sd?", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="scsi", \
ATTRS{fw_id}=="0x0000", RUN="/bin/rm -f /dev/diskA*"

HEREDOC
        }

  [ $THIS_ID -eq $NODE_TWO ] && {
  cat << HEREDOC >> $TMP_RULES
# -- RIGHT GED-SASF

KERNEL=="sd?", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="scsi", \
ATTRS{fw_id}=="0x0004", SYMLINK+="eri_diskB"
ENV{DEVTYPE}=="partition", ENV{ID_BUS}=="scsi", ATTRS{fw_id}=="0x0004", \
ENV{ID_PART_ENTRY_NUMBER}=="2", SYMLINK+="eri-meta-part"
ACTION="remove", KERNEL=="sd?", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="scsi", \
ATTRS{fw_id}=="0x0004", RUN="/bin/rm -f /dev/diskB*"

HEREDOC
        }

  # Now copy created rule file to destination folder
  copy_udev_rules

}

# ------------------------------------------------------------------------
function udev_rules_VM(){

  # Create udev rules for diskA
  append_header

  cat << HEREDOC >> $TMP_RULES
# - FOR External Data Disk Attached to Node
KERNEL=="[sv]d?", SUBSYSTEM=="block", PROGRAM="$PLUGIN_SCRIPTS_ROOT/is_data_disk.sh %k", SYMLINK+="eri_disk"
ENV{DEVTYPE}=="partition", ENV{ID_PART_ENTRY_NUMBER}=="2", PROGRAM="$PLUGIN_SCRIPTS_ROOT/is_data_disk.sh %k", SYMLINK+="eri-meta-part"
HEREDOC
  # Now copy created rule file to destination folder
  copy_udev_rules

}

# ------------------------------------------------------------------------
function udev_rules_GEP5() {

  # Create udev rules for diskA
  append_header

  cat << HEREDOC >> $TMP_RULES
# -- GEP5
# -- LEFT-SASF
KERNEL=="sd*", ENV{DEVTYPE}=="disk", ATTRS{sas_address}=="0x4433221100000000", SYMLINK+="eri_disk"
ENV{DEVTYPE}=="partition", ATTRS{sas_address}=="0x4433221100000000", ATTR{partition}=="6", SYMLINK+="eri-meta-part"

HEREDOC
  # Now copy created rule file to destination folder
  copy_udev_rules

}

# ------------------------------------------------------------------------
function append_header() {

  # Appened header for data disk rules for APG
  cat << HEREDOC > $TMP_RULES
# This file contains the rules for the physical-to-logical disk mapping for APG.

# DO NOT WRAP THIS LINE
#
# old udev does not understand some of it,
# and would end up skipping only some lines, not the full rule.
# which can cause all sort of trouble with strange-named device nodes
# for completely unrelated devices,
# resulting in unusable network lookback, etc.
#
# in case this is "accidentally" installed on a system with old udev,
# having it as one single line avoids those problems.
#
# DO NOT WRAP THIS LINE

HEREDOC

}

# ------------------------------------------------------------------------
function udev_rules_GEP2() {

  # Create udev rules for diskA and update 
  # with header as well
  append_header

  [ $THIS_ID -eq $NODE_ONE ] && {
  cat << HEREDOC >> $TMP_RULES
# -- GEP2
# -- LEFT GED-SASF

KERNEL=="sd?", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="scsi",\
ATTRS{fw_id}=="0x0007", SYMLINK+="eri_diskA" 
ENV{DEVTYPE}=="partition", ENV{ID_BUS}=="scsi", ATTRS{fw_id}=="0x0007", \
ENV{ID_PART_ENTRY_NUMBER}=="2", SYMLINK+="eri-meta-part"
ACTION="remove", KERNEL=="sd?", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="scsi", \
ATTRS{fw_id}=="0x0007", RUN="/bin/rm -f /dev/diskA*"

HEREDOC
  }

  [ $THIS_ID -eq $NODE_TWO ] && {
  cat << HEREDOC >> $TMP_RULES
# -- RIGHT GED-SASF

KERNEL=="sd?", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="scsi", \
ATTRS{fw_id}=="0x0003", SYMLINK+="eri_diskB"
ENV{DEVTYPE}=="partition", ENV{ID_BUS}=="scsi", ATTRS{fw_id}=="0x0003", \
ENV{ID_PART_ENTRY_NUMBER}=="2", SYMLINK+="eri-meta-part"
ACTION="remove", KERNEL=="sd?", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="scsi", \
ATTRS{fw_id}=="0x0003", RUN="/bin/rm -f /dev/diskB*"

HEREDOC
	}

  # Now copy created rule file to destination folder
  copy_udev_rules

}

# ------------------------------------------------------------------------
function copy_udev_rules() {

  # copy TEMP_RULES to source file UDEV_RULES
  if [ -r $TMP_RULES ]; then
    /bin/cp -f $TMP_RULES /etc/udev/rules.d/$UDEV_RULES
    [ $? -ne 0 ] && abort 'copy failed'
    /sbin/udevadm control --reload-rules || abort '"udevadm control" ended with errors'
    /sbin/udevadm trigger --subsystem-match="block" || abort '"udevadm trigger" ended with errors'
    /sbin/udevadm settle --quiet --timeout=120
  else
    abort "file $TMP_RULES not found or not readable"
  fi

  # buffer time to settle for block device
  sleep 10

  # cleanup the source file
  /bin/rm -f $TMP_RULES
}

# _____________________
#|    _ _   _  .  _    |
#|   | ) ) (_| | | )   |
#|_____________________|
# Here begins the "main" function...

# Set the interpreter to exit if a non-initialized variable is used.
set -u

# sanity check to see if things are in place
sanity_check

# generate udev rules for HW_TYPE
udev_rules_$HW_TYPE

exit $TRUE
# End of file
