#!/bin/bash -u
##
# ------------------------------------------------------------------------
#     Copyright (C) 2012 Ericsson AB. All rights reserved.
# ------------------------------------------------------------------------
##
# Name:
#       apos_deploy.sh
# Description:
#       A script to deploy content from a file to another file.
# Note:
#	None.
##
# Usage:
#       deploy.sh --from|-f <source_file>
#                 --to|-t <destination_file>
#                 [--append|-a] [--inject|-i]
##
# Output:
#       None.
##
# Changelog:
# - Thu Apr 28 2016 - Francesco Rainone (EFRARAI)
#   Impact in lockfile invocation for avoiding the creation of lockfile in
#   backed-up directory.
# - Fri Nov 23 2012 - Paolo Palmieri (epaopal)
#	  Added option to manage exclusive lock when destination is a file under /cluster.
# - Tue Jan 31 2012 - Paolo Palmieri (epaopal)
#	  Script rework.
# - Tue Jan 10 2012 - Francesco Rainone (efrarai)
#	Minor changes to use the apos_common.sh library.
# - Wed Nov 16 2011 - Francesco Rainone (efrarai)
#   First version.
##

# Load the apos common functions.
. /opt/ap/apos/conf/apos_common.sh

apos_intro $0
apos_log "parameters: $*"

function usage() {
        echo 'deploy.sh --from|-f <source_file>'
        echo '          --to|-t <destination_file>'
        echo '          [--append|-a] [-i|--inject]'
        echo
}

function sanity_check() {
        if [ ! -r "$OPT_FROM_ARG" ]; then
                apos_abort "file $OPT_FROM_ARG not found or not readable"
        fi
	
	if [ ! -f "$OPT_TO_ARG" ]; then
		if [[ $OPT_APPEND -ne $FALSE || $OPT_INJECT -ne $FALSE ]]; then
			apos_abort "file $OPT_TO_ARG not found"
		fi
	elif [ ! -w "$OPT_TO_ARG" ]; then
                apos_abort "file $OPT_TO_ARG not writable"
        fi
}

function do_deploy() {
	local fl_fold="$(apos_create_brf_folder clear)"
	local fl_file=".aposdeploy.exclusivelock"
  local RET_CODE=''

	# check for directory presence
	if [ $OPT_EXLO -eq $TRUE ]; then
    if [[ -z "${fl_fold}" || ! -d "${fl_fold}" ]]; then
      apos_abort "directory \"${fl_fold}\" not found"
    fi
  fi
	# lock
	[ $OPT_EXLO -eq $TRUE ] && lockfile -1 ${fl_fold}/${fl_file}
	# do stuff
  if [ $OPT_APPEND -eq $TRUE ]; then
    cat $OPT_FROM_ARG >> $OPT_TO_ARG
    RET_CODE=$?
	elif [ $OPT_INJECT -eq $TRUE ]; then
		cat $OPT_FROM_ARG > $OPT_TO_ARG
    RET_CODE=$?
  else
		MODE=$(stat --format=%a $OPT_FROM_ARG)
    install -m ${MODE} $OPT_FROM_ARG $OPT_TO_ARG
    RET_CODE=$?
	fi
	# unlock
	if [ $OPT_EXLO -eq $TRUE ]; then
    rm -f ${fl_fold}/${fl_file} || apos_abort "failure while trying to delete \"${fl_fold}/${fl_file}\""
  fi
  if [ $RET_CODE -ne $TRUE ]; then
    apos_abort 'deploy operation ended abnormally'
  fi
}

# The function reads the command line argument list and parses it flagging the
#  right variables in a case/esac switch.
#  Input: the function must be invoked with the $@ parameter:
#   parse_cmdline $@
#  Required: please make attention to handle the cases in the right way.
#
function parse_cmdline() {
        # OPTIONS is a list of single-character options.
        #  The string must be in the form:
        #   Example: 'ovl' (for -o -v -l options).
        #  Options that takes an argument must be followed by a colon:
        #   Example: 'ov:l' (-v takes a mandatory argument).
        #  Options with an optional argument must be followed by a double colon:
        #   Example: 'ovl::' (-l takes an optional argument).
        local OPTIONS='f: t: a i e'

        # LONG_OPTIONS is a list of space-separated multi-character options.
        #  The string must be in the form:
        #   Example: 'option1 option2 ... optionN'.
        #  Options that takes an argument must be followed by a colon:
        #   Example: 'option1: option2 ... optionN:'
        #  Options with an optional argument must be followed by a double colon:
        #   Example: 'option1:: option2:: ... optionN'
        local LONG_OPTIONS='from: to: append inject exlo'

        ARGS=`getopt --longoptions "$LONG_OPTIONS" --options "$OPTIONS" -- "$@"`
        RETURN_CODE=$?
        if [ $RETURN_CODE -ne 0 ]; then
                usage
                apos_abort "wrong parameters"
        fi

        eval set -- "$ARGS"

        # Make sure to handle the cases for all the options listed in OPTIONS
        #  and LONG_OPTIONS and to fill up the right script-wide variables.
        while [ $# -gt 0 ]; do
                case "$1" in
                        -f|--from)
                                OPT_FROM=$TRUE
                                OPT_FROM_ARG=$2
                                shift
                        ;;
                        -t|--to)
                                OPT_TO=$TRUE
                                OPT_TO_ARG=$2
                                shift
                        ;;
                        -a|--append)
                                OPT_APPEND=$TRUE
                        ;;
                        -i|--inject)
                                OPT_INJECT=$TRUE
                        ;;
			-e|--exlo)
                                OPT_EXLO=$TRUE
			;;
                        --)
                                # echo "end of argument list"
                                shift
                                break
                        ;;
                        *)
                                apos_abort "Unrecognized option ($1)"
                        ;;
                esac
                shift
        done
}

function options_check() {
        if [[ $OPT_FROM -ne $TRUE || $OPT_TO -ne $TRUE ]]; then
                usage
                apos_abort "missing --from and/or --to option"
        fi


        if [[ $OPT_FROM -eq $TRUE && -z "$OPT_FROM_ARG" ]]; then
                usage
                apos_abort "missing mandatory parameter"
        fi

        if [[ $OPT_TO -eq $TRUE && -z "$OPT_TO_ARG" ]]; then
                usage
                apos_abort "missing mandatory parameter"
        fi

        if [[ $OPT_APPEND -eq $TRUE && $OPT_INJECT -eq $STRUE ]]; then
                usage
                apos_abort "uncompatible options specified"
        fi
}

# Main

# Option variables
OPT_FROM=$FALSE
OPT_FROM_ARG=""
OPT_TO=$FALSE
OPT_TO_ARG=""
OPT_APPEND=$FALSE
OPT_INJECT=$FALSE
OPT_EXLO=$FALSE

parse_cmdline $@
options_check
sanity_check
do_deploy

apos_outro $0
exit $TRUE

# End of file
