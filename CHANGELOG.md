# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-07-18

### Added

- GitHub Actions workflow with independent OpenTofu and Ansible validation jobs.
- Automated OpenTofu formatting, backend-disabled initialization, and configuration validation.
- Automated sanitized-inventory parsing, playbook syntax checking, and production-profile Ansible linting.
- Validation on pull requests and pushes to the `main` branch.

### Changed

- Renamed the sanitized inventory from `hosts.yml.example` to `hosts.example.yml` so Ansible recognizes it as YAML.
- Updated Ansible documentation to use the parseable example-inventory filename.

### Security

- Restricted workflow permissions to read-only repository contents.
- Kept Proxmox credentials, SSH keys, live inventory, state, plans, and live-host connections out of CI.
- Prevented public CI from running OpenTofu `plan` or `apply`.

## [0.2.0] - 2026-07-18

### Added

- Role-based Ansible Linux baseline for the OpenTofu-provisioned Ubuntu container.
- Repository-scoped Ansible configuration, structured inventory, reusable role, and deployment playbook.
- Automated administration-package installation and timezone configuration.
- SSH hardening with configuration validation before service restart.
- Sanitized example inventory and live-validation documentation.

### Changed

- Updated the portfolio landing page to show live-validated Ansible configuration management.
- Advanced the project roadmap to automated CI validation and future K3s infrastructure.

### Security

- Added a dedicated password-locked automation account using ED25519 key authentication and controlled sudo escalation.
- Disabled SSH password authentication, keyboard-interactive authentication, and direct root login.
- Excluded live inventory, private keys, vault-password files, and retry files from version control.

## [0.1.0] - 2026-07-18

### Added

- Reusable OpenTofu module for provisioning Ubuntu LXC containers on Proxmox VE.
- Development environment with configurable compute, storage, networking, and container settings.
- Input validation, documented outputs, and pinned provider requirements.
- Live Ubuntu 24.04 LXC deployment with two CPU cores, 3072 MB memory, 512 MB swap, and a 16 GB disk.
- Runtime verification for container identity, resource allocation, networking, start-on-boot behavior, unprivileged operation, and nesting.
- Live-validation report documenting the deployed stack, validation results, API troubleshooting, security controls, and current limitations.
- Sanitized example configuration containing all required inputs.
- Project and module documentation for setup, structure, requirements, security, and future work.

### Changed

- Updated the portfolio landing page to reflect the live-validated OpenTofu deployment.
- Replaced the outdated OpenTofu project status and workflow documentation.
- Expanded `.gitignore` coverage for local variables, state, saved plans, provider data, logs, override files, and CLI configuration.

### Security

- Kept real API credentials, local variable files, state, and provider data out of version control.
- Used a dedicated Proxmox service identity and API token for automation.
- Documented the distinction between authentication failures (`401`) and authorization failures (`403`).
- Revoked and replaced a previously exposed development API token.
