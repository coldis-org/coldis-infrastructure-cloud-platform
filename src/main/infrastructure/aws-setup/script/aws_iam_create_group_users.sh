#!/bin/sh

# Default script behavior.
set -o errexit
#set -o pipefail

# Debug is disabled by default.
DEBUG=false
DEBUG_OPT=

# Default paramentes.
AWS_CONFIG_FILE=aws_basic_config.properties
AWS_IAM_GROUP_USERS_PASSWORD=
AWS_IAM_USER_ACCESS_KEY_FILENAME=

# For each argument.
while :; do
	case ${1} in

		# Debug argument.
		--debug)
			DEBUG=true
			DEBUG_OPT="--debug"
			;;

		# Work folder.
		-w|--aws-work-folder)
			readonly AWS_WORK_FOLDER="${2}"
			shift
			;;
		
		# Group path.
		--aws-iam-group-path)
			readonly AWS_IAM_GROUP_PATH="${2}"
			shift
			;;
		
		# Group name.
		--aws-iam-group-name)
			readonly AWS_IAM_GROUP_NAME="${2}"
			shift
			;;
		
		# Group policies.
		--aws-iam-group-policies)
			readonly AWS_IAM_GROUP_POLICIES="${2}"
			shift
			;;
		
		# Group users path.
		--aws-iam-group-users-path)
			readonly AWS_IAM_GROUP_USERS_PATH="${2}"
			shift
			;;
		
		# Group users names.
		--aws-iam-group-users-names)
			readonly AWS_IAM_GROUP_USERS_NAMES="${2}"
			shift
			;;
		
		# Group users password.
		--aws-iam-group-users-password)
			readonly AWS_IAM_GROUP_USERS_PASSWORD="${2}"
			shift
			;;
		
		# Access key file name. In this case, no profile is created.
		--aws-iam-user-access-key-filename)
			readonly AWS_IAM_USER_ACCESS_KEY_FILENAME="${2}"
			shift
			;;
		
		# AWS config file argument.
		-f|--aws-config-file)
			AWS_CONFIG_FILE="${2}"
			shift
			;;

		# Unkown option.
		-?*)
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

# Puts the AWS config information in the the context variables.
if [ -f ${AWS_CONFIG_FILE} ]
then 
	set -a
	. ${AWS_CONFIG_FILE}
	set +a
	${DEBUG} && cat ${AWS_CONFIG_FILE}
fi

# Print arguments if on debug mode.
${DEBUG} && echo  "Running 'aws_iam_create_group_users'"
${DEBUG} && echo "AWS_CONFIG_FILE=${AWS_CONFIG_FILE}"
${DEBUG} && echo "AWS_IAM_GROUP_PATH=${AWS_IAM_GROUP_PATH}"
${DEBUG} && echo "AWS_IAM_GROUP_NAME=${AWS_IAM_GROUP_NAME}"
${DEBUG} && echo "AWS_IAM_GROUP_POLICIES=${AWS_IAM_GROUP_POLICIES}"
${DEBUG} && echo "AWS_IAM_GROUP_USERS_PATH=${AWS_IAM_GROUP_USERS_PATH}"
${DEBUG} && echo "AWS_IAM_GROUP_USERS_NAMES=${AWS_IAM_GROUP_USERS_NAMES}"
${DEBUG} && echo "AWS_IAM_GROUP_USERS_PASSWORD=${AWS_IAM_GROUP_USERS_PASSWORD}"
${DEBUG} && echo "AWS_IAM_USER_ACCESS_KEY_FILENAME=${AWS_IAM_USER_ACCESS_KEY_FILENAME}"

# If there is no AWS IAM group for the name.
if aws iam get-group --group-name ${AWS_IAM_GROUP_NAME} || false
then
	${DEBUG} && echo "AWS IAM group '${AWS_IAM_GROUP_NAME}' already exists"
else 
	# Creates AWS IAM group.
	${DEBUG} && echo "Creating AWS IAM group '${AWS_IAM_GROUP_NAME}'"
	aws iam  create-group \
			--path ${AWS_IAM_GROUP_PATH} --group-name ${AWS_IAM_GROUP_NAME}
fi

# For each group policy.
IFS=','; for AWS_IAM_GROUP_POLICY in `echo "${AWS_IAM_GROUP_POLICIES}"`
do
	if [ "${AWS_IAM_GROUP_POLICY}" != "" ]
		then
		# Sets the group policy.
		${DEBUG} && echo "Setting AWS IAM group policy '${AWS_IAM_GROUP_POLICY}'"
		aws iam  attach-group-policy \
				--policy-arn ${AWS_IAM_GROUP_POLICY} \
				--group-name ${AWS_IAM_GROUP_NAME}
	fi
done

# For each group user.
IFS=','; for AWS_IAM_USER_NAME in `echo "${AWS_IAM_GROUP_USERS_NAMES}"`
do
	if [ "${AWS_IAM_USER_NAME}" != "" ] 
	then
		# If there is no AWS IAM user for the name.
		if aws iam get-user --user-name ${AWS_IAM_USER_NAME} || false
		then
			${DEBUG} && echo "AWS IAM user '${AWS_IAM_USER_NAME}' already exists"
		else 
			${DEBUG} && echo "Creating user '${AWS_IAM_USER_NAME}'"
			aws iam create-user \
					--path ${AWS_IAM_GROUP_USERS_PATH} \
					--user-name ${AWS_IAM_USER_NAME}
			# If it is a service user.
			if [ "${AWS_IAM_USER_ACCESS_KEY_FILENAME}" != "" ]
			then
				${DEBUG} && echo "Creating access key '${AWS_IAM_USER_NAME}'"
				AWS_ACCESS_KEY=`aws iam create-access-key --user-name ${AWS_IAM_USER_NAME}`
				touch ${AWS_IAM_USER_ACCESS_KEY_FILENAME}_${AWS_IAM_USER_NAME}.properties
				echo "AWS_ACCESS_KEY_ID=`jq -r '.AccessKey.AccessKeyId' <<EOF
${AWS_ACCESS_KEY}
EOF
`" >> ${AWS_IAM_USER_ACCESS_KEY_FILENAME}_${AWS_IAM_USER_NAME}.properties
				echo "AWS_SECRET_ACCESS_KEY=`jq -r '.AccessKey.SecretAccessKey' <<EOF
${AWS_ACCESS_KEY}
EOF
`" >> ${AWS_IAM_USER_ACCESS_KEY_FILENAME}_${AWS_IAM_USER_NAME}.properties
			# If it is not a service user.
			else 
				${DEBUG} && echo "Creating user profile '${AWS_IAM_USER_NAME}'"
				aws iam create-login-profile \
						--user-name ${AWS_IAM_USER_NAME} \
						--password ${AWS_IAM_GROUP_USERS_PASSWORD} \
						--password-reset-required
			fi
		fi
		# Adds the user to the group.
		${DEBUG} && echo "Adding user '${AWS_IAM_USER_NAME}' to group '${AWS_IAM_GROUP_NAME}'"
		aws iam add-user-to-group --group-name ${AWS_IAM_GROUP_NAME} \
				--user-name ${AWS_IAM_USER_NAME}
	fi
done

# Print script end if on debug mode.
${DEBUG} && echo  "Finishing 'aws_iam_create_group_users'"
