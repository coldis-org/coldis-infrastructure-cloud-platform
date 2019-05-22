#!/bin/sh

# Default script behavior.
set -o errexit
#set -o pipefail

# Debug is disabled by default.
DEBUG=false
DEBUG_OPT=

# Default paramentes..
AWS_CONFIG_FILE=aws_basic_config.properties
AWS_IAM_CONFIG_FILE=aws_setup_iam_config.properties

# For each argument.
while :; do
	case ${1} in
		
		# Debug argument.
		--debug)
			DEBUG=true
			DEBUG_OPT="--debug"
			;;

		# AWS config file argument.
		-f|--aws-config-file)
			AWS_CONFIG_FILE="${2}"
			shift
			;;

		# AWS IAM config file argument.
		--aws-iam-config-file)
			AWS_IAM_CONFIG_FILE="${2}"
			shift
			;;

		# Unkown option.
		?*)
			printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
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
${DEBUG} && echo  "Running 'aws_setup'"
${DEBUG} && echo "AWS_CONFIG_FILE=${AWS_CONFIG_FILE}"
${DEBUG} && echo "AWS_IAM_CONFIG_FILE=${AWS_IAM_CONFIG_FILE}"

# Creates AWS IAM groups and users.
aws_iam_create_admin_group_users --aws-config-file ${AWS_CONFIG_FILE} \
		--aws-iam-config-file ${AWS_IAM_CONFIG_FILE} \
		${DEBUG_OPT}
		
# Print script end if on debug mode.
${DEBUG} && echo  "Finishing 'aws_setup'"



