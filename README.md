# AssumeRole.sh

Assuming a role with the appropriate security context is the canonical - 
and a security conscious way to authenticate processes (and people) with the
AWS API.

# Why Assume Anything?
Alternatives, like long-lived access keys tied to user accounts are a big no-no.

Managing access with IAM users is bad because, it:

* Does not scale
* Does not play well with external orgs
* Keys never expire (only a matter of time until they are compromised)
* User's access levels and risks are harder to audit and reason about
* Is not the recommended model for service-accounts

# How sts:AssumeRole Works
By using IAM roles which posses the access required for a given purpose, a user (or 
instance-profile) can "Assume" the role for a given period of time. Many users can assume
one role. Only the ability to assume the role needs to be modified for the user.

New keys, and a session token, are delivered from the STS API. These new credentials
are temporary by design, meaning the keys expire after a given time, and new keys
must be requested.

The IAM Role defines a Trust Relationship which allows a "Principal" to assume it.

# Benefits of AssumeRole
* Logical separation of WHAT can be done and WHO can do it
* Default expiry limits on sensitive access keys which may be "out in the wild"
* Security separation between users/instance-profiles and roles

The user seeking to elevate their access must know at least the name of the role they wish
to assume. This creates an additional safeguard for compromised access key scenarios... The keys
themselves should be useless - only once they assume a role can they have any power.

This functionality can be further safeguarded with an `external-id` which ensures that a user could
never accidentally assume a role without also knowing the pseudo-secret external id.

# Challenges
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

# Features

## Security
External ID is an additional value which must be known by the assumer. This value can be
changed over time. It is not considered a "secret" - but should be hard to guess.



https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_common-scenarios_third-party.html
