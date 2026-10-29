# Project Guide (for AI and human readers)

Shared project notes are still being built. This guide is grounded in repository files. **All deployment and validation claims sourced from README.md, CHANGELOG.md, and per-area READMEs are historical evidence recorded in the repository — not live checks performed this session.** No live infrastructure was checked while writing this file.

## 1. Project purpose

A hands-on infrastructure portfolio by Lee Austin (see `README.md`): an isolated Linux lab on one Proxmox host running a three-server K3s control plane with embedded etcd, built with OpenTofu and Ansible, with a stable internal API VIP (kube-vip), protected application rollouts, Prometheus/Grafana observability, off-server etcd backups to Unraid NFS, and Argo CD GitOps application delivery. The intent is to build, operate, and test what happens when things break — and document only what the evidence proves.

## 2. Major folders

| Path | Contents |
|---|---|
| `README.md` | Portfolio entry point; architecture, live-evidence table, roadmap, boundaries (historical) |
| `CHANGELOG.md` | Milestone records v0.1–v0.9 plus Unreleased (historical) |
| `proxmox/opentofu/` | OpenTofu modules (`modules/ubuntu-vm/`, `modules/ubuntu-lxc/`) and environments (`environments/dev/`, `environments/k3s/`, `environments/restore-lab/`); provisioning docs in `proxmox/opentofu/docs/` |
| `ansible/` | `ansible.cfg`, `requirements.yml`, `inventory/hosts.example.yml` (sanitized; live `hosts.yml` is excluded from Git), playbooks (`linux_baseline.yml`, `k3s_cluster.yml`, `k3s_backup.yml`, `k3s_storage_clients.yml`, `k3s_restore_lab_stage.yml`), roles (`linux_baseline`, `k3s_server`, `k3s_api_vip`, `k3s_backup`), validation records in `ansible/docs/` |
| `kubernetes/` | `k8s-learning/` (WebDemo workload + rolling-update lab), `argocd/` (install manifests, Applications, preserved drift evidence), `observability/` (pinned kube-prometheus-stack values, blackbox-exporter, alert rule), `storage-demo/` (Unraid NFS PV/PVC demo) |
| `scripts/` | `k3s-health-check.sh`, `pvc-status-validator.sh`, `collect-backup-evidence.py` (self-test in CI), `validate-backup-artifacts.py` (offline backup-artifact validator: checks snapshot/token presence, regular-file and `.sha256` sidecar format; no SSH, Kubernetes, or live-infrastructure access) |
| `test-pvc-validator/` | Fixtures and runner for the PVC status validator, exercised by CI |
| `docs/` | Portfolio history through v0.7, backup evidence collector, local-AI workflow/connection records, and `docs/ai/` (these shared notes) |
| `diagrams/` | Architecture diagrams (SVG): `portfolio-architecture.svg` (current lab) and `future-architecture.svg` (proposed future layout, labeled not-deployed) |
| `resume/` | Lee's résumé PDF (`Lee_Austin_Infrastructure_Support_Resume_2026.pdf`), linked from the README |
| `.github/workflows/` | `infrastructure-validation.yml` (static validation only) |

## 3. Argo CD workflow (sources: `kubernetes/argocd/README.md`, `kubernetes/argocd/applications/`)

- Argo CD v3.5.3, non-HA, manually bootstrapped via `kubernetes/argocd/install/` (namespace + Kustomize-composed upstream manifests); it does not manage its own installation.
- Applications (manual sync; automated sync, self-heal, and pruning disabled):
  - `web-demo`: tracks `main`, path `kubernetes/k8s-learning` (includes `web-demo.yaml`), destination namespace `k8s-learning` — `kubernetes/argocd/applications/web-demo.yaml`.
  - `storage-demo`: tracks `main`, path `kubernetes/storage-demo` (all `*.yaml`), destination namespace `storage-demo` — `kubernetes/argocd/applications/storage-demo.yaml`.
- Documented workflow (historical): install → register Application → manual sync → controlled replica drift (3→4) → Argo reports OutOfSync → human-initiated sync of only the drifted Deployment → Synced/Healthy, 3/3 Ready.
- Preserved evidence: `kubernetes/argocd/evidence/` (before, drift, diff, after).
- The README (latest released milestone) names Argo CD delivery as v0.9.0 and lists shared application storage as **planned**; `kubernetes/storage-demo/README.md` contains dated (2026-10-13) live-validation records for the NFS storage demo. Treat both as historical documentation, not verified state.

## 4. Automation and validation

- **Provisioning:** OpenTofu defines VM identities, addressing, and startup dependencies (`proxmox/opentofu/environments/k3s/`); `proxmox/opentofu/docs/k3s-live-validation.md` records historical convergence results.
- **Configuration:** Ansible playbooks and roles (`ansible/playbooks/`, `ansible/roles/`); historical idempotence (`changed=0`) recorded in `ansible/docs/k3s-node-validation.md` and `ansible/docs/k3s-cluster-validation.md`.
- **CI (static only, verified this session in `.github/workflows/infrastructure-validation.yml`):**
  - `pvc-validation`: Bash syntax checks and local fixtures for `scripts/pvc-status-validator.sh` and `test-pvc-validator/`; backup-evidence collector self-test.
  - `opentofu`: `tofu fmt -check`, `init -backend=false`, `validate` for `dev`, `k3s`, and `restore-lab`.
  - `ansible`: sanitized-inventory parse, playbook syntax checks, production-profile `ansible-lint`, shellcheck, backup systemd template rendering.
  - `observability`: pinned Helm render of `kube-prometheus-stack` 88.3.0 and kubeconform validation of all committed Kubernetes manifests.
  - Runs on pull requests and pushes to `main`, with `contents: read` only; no cluster credentials, no `plan`/`apply`.
- The CI badge reflects repository validation status only — not live cluster health (per `README.md`).

## 5. Known limits (all from README.md / CHANGELOG.md — historical)

- Three control-plane VMs share one physical Proxmox host; no physical-host high availability.
- Full etcd restore incomplete: decompression verified, blocked by a reproducible K3s reset-path panic (v0.7 record).
- Application and monitoring volumes use node-local storage; etcd snapshots do not back up PV contents.
- VIP failover exercise covered a kube-vip pod deletion only — no node power-off, network loss, or host failure; zero downtime not claimed.
- Argo CD: manual sync only; self-heal, pruning, automated sync disabled; installation not self-managed.
- NetworkPolicy is not claimed as implemented.
- CI is static validation; it never deploys to or queries the live lab.

## 6. Open questions

- The README roadmap lists shared application storage as **planned**, while `kubernetes/storage-demo/README.md` records dated live validation (2026-10-13) including cross-node reads and a single-file backup/restore. Which is current, and should the README roadmap and CHANGELOG be reconciled?
- Cross-node Deployment rescheduling and full application-volume recovery are marked untested in `kubernetes/storage-demo/README.md` — is that still the state of play?
- Outbound alert delivery (Alertmanager) and blackbox-exporter redundancy remain future work per README — any movement in the Unreleased CHANGELOG section?
- The local-AI pilot (Hermes/Continue) is documented in `docs/local-ai-workflow.md`; CHANGELOG notes Continue's extension execution location remains unverified. What is the current scope boundary?
- The backup evidence collector intentionally does not verify checksums, freshness, or restores (`CHANGELOG.md` Unreleased) — does that limitation still hold?
- `README.md` notes the NFS export's `no_root_squash` for the trusted backup client as a scoped lab tradeoff — should any future production-oriented work revisit this?

---
*Sources are repository file paths listed above. Nothing in this guide is a live-verification result.*
