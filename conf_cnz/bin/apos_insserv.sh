#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_insserv.sh
# Description:
#       A script to interact with the lde configuration management.
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
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	Script rework.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0

function usage() {
	cat << HEREDOC
usage: $0 <filename>

<filename> must contain a header in the following form:

# LDE_deployment:
# 	type:		<start|stop|config>
# 	priority:	<NNN>

Please note that <NNN> must be a three-cypher positive integer greater than 500.
HEREDOC
}

# usage: sanity_checks <filename>
function sanity_checks() {
	FILE=$1
	if [ "$( dirname $FILE )/" != "$BASEDIR" ]; then
		apos_log "file not found, trying $BASEDIR/$FILE..."
		if [ -f $BASEDIR/$FILE ]; then
			FILE=$BASEDIR/$FILE
		else
			apos_abort 'File not found!'
		fi
	fi
}

# usage: read_header 
function read_header() {
	TYPES='config'
	PRIORITIES='999'
	if [ -r "$FILE" ]; then
		TYPES_ROW=$( cat $FILE | grep -E '^# LDE_deployment:$' -A1 | tail -n -1 | sed -e 's@^#[ \t]*@@g' -e 's@:[ \t]*@:@g' )
		if [[ "$TYPES_ROW" =~ ^type: ]]; then
			TYPES=$( echo $TYPES_ROW | sed 's@^type:@@g' )
		fi

		PRIORITIES_ROW=$( cat $FILE | grep -E '^# LDE_deployment:$' -A2 | tail -n -1 | sed -e 's@^#[ \t]*@@g' -e 's@:[ \t]*@:@g' )
		if [[ "$PRIORITIES_ROW" =~ ^priority: ]]; then
			PRIORITIES=$( echo $PRIORITIES_ROW | sed 's@^priority:@@g' )
		fi
	fi
}

# usage: create_link <type> <priority>
function create_link() {
	local T=$1
	local P=$2
	case "$T" in
		start)
			LETTER='S'
		;;
		stop)
			LETTER='K'
		;;
		config)
			LETTER='C'
		;;
		*)
			apos_abort 'unsupported link type'
		;;
	esac
	pushd $BASEDIR >/dev/null 2>&1
	if [ -d $T/ ]; then
		LINK_NAME=$( echo "${LETTER}${P}$(basename ${FILE})" | sed 's@-config$@@g' )
		if [ -f $T/$LINK_NAME ]; then
			apos_log "Link $T/$LINK_NAME already present: skipping."
		else
			ln -s $FILE $T/$LINK_NAME
		fi
	else
		apos_abort "folder $T not found"
	fi
	popd >/dev/null 2>&1
}

# Main

BASEDIR='/usr/lib/lde/config-management/'

if [ $# -lt 1 ]; then
	usage
	apos_abort 'missing parameter'
else
	for F in $*; do
		apos_log "processing the $F file"
		sanity_checks $F
		read_header
		INDEX='0'
		for TYPE in $TYPES; do
			INDEX=$(( $INDEX + 1 ))
			PRIO=$(echo $PRIORITIES | awk '{ print $'${INDEX}' }' )
			create_link $TYPE $PRIO
		done
	done
fi

apos_outro $0
exit $TRUE

# End of file
