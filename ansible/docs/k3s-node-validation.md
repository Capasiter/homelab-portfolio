# K3s Node Bootstrap Live Validation

- **Validation date:** July 25, 2026
- **Environment:** Isolated K3s infrastructure
- **Result:** Passed
- **Nodes:** `k3s-server-01`, `k3s-server-02`, and `k3s-server-03`

## Purpose

This validation confirmed that Ansible could securely reach three isolated Ubuntu VMs through a restricted SSH bastion, apply the existing Linux baseline through a controlled canary rollout, preserve SSH access after hardening, and complete an idempotent second run across the entire group.

K3s software was not installed during this phase.

## Validated Stack

| Component | Version or value |
|---|---|
| Ansible Core | 2.16.3 |
| Controller | Ubuntu 24.04 development workstation |
| Targets | Three Ubuntu 24.04 Proxmox VMs |
| Target group | `k3s_servers` |
| Baseline role | `linux_baseline` |
| Target account | `ansible` |
| Bastion account | `k3s-jump` |
| Target authentication | Dedicated ED25519 key |
| Bastion authentication | Separate passphrase-protected ED25519 key |
| Privilege escalation | Passwordless sudo on target VMs |
| Isolated network | `10.20.0.0/24` |

## Management-Access Problem

The Ansible controller is attached to the management network and has no direct route into the isolated K3s subnet.

Changing the upstream router would have expanded the lab network’s exposure and coupled automation access to household routing. Connecting the unused physical lab interface would also have weakened the intended virtual isolation.

Instead, the existing Proxmox host provides a controlled SSH transit path because it already has interfaces on both virtual networks.

No upstream-router, physical-NIC, bridge, gateway, or VM network changes were required.

## Restricted Bastion Design

A dedicated local Linux account named `k3s-jump` was created on the Proxmox host.

The account was verified with:

- No sudo or administrative group membership
- Locked password
- `/usr/sbin/nologin` shell
- Private `700` home directory
- Key-only SSH authentication
- No interactive shell
- No TTY allocation
- No SFTP or subsystem sessions
- No SSH-agent forwarding
- No X11 forwarding
- No tunnel devices
- No user SSH startup file
- Local TCP forwarding only
- Forwarding restricted to the three K3s SSH endpoints

The effective OpenSSH policy is:

```text
AuthenticationMethods publickey
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
AllowTcpForwarding local
PermitOpen 10.20.0.101:22 10.20.0.102:22 10.20.0.103:22
AllowStreamLocalForwarding no
AllowAgentForwarding no
X11Forwarding no
PermitTTY no
PermitTunnel no
PermitUserRC no
MaxSessions 0
```

`MaxSessions 0` prevents shell, login, and subsystem sessions while still allowing the explicitly permitted forwarding channels.

The installed public-key entry adds a second enforcement layer:

- Restricted to the controller’s source address
- `restrict` enabled
- Port forwarding explicitly re-enabled
- Three exact `permitopen` destinations
- No private-key material stored on Proxmox

## Key Separation

The two SSH hops use different identities:

| Hop | Account | Key |
|---|---|---|
| Controller to bastion | `k3s-jump` | `homelab_bastion_ed25519` |
| Bastion to K3s targets | `ansible` | `homelab_ansible_ed25519` |

The bastion key is passphrase protected and loaded into `ssh-agent` for the active controller session. The private keys remain outside the repository.

The bastion does not receive or forward the target private key or SSH agent.

## Bastion Security Validation

### Permitted Destinations

SSH forwarding succeeded to:

- `10.20.0.101:22`
- `10.20.0.102:22`
- `10.20.0.103:22`

Each connection authenticated to the final target as `ansible`.

### Denied Destination

A forwarding attempt to the OPNsense gateway was rejected by OpenSSH:

```text
channel 0: open failed: administratively prohibited: open failed
stdio forwarding failed
```

This confirmed that the bastion cannot be used as a general-purpose tunnel into the isolated subnet.

### Password Authentication

A password-only connection attempt was rejected immediately:

```text
k3s-jump@bastion: Permission denied (publickey).
```

No password prompt was offered.

### Interactive Access

Direct access to `k3s-jump` authenticated with the approved key but could not open a shell or session channel.

## Inventory Design

