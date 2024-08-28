#!/bin/bash
##
# ------------------------------------------------------------------------
#     Copyright (C) 2021 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_grub_update_users.sh
# Description:
#       A script to replace the lde grub users update script in sync.conf file.
#       
#      Note:We have taken the lde provided script file( i.e /usr/lib/lde/grub_update_users.sh) and adapted the APG changes.
##
##
# Changelog:
# - Thu May 27 2021 - Yeswanth Vankayala (xyesvan)
#       First version.
##

GRUB_CFG=/boot/grub2/grub.cfg
WORKFILE=/boot/grub2/grub.cfg.new
GRUB_SHADOW=/etc/grub_shadow
GLOBAL_GRUB_SHADOW=/cluster/etc/grub_shadow

log() {
	logger -t update_grub_users "$1"
	echo "$1" >&2
}

die() {
	logger -t update_grub_users -p user.err "ERROR: $1"
	echo "ERROR: $1" >&2
	rm -f $WORKFILE
	exit 1
}

cp $GRUB_CFG $WORKFILE || die "Could not copy $GRUB_CFG to $WORKFILE"

# Delete any
sed -i '/^password_pbkdf2[[:space:]]\+boot/d' $WORKFILE ||
        die "sed delete passwords failed on $WORKFILE"

# Reset menu entries to not have "--unrestricted" or "--users <user>"
sed -i "s/^\(menuentry.*'[[:space:]]\+.*\)--unrestricted\(.*{[[:space:]]*\)$/\1\2/" \
        $WORKFILE || die "sed clean unrestricted from menu entries failed"

sed -i "s/^\(menuentry.*'[[:space:]]\+.*\)--users[[:space:]]\+[^[:space:]]*\(.*{[[:space:]]*\)$/\1 \2/" \
        $WORKFILE || die "sed clean menu entry users failed"

if [ -e $GLOBAL_GRUB_SHADOW ]; then
	mm_pass=$(awk /^boot-maint/'{ print $2 }' $GRUB_SHADOW)

	[ "$?" = "0" ] || die "fetch boot-maint password from $GRUB_SHADOW failed"

	adm_pass=$(awk /^boot-admin/'{ print $2 }' $GRUB_SHADOW)

	[ "$?" = "0" ] || die "fetch boot-admin password from $GRUB_SHADOW failed"
else
	mm_pass=""
	adm_pass=""
fi

# Define users and passwords
if [ "$mm_pass" != "" ]; then
	sed -i "1i password_pbkdf2 boot-maint $mm_pass" \
                $WORKFILE || die "Could not add users to $WORKFILE"
fi

if [ "$adm_pass" != "" ]; then
	sed -i "1i password_pbkdf2 boot-admin $adm_pass" $WORKFILE ||
            die "Could not add password for boot-admin in $WORKFILE"
fi

# Update menu entries for maintenance mode
# Changes done for apg is to include if statement if boot-admin user is present
if [ "$mm_pass" != "" ]; then
	replace_with="--users boot-maint"
elif [ "$adm_pass" != "" ]; then 
	replace_with='--users ""'
else
	replace_with="--unrestricted"
fi

sed -i "s/^\(menuentry.*Maintenance.*'\)[[:space:]\+{[[:space:]]\+$/\1 $replace_with {/" \
        $WORKFILE || "Unable to update menu entry for maintenance mode"

# Update menu entries for Operational mode
sed -i "s/^\(menuentry.*Operational.*'\)[[:space:]\+{[[:space:]]\+$/\1 --unrestricted {/" \
        $WORKFILE || "Unable to update menu entry for Operational mode"

mv "$WORKFILE" "$GRUB_CFG" || die "Could not move $WORKFILE to $GRUB_CFG"
log "Successfully update grub.cfg with users and passwords"
exit 0
