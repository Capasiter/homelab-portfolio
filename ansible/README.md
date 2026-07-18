# Ansible Linux Baseline

This project applies a repeatable Linux server baseline to Ubuntu infrastructure provisioned by OpenTofu on Proxmox VE.

OpenTofu manages the infrastructure lifecycle. Ansible configures the operating system, administration packages, timezone, and SSH security settings.

## Delivered Configuration

The `linux_baseline` role:

- Confirms the managed host is running Ubuntu
- Refreshes the APT package cache
- Installs standard Linux administration packages
- Configures the system timezone
- Disables SSH password authentication
- Disables keyboard-interactive SSH authentication
- Disables direct root SSH login
- Keeps public-key SSH authentication enabled
- Validates the SSH configuration before restarting the service
- Produces an idempotent second run with no changes

## Repository Structure

```text
ansible/
├── inventory/
│   └── hosts.example.yml
├── playbooks/
│   └── linux_baseline.yml
├── roles/
│   └── linux_baseline/
│       ├── defaults/
│       │   └── main.yml
│       ├── handlers/
│       │   └── main.yml
│       └── tasks/
│           └── main.yml
├── .gitignore
├── ansible.cfg
└── README.md

```

## Requirements

- Ansible Core 2.16 or newer
- Network access to the managed Ubuntu host
- Python 3 and OpenSSH installed on the managed host
- A dedicated automation account with SSH key authentication
- Passwordless sudo access for the automation account
- A recovery path such as the Proxmox console

Private SSH keys, live inventory values, passwords, and other credentials must never be committed.

## Inventory Setup

From the `ansible/` directory, copy the sanitized example:

```bash
cp inventory/hosts.example.yml inventory/hosts.yml
```

Replace the documentation address with the managed host's real address. The live `hosts.yml` file is excluded from Git.

The default controller key path is:

```text
~/.ssh/homelab_ansible_ed25519
```

The private key remains on the Ansible controller and is not stored in this repository.

## Validation and Deployment

Run these commands from the `ansible/` directory.

Inspect the inventory:

```bash
ansible-inventory --graph
```

Test connectivity, Python discovery, and privilege escalation:

```bash
ansible linux_servers -m ansible.builtin.ping
```

Check playbook syntax:

```bash
ansible-playbook --syntax-check playbooks/linux_baseline.yml
```

Preview changes:

```bash
ansible-playbook --check --diff playbooks/linux_baseline.yml
```

Apply the baseline:

```bash
ansible-playbook playbooks/linux_baseline.yml
```

Run the playbook again to verify idempotence. A successful second run reports `changed=0`, `unreachable=0`, and `failed=0`.

## Security

- The automation account uses key-only SSH authentication
- Password and keyboard-interactive SSH authentication are disabled
- Direct root SSH login is disabled
- SSH configuration is validated before the service restarts
- Live inventory and local secret files are excluded from Git
- The Proxmox console remains available as a recovery path

## Next Steps

- Add automated syntax and lint validation with GitHub Actions
- Add support for additional Linux baseline settings
- Integrate the role with future Proxmox virtual machines
- Reuse the baseline while building the planned K3s environment