The live Ansible inventory now uses this hierarchy:

```text
@all:
  |--@ungrouped:
  |--@linux_servers:
  |  |--@development:
  |  |  |--ubuntu-dev-01
  |  |--@k3s_cluster:
  |  |  |--@k3s_servers:
  |  |  |  |--k3s-server-01
  |  |  |  |--k3s-server-02
  |  |  |  |--k3s-server-03
```

This supports several operational scopes:

- `linux_servers` for the reusable Ubuntu baseline
- `development` for the existing development container
- `k3s_cluster` for future cluster-wide automation
- `k3s_servers` for the three K3s server nodes

The `k3s_cluster` group inherits the restricted ProxyJump configuration. The live inventory remains ignored by Git, while the committed example documents the sanitized structure.

## Ansible Connectivity Validation

The resolved canary variables were:

```text
ansible_host: 10.20.0.101
ansible_user: ansible
ansible_ssh_common_args: -o ProxyJump=pve-k3s-bastion
```

Ansible’s Python-based ping module succeeded on all three nodes:

```text
k3s-server-01 | SUCCESS => ping: pong
k3s-server-02 | SUCCESS => ping: pong
k3s-server-03 | SUCCESS => ping: pong
```

Every result reported `changed: false`.

## Canary Baseline Rollout

The baseline was first previewed with check mode and diff output against only `k3s-server-01`.

The preview identified the expected changes:

- Refresh the APT cache
- Install the missing `unzip` package
- Change the timezone from `Etc/UTC` to `America/Chicago`
- Create the managed SSH-hardening drop-in
- Restart SSH after handler validation

The real canary apply completed successfully:

```text
k3s-server-01 : ok=9 changed=6 unreachable=0 failed=0
```

The `Validate the SSH configuration` handler ran `/usr/sbin/sshd -t` successfully before the SSH service restarted.

## Post-Restart Canary Validation

After the SSH restart:

- ProxyJump access remained operational
- Hostname remained `k3s-server-01`
- SSH service reported `active`
- Timezone reported `America/Chicago`
- Effective SSH policy matched the declared baseline

```text
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
```

Only after the canary passed were the remaining nodes changed.

## Remaining-Node Rollout

The proven baseline was applied to `k3s-server-02` and `k3s-server-03`.

Both SSH configurations passed validation before restart:

```text
k3s-server-02 : ok=9 changed=6 unreachable=0 failed=0
k3s-server-03 : ok=9 changed=6 unreachable=0 failed=0
```

Post-restart checks confirmed matching hostnames, active SSH services, correct timezones, and identical effective authentication policy on all three nodes.

## Three-Node Idempotence Validation

The complete baseline was run again against `k3s_servers`.

```text
k3s-server-01 : ok=7 changed=0 unreachable=0 failed=0
k3s-server-02 : ok=7 changed=0 unreachable=0 failed=0
k3s-server-03 : ok=7 changed=0 unreachable=0 failed=0
```

The `changed=0` results prove that all three systems converged on the declared baseline and that repeated execution introduced no additional changes.

## Security Controls

- No router or physical-network changes were made
- Bastion and target authentication use separate keys
- The bastion key is passphrase protected
- SSH agent forwarding is disabled
- The bastion account has no administrative privileges
- Password and interactive login are disabled
- Forwarding is limited to three exact destinations
- Target SSH configuration is validated before restart
- Target password, keyboard-interactive, and root SSH login are disabled
- Live inventory and private keys remain outside Git
- Public inventory uses sanitized values
- Proxmox console access remains available for recovery

## Current Limitations

Using the Proxmox host as a forwarding-only bastion is a pragmatic homelab design. A production environment would normally prefer a dedicated bastion host, managed VPN, or identity-aware access proxy so the hypervisor is not part of the routine management path.

The bastion key must be unlocked and loaded into `ssh-agent` before the controller can use it. This preserves passphrase protection while allowing automation during the active agent session.

## Validation Outcome

The K3s node-bootstrap phase passed.

All three Ubuntu VMs are securely reachable through a restricted bastion, consistently configured by the reusable Ansible baseline, hardened against password and root SSH access, and proven idempotent.

The next phase is to build and apply the Ansible automation for the three-node K3s control plane.
