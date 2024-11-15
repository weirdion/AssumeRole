# AssumeRole.sh

> Original script and inspiration: https://github.com/danktec/AssumeRole

A pure bash CLI tool for easy sts:AssumeRole management.

Its only dependencies are `aws, jq, tail`

# Usage

## Assume a role
```bash
source AssumeRole.sh --role arn:aws:iam::[aws-account-id]:role/OrganizationAccountAccessRole
```

## UnAssume the role
```bash
source AssumeRole.sh --unset
# or just type
UnsetVars
```
## Arguments
```
Usage: source $0 [--role ROLE_NAME] [--duration 3600] [-no-display-user] [--session-name test]

optional arguments:
  -h, --help               show this help message and exit
  -r, --role STR           the name of the role to assume
  -d, --duration SECONDS   (optional) length of time the session should last
  -s, --session-name STR   (optional) the name of this session
  -n, --no-display-user    (optional) skip showing the current user (requires special IAM permissions)
  -u, --unset              (optional) unset AWS_* variables before proceeding
```

# Background

## Why Assume Anything?
Alternatives, like long-lived access keys tied to user accounts are a big no-no for obvious reasons.

Managing access with IAM users is bad because, it:

* Does not scale with single or multi-account architectures
* Does not play well with external aws orgs
* Keys never expire (only a matter of time until they are compromised)
* User's access levels and risks are harder to audit and reason about
* Is not the recommended model for service-accounts

Assuming a role with the appropriate security context is the canonical - 
and secure method to authenticate services and humans with the
AWS API.

## How sts:AssumeRole Works
By using IAM roles which posses the access required for a given purpose, a user (or 
instance-profile) can "Assume" the role for a given period of time. Many users can assume
one role. Only the ability to assume the role needs to be modified for the user.

New keys, and a session token, are delivered from the STS API. These new credentials
are temporary by design, meaning the keys expire after a given time, and new keys
must be requested.

The IAM Role defines a Trust Relationship which allows a "Principal" to assume it.

## Benefits of AssumeRole
* Logical separation of WHAT can be done and WHO can do it
* Default expiry limits on sensitive access keys which may be "out in the wild"
* Security separation between users/instance-profiles and roles

The user seeking to elevate their access must know at least the name of the role they wish
to assume. This creates an additional safeguard for compromised access key scenarios... The keys
themselves should be useless - only once they assume a role can they have any power.

This functionality can be further safeguarded with an `external-id` which ensures that a user could
never accidentally assume a role without also knowing the pseudo-secret external id.

## Challenges
AWS authentication keys are usually presented to boto tools in the ~/.aws/credentials file or as
environment variables.

This tool sets the following environment variables in the calling shell:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_SESSION_TOKEN

In order to achieve this, the `source` command must be used to call the script. This means
the script is only compatible with bash. (if you must use sh, try calling with the . method)

```
 -- /bin/bash - calling shell (this is where we need AWS_* vars to be set
  --- /bin/bash AssumeRole.sh - sub shell (this is where the variables are created)
```

## Features

(TODO)
### Security
External ID is an additional value which must be known by the assumer. This value can be
changed over time. It is not considered a "secret" - but should be hard to guess.



https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_common-scenarios_third-party.html
