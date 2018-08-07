#!/usr/bin/env bash

#
# # Hegemon
# hegemon.sh
#
# Setup a macOS development environment with Ansible.
#
# Created by Chris White on 7/23/2018
# License: MIT License / https://opensource.org/licenses/MIT
#
# # Usage
#
# TODO: Improve Usage for Local or GitHub
# TODO: Add Ansible options
# $ ./hegemon.sh -f /tmp/x
#
# For debug run
# $ ./hegemon.sh -f /tmp/x -d
#
# # Credits
# ## BASH3 Boilerplate
# Based on a template by BASH3 Boilerplate v2.3.0 but not without some changes, particularly to style.
# http://bash3boilerplate.sh/#authors
# The MIT License (MIT)
# Copyright (c) 2013 Kevin van Zonneveld and contributors
#
# ## Superlumic
# Hegemon is heavily influenced by Roderik van der Veer's Superlumic but handles the Ansible tasks in a different way, some of this code is forked from his project.
# https://github.com/superlumic/superlumic
#



# # Print Header

header () {
	if [[ "${NO_COLOR:-}" != true ]]; then	printf "\\x1b[38;5;202m\\n"; fi
	printf "ooooo   ooooo                                                                        \\n"
	printf "'888'   '888'                                                                        \\n"
	printf " 888     888   .ooooo.   .oooooooo  .ooooo.  .ooo. .oo.  .oo.   .oooooo.  ooo. .oo.  \\n"
	printf " 888ooooo888  d88' '88b 888' '88b  d88' '88b '888P'Y88bP'Y88b  d88' '88b '888P'Y88b  \\n"
	printf " 888     888  888ooo888 888   888  888ooo888  888   888   888  888   888  888   888  \\n"
	printf " 888     888  888    .o '88bod8P'  888    .o  888   888   888  888   888  888   888  \\n"
	printf "o888o   o888o 'Y8bod8P' '8oooooo.  'Y8bod8P' o888o o888o o888o 'Y8bod8P' o888o o888o \\n"
	printf "                        d'     YD                                                    \\n"
	printf "                        'Y88888P'                                                    \\n"
	printf "\\x1b[0m\\n"
}




# # Set Script Run Options

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace



# # Set Script Variables

# Determine if this script is run directly
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
	__i_am_main_script="0" # false

	if [[ "${__usage+x}" ]]; then
			if [[ "${BASH_SOURCE[1]}" = "${0}" ]]; then
			__i_am_main_script="1" # true
		fi

		__b3bp_external_usage="true"
		__b3bp_tmp_source_idx=1
	fi
else
	__i_am_main_script="1" # true
	[[ "${__usage+x}" ]] && unset -v __usage
	[[ "${__helptext+x}" ]] && unset -v __helptext
fi

# Set magic variables for current file, directory, os, etc.
__dir="$(cd "$(dirname "${BASH_SOURCE[${__b3bp_tmp_source_idx:-0}]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[${__b3bp_tmp_source_idx:-0}]}")"
__base="$(basename "${__file}" .sh)"

# Define the environment variables (and their defaults) that this script depends on
LOG_LEVEL="${LOG_LEVEL:-6}" # 7 = debug -> 0 = emergency only
NO_COLOR="${NO_COLOR:-}"    # true = disable color. otherwise autodetected



# # Functions

# TODO: Decide on exact docblock syntax and unify.

# ## Printing & Logging

