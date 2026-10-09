# Security Engineering Playbook

## Discover
Inventory architecture, repositories, services, databases, environments, cloud accounts, CI/CD, secrets, roles, integrations, AI tools and plugins.

## Classify
Identify credentials, personal data, BIM/IP, manufacturer assets, project data, source code, signing keys, administrator capabilities and AI context.

## Threat model
Map entry points, trust boundaries, identities, privileged actions, data flows, third parties and abuse cases. Use STRIDE where useful.

## Review
Perform architecture, code, dependency, secrets, access-control, API, cloud and AI-agent reviews.

## Verify
Where safe and authorized, reproduce issues in isolated environments, write regression tests, inspect logs and validate permissions.

## Remediate
Prioritize exposed secrets, auth bypass, authorization flaws, cross-tenant access, RCE/injection, unsafe parsing/uploads, cloud exposure, supply-chain risk and AI tool abuse.

## Re-test
Every resolved issue should receive code/configuration verification and a regression check where practical.

## Release gate
Before production verify secrets, MFA, least-privilege IAM, backups, logging/alerts, TLS, admin protection, tenant isolation, rate limits, dependency/secret scans and constrained AI tool permissions.
