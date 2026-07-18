# Homelab Infrastructure Portfolio

Production-style homelab demonstrating Linux administration, Infrastructure as Code, automation, troubleshooting, and infrastructure operations across Proxmox VE and Unraid.

**Career focus:** Linux Systems Administration · Infrastructure Engineering · Cloud Support · Junior DevOps

## Current Milestone

The current milestone delivers a reusable OpenTofu implementation that manages a live Ubuntu 24.04 LXC container on Proxmox VE.

Delivered capabilities include:

- Reusable `ubuntu-lxc` OpenTofu module
- Separate development environment configuration
- Configurable compute, storage, and networking
- Input validation and documented outputs
- Live unprivileged LXC deployment with nesting and start-on-boot enabled
- Dedicated Proxmox service identity and API-token authentication
- Local secrets, provider data, and state excluded from version control
- Successful OpenTofu formatting and configuration validation
- Live refresh and plan confirming no infrastructure drift
- Runtime verification against the deployed Proxmox container
- Documented HTTP 401 and 403 API troubleshooting

> **Project status:** The OpenTofu development environment is live-validated. The deployed container matches its configuration, and Ansible configuration management is the next milestone.

## Featured Infrastructure Project

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
| Configuration management | Ansible | Next milestone |
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

1. Add an Ansible Linux baseline for the OpenTofu-provisioned container.
2. Add automated formatting and validation with GitHub Actions.
3. Evaluate remote state and state-locking options.
4. Add a production environment after the development workflow is established.
5. Provision dedicated virtual machines for K3s.
6. Integrate persistent storage, monitoring, and backups.
7. Add GitOps deployment after the Kubernetes foundation is operational.

## Security

Credentials, API tokens, local variable files, provider caches, saved plans, and state files are excluded from version control. Public example configuration contains placeholders only, and the Proxmox API uses a dedicated service identity with scoped permissions.

State files are treated as sensitive because infrastructure providers can store environment details or secret values in them.

## About

I am building this portfolio to demonstrate practical infrastructure skills through working systems, repeatable automation, troubleshooting, and technical documentation.

**Lee Austin**

[GitHub profile](https://github.com/Capasiter)
