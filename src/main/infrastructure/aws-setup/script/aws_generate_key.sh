#!/bin/sh

# Default script behavior.
set -o errexit
#set -o pipefail

# Debug is disabled by default.
DEBUG=false
DEBUG_OPT=

# For each argument.
while :; do
	case ${1} in
		
		# Debug argument.
		--debug)
			DEBUG=true
			DEBUG_OPT="--debug"
			;;

		# Output key file argument.
		-f|--key-file)
			OUTPUT_KEY_FILE=${2}
			shift
			;;

		# Unkown option.
		-?*)
			printf 'WARN: Unknown option (ignored): %s\n' "${1}" >&2
			;;

		# No more options.
		*)
			break

	esac 
	shift
done

# Using unavaialble variables should fail the script.
set -o nounset

# Enables interruption signal handling.
trap - INT TERM

# Print arguments if on debug mode.
${DEBUG} && echo  "Running 'aws_iamgenerate_key'"
${DEBUG} && echo  "OUTPUT_KEY_FILE=${OUTPUT_KEY_FILE}"

ssh-keygen -t rsa -N "" -f ${OUTPUT_KEY_FILE}