# ### __b3bp_log() BASH3 Boilerplate Log
#
# Log and print different kinds of information from general info to critical errors.
#
# - `$1`:      string    required  The log-level for the string being logged and printed. Values can be `debug`, `info`, `notice`, `warning`, `error`, `critical`, `alert` or `emergency`.
# - `$@`:      string    required  The full string to be logged and printed.
# - `exit`:    code 0    implicit  Always exits succesfully.
#
__b3bp_log () {
	local log_level="${1}"
	shift

	# Set log colors
	# shellcheck disable=SC2034
	local color_debug='\x1b[35m'
	# shellcheck disable=SC2034
	local color_info='\x1b[32m'
	# shellcheck disable=SC2034
	local color_notice='\x1b[34m'
	# shellcheck disable=SC2034
	local color_warning='\x1b[33m'
	# shellcheck disable=SC2034
	local color_error='\x1b[31m'
	# shellcheck disable=SC2034
	local color_critical='\x1b[1;31m'
	# shellcheck disable=SC2034
	local color_alert='\x1b[1;33;41m'
	# shellcheck disable=SC2034
	local color_emergency='\x1b[1;4;5;33;41m'

	# Set correct color for level
	local colorvar="color_${log_level}"
	local color="${!colorvar:-${color_error}}"

	local color_reset='\x1b[0m'

	# Don't use color in some instances
	if [[ "${NO_COLOR:-}" = "true" ]] || { [[ "${TERM:-}" != "xterm"* ]] && [[ "${TERM:-}" != "screen"* ]] ; } || [[ ! -t 2 ]]; then
		if [[ "${NO_COLOR:-}" != "false" ]]; then
			# Don't use colors on pipes or non-recognized terminals
			color=""; color_reset=""
		fi
	fi

	# All remaining arguments are to be printed
	local log_line=""

	while IFS=$'\n' read -r log_line; do
		echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") ${color}$(printf "[%9s]" "${log_level}")${color_reset} ${log_line}" 1>&2
	done <<< "${@:-}"
}


# ## Log Functions

# emergency(), alert(), critical(), error(), warning(), notice(), info(), debug()
#
# Executes __b3bp_log to log and print information or problems of different types and severities depending on the specified `$LOG_LEVEL` defined at execution (or defaulting to 6).
#
# - `$1`:    string  required  String to to log and print.
# - `exit`:  code 1  explicit  emergency() always exits unsuccessfully.
# - `true`:  code 0  explicit  All others exit successfully.
#
emergency () {                                  __b3bp_log emergency "${@}"; exit 1; }
alert ()     { [[ "${LOG_LEVEL:-0}" -ge 1 ]] && __b3bp_log alert "${@}"; true; }
critical ()  { [[ "${LOG_LEVEL:-0}" -ge 2 ]] && __b3bp_log critical "${@}"; true; }
error ()     { [[ "${LOG_LEVEL:-0}" -ge 3 ]] && __b3bp_log error "${@}"; true; }
warning ()   { [[ "${LOG_LEVEL:-0}" -ge 4 ]] && __b3bp_log warning "${@}"; true; }
notice ()    { [[ "${LOG_LEVEL:-0}" -ge 5 ]] && __b3bp_log notice "${@}"; true; }
info ()      { [[ "${LOG_LEVEL:-0}" -ge 6 ]] && __b3bp_log info "${@}"; true; }
debug ()     { [[ "${LOG_LEVEL:-0}" -ge 7 ]] && __b3bp_log debug "${@}"; true; }


# ## help() Generate Help Text
#
# Generates and echoes description and syntax information when script is run with `-h` or `--help` options.
#
# - `$1`:    string            Title text to print at top.
# - `exit`:  code 1  explicit  Always exits unsuccessfully.
#
help () {
	echo "" 1>&2
	echo "${*}" 1>&2
	echo "" 1>&2
	# Options and descriptions
	echo "${__usage:-No usage available}" 1>&2
	echo "" 1>&2

	# Help text
	if [[ "${__helptext:-}" ]]; then
		echo "${__helptext}" 1>&2
		echo "" 1>&2
	fi

	exit 1
}



# ## __validate_local ()
#
# Validates that the configuration file exists and is readable.
#
# - `exit`:  code `0`  implicit  Validation successful.
# - `exit`:  code `1`  implicit  Validation unsuccessful.
#
__validate_local () {
	if [[ "${__local:-}" ]] && info "Validating configuration file is accessible"; then
		if ! test -r "${__local}"; then
			[[ "${LOG_LEVEL:-}" ]] || emergency "Unable to read file from ${__local}"
		fi
	fi
}


# ## __validate_repo ()
#
# Validates that the repo URL can be cloned.
#
# - `exit`:  code `0`  implicit  Validation successful.
# - `exit`:  code `1`  implicit  Validation unsuccessful.
#
__validate_repo () {
	if [[ "${__repo:-}" ]] && info "Validating repository"; then
		if ! git ls-remote --tags "${__repo}" refs/heads/master; then
			[[ "${LOG_LEVEL:-}" ]] || emergency "Unable to read repository from ${__repo}"
		fi
	fi
}



