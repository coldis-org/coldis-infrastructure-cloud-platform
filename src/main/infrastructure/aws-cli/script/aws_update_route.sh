#!/bin/sh

# Default script behavior.
set -o errexit
#set -o pipefail

# Debug is disabled by default.
DEBUG=false
DEBUG_OPT=

# Default paramentes.
AWS_CONFIG_FILE=aws_basic_config.properties
AWS_RECORD_SET_VALUE=$(dig @resolver1.opendns.com ANY myip.opendns.com +short -4)
echo ${AWS_RECORD_SET_VALUE}

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

		# AWS hosted zone.
		-z|--hosted-zone)
			AWS_HOSTED_ZONE="${2}"
			shift
			;;

		# AWS record set type.
		-t|--record-set-type)
			AWS_RECORD_SET_TYPE="${2}"
			shift
			;;

		# AWS record set entry.
		-e|--record-set-entry)
			AWS_RECORD_SET_ENTRY="${2}"
			shift
			;;

		# AWS record set value.
		-v|--record-set-value)
			AWS_RECORD_SET_VALUE="${2}"
			shift
			;;

		# Unkown option.
		?*)
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
${DEBUG} && echo  "Running 'aws_update_route'"
${DEBUG} && echo  "AWS_HOSTED_ZONE=${AWS_HOSTED_ZONE}"
${DEBUG} && echo  "AWS_RECORD_SET_TYPE=${AWS_RECORD_SET_TYPE}"
${DEBUG} && echo  "AWS_RECORD_SET_ENTRY=${AWS_RECORD_SET_ENTRY}"
${DEBUG} && echo  "AWS_RECORD_SET_VALUE=${AWS_RECORD_SET_VALUE}"

# Puts the AWS config information in the the context variables.
if [ -f ${AWS_CONFIG_FILE} ]
then 
	set -a
	. ${AWS_CONFIG_FILE}
	set +a
	${DEBUG} && cat ${AWS_CONFIG_FILE}
fi

# Creates the temp route file.
echo "{
	\"Comment\":\"Updating entry\",
	\"Changes\":[{
		\"Action\":\"UPSERT\",
		\"ResourceRecordSet\":{
			\"Name\":\"${AWS_RECORD_SET_ENTRY}\",
			\"Type\":\"${AWS_RECORD_SET_TYPE}\",
			\"TTL\":30, 
			\"ResourceRecords\":[{
				\"Value\":\"${AWS_RECORD_SET_VALUE}\"
			}]
		}
	}]
}" > update_route.json
${DEBUG} && cat update_route.json

aws route53 change-resource-record-sets --hosted-zone-id ${AWS_HOSTED_ZONE} --change-batch file://update_route.json

