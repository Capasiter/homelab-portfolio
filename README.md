# Homelab Infrastructure Portfolio

Production-style homelab demonstrating Linux administration, Infrastructure as Code, automation, and infrastructure operations across Proxmox VE and Unraid.

**Career focus:** Linux Systems Administration · Infrastructure Engineering · Cloud Support · Junior DevOps

## Current Milestone

The active project is a reusable OpenTofu implementation for provisioning Ubuntu LXC containers on Proxmox VE.

Current capabilities include:

- Reusable `ubuntu-lxc` OpenTofu module
- Separate development environment configuration
- Configurable compute, storage, and networking
- Input validation and documented outputs
- Unprivileged LXC deployment with start-on-boot behavior
- Sensitive API-token handling
- Local secrets and state excluded from version control
- Successful OpenTofu formatting and validation

> **Project status:** The OpenTofu configuration is validated. Live deployment verification and an operational runbook are the next milestones.

## Featured Infrastructure Project

[View the Proxmox OpenTofu project](proxmox/opentofu/)

The project separates reusable infrastructure modules from environment-specific configuration:

    proxmox/opentofu/
    ├── environments/
    │   ├── dev/
    │   └── prod/
    ├── modules/
    │   └── ubuntu-lxc/
    ├── archive/
    ├── README.md
    └── terraform.tfvars.example

This structure allows infrastructure components to be reused while keeping environment values and credentials separate.

## Technology and Status

| Area | Technology | Status |
|---|---|---|
| Virtualization | Proxmox VE | Operational |
| Infrastructure as Code | OpenTofu and `bpg/proxmox` | Active development |
| Linux containers | Ubuntu LXC | Module validated |
| Configuration management | Ansible | Planned next phase |
| Containers | Docker | Used in homelab |
| Orchestration | Kubernetes/K3s | Future phase |
| Storage | Unraid | Operational |
| Secure remote access | Tailscale | Used in homelab |
| Version control | Git and GitHub | Active |

## Engineering Practices Demonstrated

- Reusable infrastructure modules
- Environment-specific configuration
- Input validation and version constraints
- Secret and state-file protection
- Git feature-branch workflow
- Consistent formatting and validation
- Clear documentation of current and planned work
- Incremental testing before production use

## Repository Structure

    homelab-portfolio/
    ├── ansible/       # Configuration-management work
    ├── diagrams/      # Architecture diagrams
    ├── docs/          # Runbooks and technical documentation
    ├── kubernetes/    # Future K3s implementation
    └── proxmox/       # Proxmox infrastructure automation

## Roadmap

1. Verify the OpenTofu deployment on Proxmox.
2. Document deployment, validation, and recovery procedures.
3. Build an Ansible Linux baseline.
4. Add automated formatting and validation with GitHub Actions.
5. Provision dedicated virtual machines for K3s.
6. Integrate persistent storage, monitoring, and backups.
7. Add GitOps deployment after the Kubernetes foundation is operational.

## Security

Credentials, API tokens, local variable files, provider caches, and state files are excluded from version control. Example configuration files contain placeholders only.

## About

I am building this portfolio to demonstrate practical infrastructure skills through working systems, repeatable automation, troubleshooting, and technical documentation.

**Lee Austin**

[GitHub profile](https://github.com/Capasiter)
