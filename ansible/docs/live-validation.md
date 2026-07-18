# Ansible Linux Baseline Live Validation

- **Validation date:** July 18, 2026
- **Environment:** Development
- **Result:** Passed

## Purpose

This validation confirmed that Ansible could connect to an OpenTofu-provisioned Ubuntu container, escalate privileges through a dedicated automation account, apply a repeatable Linux baseline, harden SSH, and complete an idempotent second run.

## Validated Stack

| Component | Version or Value |
|---|---|
| Ansible Core | 2.16.3 |
| Controller | Ubuntu 24.04 development workstation |
| Target platform | Proxmox VE Ubuntu 24.04 LXC |
| Proxmox container ID | 337 |
| Target hostname | `ubuntu-dev-01` |
| Role | `linux_baseline` |
| Connection | SSH public-key authentication |
| Privilege escalation | Passwordless sudo |

## Connectivity Validation

The inventory hierarchy was successfully parsed:

```text
@all:
  |--@ungrouped:
  |--@linux_servers:
  |  |--@development:
  |  |  |--ubuntu-dev-01
```

Ansible successfully verified SSH connectivity, Python discovery, and privilege escalation:

```text
ubuntu-dev-01 | SUCCESS
ping: pong
uid=0(root) gid=0(root) groups=0(root)
```

## Baseline Configuration

The role successfully:

- Confirmed the target operating system was Ubuntu
- Refreshed the APT package cache
- Installed standard administration packages
- Configured the `America/Chicago` timezone
- Installed a managed SSH hardening configuration
- Validated the SSH configuration before restarting the service

The initial baseline run completed without failures:

```text
ubuntu-dev-01 : ok=6 changed=4 unreachable=0 failed=0
```

The SSH-hardening run also completed without failures:

```text
ubuntu-dev-01 : ok=9 changed=2 unreachable=0 failed=0
```

## SSH Security Validation

The effective SSH daemon configuration was inspected after the service restart:

```text
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
```

Key-based access remained operational after the restart.

## Idempotence Validation

The completed playbook was run again after all baseline and security settings were applied:

```text
ubuntu-dev-01 : ok=7 changed=0 unreachable=0 failed=0
```

The `changed=0` result confirms that the managed host already matched the declared configuration and that the role did not repeat completed work.

## Security Controls

- A dedicated `ansible` automation account is used
- The automation account has no password-based login
- A dedicated ED25519 SSH key is used
- The private key remains outside the repository
- Live inventory is excluded from Git
- The committed inventory example uses a documentation-only address
- SSH password and keyboard-interactive authentication are disabled
- Direct root SSH login is disabled
- SSH configuration is validated before service restart
- Proxmox console access remains available for recovery

## Current Limitations

- The live inventory currently uses a DHCP-assigned address
- The automation account requires an initial bootstrap step
- The role currently targets Ubuntu only
- Validation currently covers one development container
- Automated linting and CI validation have not yet been implemented

## Next Milestone

The next phase will add GitHub Actions to automatically validate OpenTofu formatting and Ansible playbook syntax on pull requests.