# # Parse Commandline Options
#
# Commandline options. This defines the usage page, and is used to parse cli opts & defaults from. The parsing is unforgiving so be precise in your syntax.
#
# - A short option must be preset for every long option; but every short option need not have a long option.
# - `--` is respected as the separator between options and arguments.
# - We do not bash-expand defaults, so setting '~/app' as a default will not resolve to ${HOME}. You can use bash variables to work around this (so use ${HOME} instead).
#

# ## Usage & Help Text

# shellcheck disable=SC2015
[[ "${__usage+x}" ]] || read -r -d '' __usage <<-'EOF' || true # exits non-zero when EOF encountered
	-f --file   [arg] Filename for Ansible configuration. Optional.
	-r --repo   [arg] URL an Ansible configuration Git repo to be cloned locally.
	-v                Enable verbose mode, print script as it is executed
	-d --debug        Enables debug mode and prints a great deal of information when run.
	-h --help         This page
	-n --no-color     Disable color output
EOF

# TODO: Write a proper description
# shellcheck disable=SC2015
[[ "${__helptext+x}" ]] || read -r -d '' __helptext <<-'EOF' || true # exits non-zero when EOF encountered
Hegemon uses Ansible to setup and maintain a macOS development environment with a specified configuration. You must pass either a configuration file (-f) or the URL (-r) to an configuration in a Git repo that will be cloned and executed locally.
EOF



# ## Parse Input Loop

# Translate usage string -> getopts arguments, and set $arg_<flag> defaults
while read -r __b3bp_tmp_line; do
	if [[ "${__b3bp_tmp_line}" =~ ^- ]]; then
		# Fetch single character version of option string
		__b3bp_tmp_opt="${__b3bp_tmp_line%% *}"
		__b3bp_tmp_opt="${__b3bp_tmp_opt:1}"

		# Fetch long version if present
		__b3bp_tmp_long_opt=""

		if [[ "${__b3bp_tmp_line}" = *"--"* ]]; then
			__b3bp_tmp_long_opt="${__b3bp_tmp_line#*--}"
			__b3bp_tmp_long_opt="${__b3bp_tmp_long_opt%% *}"
		fi

		# Map opt long name to+from opt short name
		printf -v "__b3bp_tmp_opt_long2short_${__b3bp_tmp_long_opt//-/_}" '%s' "${__b3bp_tmp_opt}"
		printf -v "__b3bp_tmp_opt_short2long_${__b3bp_tmp_opt}" '%s' "${__b3bp_tmp_long_opt//-/_}"

		# Check if option takes an argument
		if [[ "${__b3bp_tmp_line}" =~ \[.*\] ]]; then
			__b3bp_tmp_opt="${__b3bp_tmp_opt}:" # add : if opt has arg
			__b3bp_tmp_init=""  # it has an arg. init with ""
			printf -v "__b3bp_tmp_has_arg_${__b3bp_tmp_opt:0:1}" '%s' "1"
		elif [[ "${__b3bp_tmp_line}" =~ \{.*\} ]]; then
			__b3bp_tmp_opt="${__b3bp_tmp_opt}:" # add : if opt has arg
			__b3bp_tmp_init=""  # it has an arg. init with ""
			# remember that this option requires an argument
			printf -v "__b3bp_tmp_has_arg_${__b3bp_tmp_opt:0:1}" '%s' "2"
		else
			__b3bp_tmp_init="0" # it's a flag. init with 0
			printf -v "__b3bp_tmp_has_arg_${__b3bp_tmp_opt:0:1}" '%s' "0"
		fi
		__b3bp_tmp_opts="${__b3bp_tmp_opts:-}${__b3bp_tmp_opt}"
	fi

	[[ "${__b3bp_tmp_opt:-}" ]] || continue

	if [[ "${__b3bp_tmp_line}" =~ (^|\.\ *)Default= ]]; then
		# Ignore default value if option does not have an argument
		__b3bp_tmp_varname="__b3bp_tmp_has_arg_${__b3bp_tmp_opt:0:1}"

		if [[ "${!__b3bp_tmp_varname}" != "0" ]]; then
			__b3bp_tmp_init="${__b3bp_tmp_line##*Default=}"
			__b3bp_tmp_re='^"(.*)"$'
			if [[ "${__b3bp_tmp_init}" =~ ${__b3bp_tmp_re} ]]; then
				__b3bp_tmp_init="${BASH_REMATCH[1]}"
			else
				__b3bp_tmp_re="^'(.*)'$"
				if [[ "${__b3bp_tmp_init}" =~ ${__b3bp_tmp_re} ]]; then
					__b3bp_tmp_init="${BASH_REMATCH[1]}"
				fi
			fi
		fi
	fi

	if [[ "${__b3bp_tmp_line}" =~ (^|\.\ *)Required\. ]]; then
		# Remember that this option requires an argument
		printf -v "__b3bp_tmp_has_arg_${__b3bp_tmp_opt:0:1}" '%s' "2"
	fi

	printf -v "arg_${__b3bp_tmp_opt:0:1}" '%s' "${__b3bp_tmp_init}"
