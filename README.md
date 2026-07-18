# Homelab Infrastructure Portfolio

Production-style homelab demonstrating Linux administration, Infrastructure as Code, automation, troubleshooting, and infrastructure operations across Proxmox VE and Unraid.

**Career focus:** Linux Systems Administration · Infrastructure Engineering · Cloud Support · Junior DevOps

## Current Milestone

The current milestone delivers an end-to-end infrastructure automation workflow for a live Ubuntu 24.04 LXC container on Proxmox VE.

Delivered capabilities include:

- Reusable OpenTofu module for provisioning Ubuntu LXC infrastructure
- Live infrastructure refresh and drift validation
- Dedicated Ansible automation account with ED25519 key authentication
- Structured inventory, playbook, and reusable `linux_baseline` role
- Automated installation of Linux administration packages
- Repeatable timezone configuration
- SSH password and keyboard-interactive authentication disabled
- Direct root SSH login disabled
- SSH configuration validation before service restart
- Successful live configuration of the OpenTofu-provisioned container
- Idempotent Ansible validation reporting `changed=0`
- Local credentials, private keys, live inventory, and state excluded from Git

> **Project status:** OpenTofu provisioning and Ansible configuration management are both live-validated. Automated CI validation is the next milestone.

## Featured Infrastructure Projects

### Ansible Linux Baseline

[View the Ansible Linux baseline project](ansible/)

[Read the Ansible live-validation report](ansible/docs/live-validation.md)

The Ansible project configures the OpenTofu-provisioned Ubuntu container with administration packages, timezone management, SSH hardening, validation handlers, and an idempotent role-based workflow.

### OpenTofu Infrastructure

[View the Proxmox OpenTofu project](proxmox/opentofu/)

[Read the live-validation report](proxmox/opentofu/docs/live-validation.md)

The project separates reusable infrastructure modules from environment-specific configuration:

```text
proxmox/opentofu/
├── docs/
│   └── live-validation.md
├── environments/
│   └── dev/
├── modules/
│   └── ubuntu-lxc/
├── archive/
├── README.md
└── terraform.tfvars.example
```

This structure allows infrastructure components to be reused while keeping environment values, credentials, and local state separate from committed code.

## Technology and Status

| Area | Technology | Status |
|---|---|---|
| Virtualization | Proxmox VE | Operational |
| Infrastructure as Code | OpenTofu and `bpg/proxmox` | Live validated |
| Linux containers | Ubuntu 24.04 LXC | Deployed and verified |
| Configuration management | Ansible | Live validated |
| Containers | Docker | Used in homelab |
| Orchestration | Kubernetes/K3s | Future phase |
| Storage | Unraid | Operational |
| Secure remote access | Tailscale | Used in homelab |
| Version control | Git and GitHub | Active |

## Engineering Practices Demonstrated

- Reusable infrastructure modules
- Environment-specific configuration
- Input validation and version constraints
- Least-privilege service authentication
- Secret and state-file protection
- Git feature-branch workflow
- Role-based Ansible configuration management
- Key-only SSH automation with controlled privilege escalation
- Pre-restart SSH configuration validation
- Idempotence verification with `changed=0`
- Consistent formatting and validation
- Infrastructure drift detection
- Runtime verification against live infrastructure
- Troubleshooting based on API response codes
- Clear documentation of delivered work and limitations

## Repository Structure

```text
homelab-portfolio/
├── ansible/       # Configuration-management work
├── diagrams/      # Architecture diagrams
├── docs/          # Runbooks and technical documentation
├── kubernetes/    # Future K3s implementation
└── proxmox/       # Proxmox infrastructure automation
```

## Roadmap

1. Add automated OpenTofu and Ansible validation with GitHub Actions.
2. Evaluate remote state and state-locking options.
3. Add a production environment after the development workflow is established.
4. Provision dedicated Proxmox virtual machines for K3s.
5. Deploy a three-node K3s cluster with Ansible.
6. Integrate persistent storage, monitoring, and backups.
7. Add GitOps deployment after the Kubernetes foundation is operational.

## Security

Credentials, API tokens, local variable files, provider caches, saved plans, and state files are excluded from version control. Public example configuration contains placeholders only, and the Proxmox API uses a dedicated service identity with scoped permissions.

Ansible private keys, live inventory, vault-password files, and retry files are also kept out of version control.

State files are treated as sensitive because infrastructure providers can store environment details or secret values in them.

## About

I am building this portfolio to demonstrate practical infrastructure skills through working systems, repeatable automation, troubleshooting, and technical documentation.

**Lee Austin**

[GitHub profile](https://github.com/Capasiter)
