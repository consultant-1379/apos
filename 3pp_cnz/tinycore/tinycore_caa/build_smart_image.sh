#!/bin/bash 
##
# ------------------------------------------------------------------------
# Copyright (C) 2015 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##

# rerun myself in fakeroot environment
if [ $EUID -ne 0 ]
then
  PATH=${PATH}:/app/fakeroot/1.9.3/LMWP3/bin fakeroot "$0" "$@"
  exit
fi

SCRIPT_NAME=${0##*/}

BUILD_DIR=$(mktemp -d -t "$SCRIPT_NAME".XXXXXX)

function cleanup () {
  cd
  rm -rf "$BUILD_DIR"
}

function abort () {
  echo "ERROR: $*"
  exit 1
}

#                                              __    __   _______   _   __    _
#                                             |  \  /  | |  ___  | | | |  \  | |
#                                             |   \/   | | |___| | | | |   \ | |
#                                             | |\  /| | |  ___  | | | | |\ \| |
#                                             | | \/ | | | |   | | | | | | \   |
#                                             |_|    |_| |_|   |_| |_| |_|  \__|
trap cleanup EXIT

if [ $# -ne 2 ]; then
  abort "Usage: $SCRIPT_NAME <CXC_DIR> <CAA_DIR>"
fi

TINYCORE_CXC_DIR=$(readlink -f "$1")
TINYCORE_CAA_DIR=$(readlink -f "$2")
FILES_TO_DEPLOY="$TINYCORE_CAA_DIR/scripts/.profile;etc/skel
  $TINYCORE_CAA_DIR/scripts/apz_cloud_init.sh;usr/local/tce.installed/
  $TINYCORE_CAA_DIR/scripts/apz_cloud_common.sh;usr/local/tce.installed/
  $TINYCORE_CAA_DIR/scripts/apz_cloud_get_parameter_openstack.sh;usr/local/tce.installed/
  $TINYCORE_CAA_DIR/scripts/apz_cloud_get_parameter_vmware.sh;usr/local/tce.installed/
  $TINYCORE_CAA_DIR/tcz/bash.tcz;usr/local/tce.installed/
  $TINYCORE_CAA_DIR/tcz/ncursesw.tcz;usr/local/tce.installed/
  $TINYCORE_CAA_DIR/tcz/readline.tcz;usr/local/tce.installed/
  $TINYCORE_CXC_DIR/bin/sinetcc;usr/local/tce.installed/"

echo "Smart Image build start"

echo "Unpacking core.gz..."

mkdir "$BUILD_DIR"
chmod 775 "$BUILD_DIR" 
cd "$BUILD_DIR" || abort "cannot cd $BUILD_DIR"

zcat "$TINYCORE_CAA_DIR"/core/core.gz | cpio -i -d ||
  abort "Failed to extract $TINYCORE_CAA_DIR/core/core.gz to $BUILD_DIR"

echo "Adding extensions..."

for ITEM in $FILES_TO_DEPLOY; do
  FROM=${ITEM%;*}
  FROMFILE=${FROM##*/}
  TO=${ITEM#*;}
  TODIR=${TO%/*}
  if [ -z "$TODIR" ]; then
    echo "ignored bad item '$ITEM'"
    continue
  fi
  if [ ! -d "$TODIR" ]; then
    mkdir -p "$TODIR"
  fi
  if [ "${TO%/}" = "$TODIR" ]; then
    TO=$TODIR/$FROMFILE
  fi
  cp -vf "$FROM" ./"$TO" ||
    abort "Failed to deploy '$FROM' to '$TO'"
done

mycopy=/tmp/core.gz
echo "Packing to $mycopy..."

find . | cpio -o -H newc | gzip -2 > "$mycopy" ||
  abort "Failed to pack $BUILD_DIR to $mycopy"

#sudo -u $SUDO_USER cp $mycopy $TINYCORE_CXC_DIR/bin/smart_image/default/ ||
cp "$mycopy" "$TINYCORE_CXC_DIR"/bin/smart_image/default/ ||
  abort "Failed to copy core.gz - leaving $mycopy"
rm $mycopy

echo "Smart Image build end"

# End of file