done <<< "${__usage:-}"

# Run getopts only if options were specified in __usage
if [[ "${__b3bp_tmp_opts:-}" ]]; then
	# Allow long options like --this
	__b3bp_tmp_opts="${__b3bp_tmp_opts}-:"

	# Reset in case getopts has been used previously in the shell.
	OPTIND=1

	# Start parsing command line
	set +o nounset # Unexpected arguments will cause unbound variables to be dereferenced
	# Overwrite $arg_<flag> defaults with the actual CLI options
	while getopts "${__b3bp_tmp_opts}" __b3bp_tmp_opt; do
		[[ "${__b3bp_tmp_opt}" = "?" ]] && help "Invalid use of script: ${*} "

		if [[ "${__b3bp_tmp_opt}" = "-" ]]; then
			# OPTARG is long-option-name or long-option=value
			if [[ "${OPTARG}" =~ .*=.* ]]; then
				# --key=value format
				__b3bp_tmp_long_opt=${OPTARG/=*/}
				# Set opt to the short option corresponding to the long option
				__b3bp_tmp_varname="__b3bp_tmp_opt_long2short_${__b3bp_tmp_long_opt//-/_}"
				printf -v "__b3bp_tmp_opt" '%s' "${!__b3bp_tmp_varname}"
				OPTARG=${OPTARG#*=}
			else
				# --key value format
				# Map long name to short version of option
				__b3bp_tmp_varname="__b3bp_tmp_opt_long2short_${OPTARG//-/_}"
				printf -v "__b3bp_tmp_opt" '%s' "${!__b3bp_tmp_varname}"
				# Only assign OPTARG if option takes an argument
				__b3bp_tmp_varname="__b3bp_tmp_has_arg_${__b3bp_tmp_opt}"
				printf -v "OPTARG" '%s' "${@:OPTIND:${!__b3bp_tmp_varname}}"
				# Shift over the argument if argument is expected
				# shellcheck disable=SC2030
				( (OPTIND+=__b3bp_tmp_has_arg_${__b3bp_tmp_opt}) )
			fi
			# We have set opt/OPTARG to the short value and the argument as OPTARG if it exists
		fi
		__b3bp_tmp_varname="arg_${__b3bp_tmp_opt:0:1}"
		__b3bp_tmp_default="${!__b3bp_tmp_varname}"

		__b3bp_tmp_value="${OPTARG}"
		if [[ -z "${OPTARG}" ]] && [[ "${__b3bp_tmp_default}" = "0" ]]; then
			__b3bp_tmp_value="1"
		fi

		printf -v "${__b3bp_tmp_varname}" '%s' "${__b3bp_tmp_value}"
		debug "cli arg ${__b3bp_tmp_varname} = (${__b3bp_tmp_default}) -> ${!__b3bp_tmp_varname}"
	done
	set -o nounset # No more unbound variable references expected

	# shellcheck disable=SC2031
	shift $((OPTIND-1))

	if [[ "${1:-}" = "--" ]] ; then
		shift
	fi
fi



# ## Automatic Validation of Required Option Arguments

for __b3bp_tmp_varname in ${!__b3bp_tmp_has_arg_*}; do
	# validate only options which required an argument
	[[ "${!__b3bp_tmp_varname}" = "2" ]] || continue

	__b3bp_tmp_opt_short="${__b3bp_tmp_varname##*_}"
	__b3bp_tmp_varname="arg_${__b3bp_tmp_opt_short}"
	[[ "${!__b3bp_tmp_varname}" ]] && continue

	__b3bp_tmp_varname="__b3bp_tmp_opt_short2long_${__b3bp_tmp_opt_short}"
	printf -v "__b3bp_tmp_opt_long" '%s' "${!__b3bp_tmp_varname}"
	[[ "${__b3bp_tmp_opt_long:-}" ]] && __b3bp_tmp_opt_long=" (--${__b3bp_tmp_opt_long//_/-})"

	help "Option -${__b3bp_tmp_opt_short}${__b3bp_tmp_opt_long:-} requires an argument"
done



# ## Clean Environment Variables

for __tmp_varname in ${!__b3bp_tmp_*}; do
	unset -v "${__tmp_varname}"
done

unset -v __tmp_varname


### Externally Supplied __usage
#
# Nothing else to do here.

if [[ "${__b3bp_external_usage:-}" = "true" ]]; then
	unset -v __b3bp_external_usage
	return
fi



# ## Signal Trapping and Backtracing

# ### __b3bp_cleanup_before_exit ()
#
# Print cleaning up info message.
#
# - `exit`:  code 0  implicit  Always exits successfully
#
__b3bp_cleanup_before_exit () {
	info "Cleaning up environment variables. Done"
}
trap __b3bp_cleanup_before_exit EXIT


# ### __b3bp_err_report ()
#
# Print error code and exit.
#
# - `$1`:    string   Function name for error.
# - `$2`:    int      Line number for error.
# - `exit`:  code !0  Always exits unsuccessfully with error code from previous command.
#
# requires `set -o errtrace`
#
__b3bp_err_report () {
		local error_code
		error_code=${?}
		error "Error in ${__file} in function ${1} on line ${2}"
		exit ${error_code}
}



# ## Command-Line Argument Switches
#
# - `-d`  debug mode     Enables xtrace, sets log level to maxium, traps error reports.
# - `-v`  verbose mode   Enabled verbose mode.
# - `-n`  no color mode  Disables color in terminal output.
# - `-h`  help mode      Prints usage and help, exits with code 1.

# debug mode
if [[ "${arg_d:?}" = "1" ]]; then
	set -o xtrace
	LOG_LEVEL="7"
	# Enable error backtracing
	trap '__b3bp_err_report "${FUNCNAME:-.}" ${LINENO}' ERR
fi

# verbose mode
if [[ "${arg_v:?}" = "1" ]]; then
	set -o verbose
fi

# no color mode
if [[ "${arg_n:?}" = "1" ]]; then
	NO_COLOR="true"
fi

# help mode
if [[ "${arg_h:?}" = "1" ]]; then
	# Help exists with code 1
	help "Help using ${0}"
fi



# ## Command Validation
#
# Error out if the things required for your script are not present
#

# File or repo is required
[[ "${arg_f:-}" || "${arg_r:-}" ]] || help      "Setting a filename with -f or --file is required"

# Log level is required but you should never see this as log level is set automatically if not specified.
[[ "${LOG_LEVEL:-}" ]] || emergency "Cannot continue without LOG_LEVEL. "



# ## Set Variables from Arguments
[[ "${arg_f:-}" ]] && __local=${arg_f}
[[ "${arg_r:-}" ]] && __repo=${arg_r}



# ## Runtime

# ### Print General Information
header

[[ "${__repo:-}" ]] && info "Configuration from remote repository:" && info "${__repo}"
[[ "${__local:-}" ]] && info "Configuration from local file:" && info "${__file}"

debug "__i_am_main_script: ${__i_am_main_script}"
debug "__file: ${__file}"
debug "__dir: ${__dir}"
debug "__base: ${__base}"
debug "OSTYPE: ${OSTYPE}"

debug "Argument --file:  ${arg_f}"
debug "Argument --repo:  ${arg_r}"
debug "Argument --debug: ${arg_d}"
debug "Argument --help:  ${arg_h}"
debug "Argument -v:      ${arg_v}"


# ### Validate configuration

if [[ "${__repo:-}" ]]; then
	__validate_repo
elif [[ "${__local:-}" ]]; then
	__validate_local
fi
