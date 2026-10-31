# AI Access Map — homelab-portfolio

> **Purpose:** one place that records *how* to reach each system, *what works*, *what is blocked*,
> and the password protocol. This is the main speed bottleneck for every AI tool, so it lives here.
>
> **Last updated:** 2026-10-25 evening (America/Chicago) — by Bionic; folded in Lee's preferences
> **Status:** FINAL (reconciled 2026-10-25; preferences folded in 2026-10-25 evening). Part of the shared brain; read via `INDEX.md`.
>
> **All paths below are read-only by default.** Nothing in this file changes live state.
>
> **Working machine (2026-10-25, Lee's preference):** the **Linux box (`devops-workstation`)** is Lee's
> primary working surface — VS Code → Linux terminal → **Hermes** (preferred) and **Continue** (parameters
> still unfinished). Bionic reads the repo and the `Z:` handoff share directly, so *reading* never needs Lee;
> *executing* on the Linux box is Lee's keyboard (the agent hands him complete commands). See
> `DECISIONS.md` D-026-1 / D-026-2.

---

## 1. The machines

| Host | IP | Role | How we reach it |
|---|---|---|---|
| `devops-workstation` | `192.168.0.159` | Lee's Linux box (VS Code, our work surface) | we are already here |
| Unraid | `192.168.0.102` | Backup tier (etcd snapshots, token, app data) | `ssh root@192.168.0.102` |
| PVE / bastion | `192.168.0.182` (LAN) → `192.168.0.202` (VM) | SSH bastion into the K3s VMs | `ssh -i ~/.ssh/homelab_bastion_ed25519 k3s-jump@192.168.0.202` |
| k3s-server-01 | `10.20.0.101` | K3s control-plane + etcd (the one we inspect) | via bastion, `ansible@10.20.0.101` |
| k3s-server-02 | `10.20.0.102` | K3s control-plane + etcd | via bastion (rarely needed) |
| k3s-server-03 | `10.20.0.103` | K3s control-plane + etcd | via bastion (rarely needed) |
| `.162` | `192.168.0.162` | Unraid NFS ACL allow-list entry | **Currently unreachable** — do not use |

## 2. K3s inspection (the path that works)

**Two-terminal SSH-through-bastion.** Open the tunnel **first** (terminal A), inspect **second** (terminal B).

Terminal A — open the bastion forward (keeps running; this is the "reverse ssh" Lee set up):

```bash
ssh -N -f -L 2222:10.20.0.101:22 \
  -i ~/.ssh/homelab_bastion_ed25519 -o IdentitiesOnly=yes \
  k3s-jump@192.168.0.202
```

Terminal B — inspect (read-only). Replace `<cmd>` with the specific kubectl/systemctl command:

```bash
ssh -p 2222 -i ~/.ssh/homelab_ansible_ed25519 -o IdentitiesOnly=yes ansible@127.0.0.1 \
  'sudo -n k3s kubectl <cmd>'
```

**Verified working (2026-10-24):** `get nodes`, `get ns`, `get pvc -A`, `get sc`,
`get cronjobs -A`, `get cm <name> -n monitoring -o yaml`, `systemctl list-timers`.

**Keys:**
- Bastion key: `~/.ssh/homelab_bastion_ed25519` (user `k3s-jump`). Has a passphrase → Lee types it.
- Node key: `~/.ssh/homelab_ansible_ed25519` (user `ansible`).
- `sudo -n` works for `k3s kubectl` (no password needed) — do not fall back to a passworded sudo.

**Bastion constraint (why the easy path is blocked):** `authorized_keys` has
`permitopen="10.20.0.101:22","10.20.0.102:22","10.20.0.103:22"` — **port 22 only**. That is why
`kubectl --kubeconfig` through `127.0.0.1:16443` gets *connection reset by peer* (it needs 6443).
**Do not "fix" this by widening `permitopen`** without Lee's explicit go — it's a live-config change.

## 3. Unraid (read-only)

```bash
ssh root@192.168.0.102          # Lee types the password at the prompt
# then, read-only, e.g.:
ls -ld /mnt/user/k3s-backups
find /mnt/user/k3s-backups -printf '%y %u %g %m %s %TY-%Tm-%Td %TH:%TM %p\n'
# verify (never reads the token itself):
(cd <dir> && sha256sum -c <snapshot>.sha256)
```

- **Never** open, print, copy, hash, or expose the real token. Check it for *presence* + *regular-file* + *0600* only.
- NFS mount from `.159` is **not usable**: Unraid exports `k3s-backups` only to `.162`, which is unreachable. Use SSH instead.

## 4. What is blocked / not usable (do not retry blindly)

| Path | Why it fails | Use instead |
|---|---|---|
| `kubectl --kubeconfig ~/.kube/k3s-homelab.yaml` | bastion `permitopen` allows 22 only, not 6443 → reset by peer | the SSH-through-bastion path in §2 |
| NFS mount from `.159` | export ACL is `.162`-only; `.162` unreachable | `ssh root@192.168.0.102` (§3) |
| `apt-get install kubectl` | package not in this Ubuntu repo | snap, or just use `k3s kubectl` on the node (§2) |

## 5. Password & credential protocol (hard rule)

- When a **sudo or SSH password/passphrase prompt** appears, the agent **stops and tells Lee exactly
  which prompt is waiting**. **Lee types it at the keyboard.**
- **Never** ask Lee to paste, dictate, save, print, or place a credential in chat, a command, a
  report, or a handoff.
- **Never** read, print, hash, copy, or expose the real K3s token or kubeconfig credentials.

## 6. Read-only default

Every command in this file is read-only. Any command that would *apply a manifest, restart/scale a
workload, modify alerts, change firewall/routes/kubeconfig, create a backup, or edit Unraid/NFS
config* is **out of scope** until Lee explicitly authorizes that specific action.
