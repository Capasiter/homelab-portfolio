# Proxmox OpenTofu Infrastructure

This project uses OpenTofu to provision and manage infrastructure on a Proxmox VE homelab. It demonstrates a modular Infrastructure as Code workflow with reusable modules, environment-specific configuration, secure handling of credentials, and live infrastructure validation.

## Delivered Infrastructure

The development environment currently manages a live Ubuntu 24.04 LXC container:

| Setting | Value |
|---|---|
| Proxmox node | `pve` |
| Container ID | `337` |
| Hostname | `ubuntu-dev-01` |
| Status | Running |
| CPU | 2 cores |
| Memory | 3072 MB |
| Swap | 512 MB |
| Disk | 16 GB |
| Networking | DHCP on `vmbr0` |
| Start on boot | Enabled |
| Container type | Unprivileged |
| Nesting | Enabled |

A live refresh and plan confirmed that the deployed container matches the OpenTofu configuration with no infrastructure drift.

See [Live Validation](docs/live-validation.md) for the validation evidence, troubleshooting notes, and security controls.

## Repository Structure

```text
proxmox/opentofu/
├── docs/
│   └── live-validation.md
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── outputs.tf
│       ├── provider.tf
│       ├── variables.tf
│       └── versions.tf
├── modules/
│   └── ubuntu-lxc/
│       ├── main.tf
│       ├── outputs.tf
│       ├── README.md
│       ├── variables.tf
│       └── versions.tf
├── archive/
├── .gitignore
├── README.md
└── terraform.tfvars.example
```

- `environments/dev/` defines the development deployment and calls the reusable module.
- `modules/ubuntu-lxc/` contains the reusable Ubuntu LXC resource definition.
- `docs/` contains live-validation and operational documentation.
- `archive/` preserves the earlier prototype configuration for project history.
- `terraform.tfvars.example` documents required inputs using safe placeholder values.

## Requirements

Before using this project, you need:

- Proxmox VE with API access
- An Ubuntu 24.04 LXC template available in Proxmox storage
- OpenTofu 1.10.0 or newer
- Network access from the OpenTofu workstation to the Proxmox API
- A dedicated Proxmox API identity and token
- Appropriate Proxmox ACL permissions for the target node, storage, and container resources

The configuration currently pins the `bpg/proxmox` provider to version `0.66.0`.

## Quick Start

From the repository root, enter the development environment:

```bash
cd proxmox/opentofu/environments/dev
```

Copy the sanitized example configuration:

```bash
cp ../../terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and replace the placeholder endpoint, API token, template, storage, and environment values with values for your Proxmox environment.

Initialize the working directory:

```bash
tofu init
```

Format and validate the configuration:

```bash
tofu fmt -check -recursive
tofu validate
```

Review the proposed infrastructure changes:

```bash
tofu plan
```

Only after carefully reviewing the plan, deploy the configuration:

```bash
tofu apply
```

Never run `tofu apply` against an environment you do not understand or have permission to modify.

## Security Practices

- Real `terraform.tfvars` files are excluded from Git.
- OpenTofu state, saved plans, downloaded providers, and local override files are excluded from Git.
- The committed example file contains placeholders only.
- Proxmox automation uses a dedicated service identity and API token.
- API tokens must be granted only the permissions required for the managed resources.
- Secrets must never be pasted into documentation, terminal output shared publicly, commits, or screenshots.
- A previously exposed development token was revoked and replaced.
- State files must be treated as sensitive because providers can store infrastructure details or secret values in them.

## Current Limitations

- The project currently deploys one development LXC container.
- State is stored locally rather than in a remote state backend.
- The development environment uses DHCP instead of a reserved or static address.
- TLS verification can be disabled for the homelab's self-signed Proxmox certificate.
- Automated configuration management has not yet been added.
- Production environment configuration and CI validation are not yet implemented.
- The live deployment depends on environment-specific Proxmox storage, networking, templates, and ACLs.

## Next Milestone

The next milestone is to add Ansible configuration management for the OpenTofu-provisioned container. OpenTofu will remain responsible for infrastructure lifecycle, while Ansible will configure the operating system, packages, users, security settings, and services.

This separation demonstrates a standard automation pattern:

```text
OpenTofu provisions infrastructure
              ↓
Ansible configures the operating system
              ↓
Validation confirms the delivered service
```
