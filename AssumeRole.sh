#!/bin/bash +x
set -o pipefail

POSITIONAL_ARGS=()

function usage() {
   cat << HELP

   Usage: source $0 [--role ROLE_NAME] [--duration 3600] [-no-display-user] [--session-name test]

   optional arguments:
     -h, --help               show this help message and exit
     -r, --role STR           the name of the role to assume
     -d, --duration SECONDS   (optional) length of time the session should last
     -s, --session-name STR   (optional) the name of this session
     -n, --no-display-user    (optional) skip showing the current user (requires special IAM permissions)
     -u, --unset              (optional) unset AWS_* variables before proceeding

HELP
}

function UnsetVars() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
}

# Check how the script is being called
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf "\n  Error: This script must be called using 'source' in order to set
  AWS_ variables in your shell E.g: 'source ./AssumeRole.sh --help'\n"
  usage
  exit 1
fi

if [[ $1 == "" ]]; then usage; return 1; fi

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      return
      shift # past argument
      ;;
    -r|--role)
      ROLE_NAME="$2"
      shift # past argument
      ;;
    -d|--duration)
      SESSION_DURATION="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--session-name)
      SESSION_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -n|--no-display-user)
      DISPLAY_USER="false"
      shift # past argument
      shift # past value
      ;;
    -u|--unset)
      printf "Unsetting AWS_ vars"
      UnsetVars
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      usage
      return 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [[ $ROLE_NAME == "" ]]; then
  printf "Error: role-name is required. Specified with -r, --role\n"
  return 1
fi

# Set default values
SESSION_DURATION="${SESSION_DURATION:-3600}"
SESSION_NAME="${SESSION_NAME:-AssumeRoleScript}"

# Require some things
function RequireDep() {
  if ! [ -x "$(command -v $1)" ]; then
    printf "Error: $1 is not installed. Please install $1 to use this program\n" >&2
    return
  fi
}

# Dependencies required for this script
RequireDep aws
RequireDep jq
RequireDep tail

# Unset existing AWS_* variables
UnsetVars

printf "\nAssuming role '$ROLE_NAME' for $SESSION_DURATION seconds\n"

# When the current user is instance-profile, this command will fail due to insufficient permissions
if [[ $DISPLAY_USER != "false" ]]; then
  printf "\nCurrent User:\n"
  aws iam get-user --output table --query 'User.[UserName,Arn,UserId]'|tail -n5
fi

# Get .Credentials portion of the assume-role return value using jq
export AWS_API_RESULT=$(aws sts assume-role \
  --role-arn $ROLE_NAME \
  --role-session-name $SESSION_NAME \
  --duration-seconds $SESSION_DURATION \
  |jq -r .Credentials)

# Echo must be used here instead of printf
export AWS_ACCESS_KEY_ID=$(echo $AWS_API_RESULT|jq -r .AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $AWS_API_RESULT|jq -r .SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $AWS_API_RESULT|jq -r .SessionToken)
AWS_API_RESULT="null"

## Assumed role session info
printf "\nAssumed role: \n"
aws sts get-caller-identity --output table|tail -n5

printf "\nAWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY & AWS_SESSION_TOKEN have been set in your current shell environment\n\n"
