# Homelab Infrastructure Portfolio

### Build it. Operate it. Test what happens when it breaks.

A hands-on infrastructure portfolio by **Lee Austin**: isolated Linux infrastructure, a three-server Kubernetes control plane, repeatable automation, live monitoring, verified off-server backups, and a documented restore investigation.

> **Latest released milestone: Argo CD application delivery.** Deployed in the lab, with preserved drift-detection and manual-reconciliation evidence. [Read the configuration and validation evidence](kubernetes/argocd/README.md).

[![Infrastructure Validation](https://github.com/Capasiter/homelab-portfolio/actions/workflows/infrastructure-validation.yml/badge.svg)](https://github.com/Capasiter/homelab-portfolio/actions/workflows/infrastructure-validation.yml)
[![Infrastructure as Code](https://img.shields.io/badge/IaC-OpenTofu-844FBA?style=flat-square)](proxmox/opentofu/)
[![Automation](https://img.shields.io/badge/Automation-Ansible-EE0000?style=flat-square)](ansible/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-326CE5?style=flat-square)](ansible/docs/k3s-cluster-validation.md)
[![Observability](https://img.shields.io/badge/Observability-Prometheus%20%2B%20Grafana-F46800?style=flat-square)](kubernetes/observability/README.md)

**[Architecture](#architecture)** · **[Live evidence](#live-evidence)** · **[Engineering stories](#engineering-stories)** · **[Roadmap](#roadmap)** · **[About Lee](#about-lee)**

| Infrastructure | Reliability | Recovery |
|:---|:---|:---|
| **3 K3s server VMs**<br>Control plane + embedded etcd | **148 successful HTTP requests**<br>0 observed failures in a protected rollout | **Off-server etcd backups**<br>SHA-256 verification + protected token |
| **Internal API VIP**<br>kube-vip DaemonSet across all 3 servers | **Leader-pod handoff observed**<br>VIP moved from server 02 to server 03 | **Restore drill attempted**<br>Decompression verified; full restore blocked |

> **GitOps validation:** Argo CD detected replica drift from three to four; manual reconciliation restored WebDemo to Synced, Healthy, and 3/3 Ready and available replicas.
>
> **Latest release:** [v0.9.0 — Argo CD GitOps Delivery](https://github.com/Capasiter/homelab-portfolio/releases/tag/v0.9.0).
>
> **Scope:** Three VMs on **one physical Proxmox host**. This demonstrates control-plane redundancy and a pod-level failover exercise, not physical-host high availability. Full etcd restore remains incomplete.

## Architecture

The lab separates provisioning, configuration, runtime services, and off-server backups. Kubernetes API access stays inside the isolated lab; administration uses an SSH bastion.

```mermaid
flowchart TD
    Git["Git repository<br/>Version-controlled infrastructure"]
    CI["GitHub Actions<br/>Static validation only"]
    Automation["Infrastructure automation<br/>OpenTofu + Ansible"]
    Proxmox["Proxmox VE<br/>One physical host"]
    Admin["Administrator<br/>SSH bastion access"]
    Gateway["OPNsense gateway<br/>Isolated vmbr1 network"]
    VIP["Kubernetes API VIP<br/>10.20.0.110:6443"]
    Cluster["Three K3s server VMs<br/>Control plane + embedded etcd"]
    Services["Runtime services<br/>Traefik + WebDemo"]
    Observe["Observability<br/>Prometheus + Grafana + alerts"]
    Backup["Unraid NFS recovery storage<br/>Etcd snapshots + protected token"]

    Git --> CI
    Git --> Automation
    Automation --> Proxmox
    Admin --> Gateway
    Proxmox --> Gateway
    Gateway --> VIP
    VIP --> Cluster
    Cluster --> Services
    Cluster --> Observe
    Cluster --> Backup

    classDef delivery fill:#DBEAFE,stroke:#2563EB,color:#111827,stroke-width:2px,font-size:17px
    classDef boundary fill:#F1F5F9,stroke:#475569,color:#111827,stroke-width:2px,font-size:17px
    classDef runtime fill:#DCFCE7,stroke:#16A34A,color:#111827,stroke-width:2px,font-size:17px
    classDef recovery fill:#F3E8FF,stroke:#9333EA,color:#111827,stroke-width:2px,font-size:17px

    class Git,CI,Automation delivery
    class Proxmox,Admin,Gateway boundary
    class VIP,Cluster,Services,Observe runtime
    class Backup recovery
```

**Blue:** delivery and automation · **Green:** running platform · **Purple:** off-server recovery data · **Gray:** access and network boundaries.

The diagram groups workloads logically. The three K3s VMs share the same physical host; the VIP is owned by one server at a time, not a separate appliance. CI performs static checks and does not deploy to the live lab.

<details>
<summary><strong>Expand: node sizing and network design</strong></summary>

| Node | VM ID | Address | Role |
|---|---:|---|---|
| `k3s-server-01` | 401 | `10.20.0.101` | Control plane + etcd |
| `k3s-server-02` | 402 | `10.20.0.102` | Control plane + etcd |
| `k3s-server-03` | 403 | `10.20.0.103` | Control plane + etcd |

Each VM uses 4 CPU cores, 6144 MB RAM, a 32 GB disk, Ubuntu 24.04, cloud-init, and the QEMU guest agent. OpenTofu defines stable VM identities, addressing, and startup dependencies.

OPNsense VM 400 provides routing, DHCP, DNS forwarding, and outbound NAT. `vmbr0` carries management and OPNsense WAN traffic; `vmbr1` is the isolated lab bridge. No upstream-router changes or physical uplink on the isolated bridge are required.

[Provisioning and network implementation](proxmox/opentofu/environments/k3s/README.md)

</details>

## Live evidence

These are bounded test results, not uptime guarantees. Each link leads to implementation details or a validation record.

| Test | Observed result | Evidence |
|---|---|---|
| Infrastructure convergence | Full OpenTofu checks reported no changes in the documented runs | [Provisioning validation](proxmox/opentofu/docs/k3s-live-validation.md) |
| Linux and cluster automation | Live Ansible idempotence demonstrated with `changed=0` | [Node baseline](ansible/docs/k3s-node-validation.md) · [Cluster deployment](ansible/docs/k3s-cluster-validation.md) |
| Protected application rollout | 148 successful HTTP requests, 0 observed failures; separate revalidation: 120 successful, 0 failures | [Rolling-update lab](kubernetes/k8s-learning/README.md) |
| Availability alert lifecycle | Healthy → controlled failure → firing alert → recovery | [Observability validation](kubernetes/observability/README.md) |
| Off-server backup workflow | Snapshot, baseline/rolling retention, token protection, and checksum verification validated | [Backup and restore record](docs/portfolio-history-through-v0.7.md#restore-validation) |
| API leader-pod failover | VIP moved 02 → 03; no failed API probes recorded; 3/3 kube-vip pods and 3 Ready nodes afterward | [VIP validation](ansible/docs/k3s-api-vip-validation.md) |
| GitOps drift detection and manual reconciliation | Replica drift detected; manual sync restored Synced, Healthy, and 3/3 Ready replicas | [GitOps validation](kubernetes/argocd/README.md) |

**What the CI badge means:** repository validation status. It is not a live cluster-health indicator.

## Engineering stories

### 01 / A green rollout was not enough

The first rolling restart completed in Kubernetes but still produced a client-visible timeout. I added readiness checks, a minimum readiness interval, zero-unavailable rolling updates, controlled surge capacity, and a graceful drain window, then retested with live HTTP traffic.

**Result:** 148 successful requests with no observed failures in the protected rollout test.

[Read the failure, fix, and revalidation](kubernetes/k8s-learning/README.md)

### 02 / Backups needed more than a successful copy

Live testing exposed unexpected NFS ownership and checksum files retaining stale ownership. The fixes scoped the export policy to the trusted backup client and applied atomic write-then-rename handling to checksum files.

**Result:** verified off-server snapshot and token backups, protected baseline plus three rolling backups, and daily scheduling. An isolated restore attempt verified snapshot decompression but encountered a reproducible K3s reset-path panic. Full restore is **not** claimed as successful.

[Read the backup findings and restore limitation](docs/portfolio-history-through-v0.7.md#current-milestone---k3s-backup-and-recovery-readiness-v070)

### 03 / The API endpoint survived a leader-pod handoff

The API VIP is included in the K3s certificate SANs and managed by a kube-vip DaemonSet. During the September 19 test, the current leader pod on server 02 was deleted while API readiness probes ran through the VIP.

```mermaid
flowchart TD
    Before["Baseline<br/>server 02 owns VIP"]
    Action["Controlled action<br/>delete leader pod"]
    Move["VIP ownership<br/>moves to server 03"]
    Replace["Replacement pod<br/>starts on server 02"]
    Healthy["Recovered state<br/>3 pods running + 3 nodes Ready"]

    Before --> Action
    Action --> Move
    Action --> Replace
    Move --> Healthy
    Replace --> Healthy

    classDef initial fill:#DBEAFE,stroke:#2563EB,color:#111827,stroke-width:2px,font-size:16px
    classDef action fill:#FEF3C7,stroke:#D97706,color:#111827,stroke-width:2px,font-size:16px
    classDef healthy fill:#DCFCE7,stroke:#16A34A,color:#111827,stroke-width:2px,font-size:16px

    class Before initial
    class Action action
    class Move,Replace,Healthy healthy
```

**Result:** ownership moved to server 03, the deleted pod was replaced, and no failed API probes were recorded. The test did not measure application traffic or establish a zero-downtime bound.

[Read the test method, observed state, and limitations](ansible/docs/k3s-api-vip-validation.md)

## Explore the implementation

| Area | What to inspect |
|---|---|
| Infrastructure as code | [OpenTofu modules and environments](proxmox/opentofu/) |
| Host and cluster automation | [Ansible roles and playbooks](ansible/) |
| Stable API endpoint | [kube-vip role](ansible/roles/k3s_api_vip/) · [Cluster orchestration](ansible/playbooks/k3s_cluster.yml) |
| Application reliability | [Kubernetes workload and validation](kubernetes/k8s-learning/README.md) |
| Monitoring and alerting | [Observability configuration and evidence](kubernetes/observability/README.md) |
| GitOps application delivery | [Argo CD configuration and validation](kubernetes/argocd/README.md) · [WebDemo Application](kubernetes/argocd/applications/web-demo.yaml) |
| CI and change history | [Validation workflow](.github/workflows/infrastructure-validation.yml) · [Changelog](CHANGELOG.md) |
| Earlier engineering detail | [Preserved v0.1–v0.7 portfolio record](docs/portfolio-history-through-v0.7.md) |

<details>
<summary><strong>Expand: security and operating practices</strong></summary>

- Isolated lab networking and key-based SSH bastion access; no public Kubernetes API.
- Dedicated automation identities and documented Proxmox permission testing.
- Pinned K3s artifacts with SHA-256 verification.
- Root-owned K3s configuration and token files with mode `0600`.
- Sensitive join-token operations suppressed from logs and transferred through a non-cacheable in-memory Ansible fact.
- Kubernetes Secrets encryption validated across all three servers.
- Grafana credentials managed separately from committed Helm values.
- Read-only GitHub Actions repository permissions; static checks without live infrastructure credentials.
- Credentials, private keys, kubeconfigs, sensitive local inventory, state, saved plans, and configuration exports excluded from version control.
- A dedicated NFS export uses `no_root_squash` for the trusted backup client to preserve required ownership. This is a scoped lab tradeoff, not a general production recommendation.
- Feature branches, pull requests, checks, and documented live validation.

[Detailed security record and tradeoffs](docs/portfolio-history-through-v0.7.md#security)

</details>

## Roadmap

| Stage | Capability | Status |
|---|---|---|
| v0.1–v0.3 | OpenTofu foundation, hardened Linux baseline, read-only CI | Released |
| v0.4 | Three-server K3s control plane with embedded etcd | Released |
| v0.5 | Protected application rollouts tested under traffic | Released |
| v0.6 | Monitoring, application probing, and alert recovery | Released |
| v0.7 | Off-server backups, integrity checks, retention, and restore investigation | Released; full restore incomplete |
| v0.8 | Stable internal API VIP and leader-pod failover validation | Released |
| v0.9 | Argo CD application delivery with drift detection and manual reconciliation | Released |
| Next | Unraid-backed shared application storage and volume-recovery validation | Planned |
| Follow-up | Complete restore validation; notification delivery; broader failure testing | Not yet completed |
| Future | Human-supervised AI operations for log analysis, incident triage, and runbook assistance | Planned; not deployed |

The next-stage ordering is a roadmap, not a release commitment. AI-assisted operations will start in an isolated sandbox, with human-reviewed, auditable infrastructure changes.

### Boundaries worth knowing

- **Single physical host:** control-plane VM redundancy does not protect against loss of the Proxmox host.
- **Recovery:** snapshot integrity and decompression are validated; full etcd restore is not complete.
- **Storage:** current application and monitoring volumes use node-local storage. Etcd snapshots do not back up persistent-volume contents.
- **Failover:** the recorded exercise deleted one kube-vip pod. It did not power off a node, interrupt the network, or test physical-host failure.
- **Monitoring:** outbound alert delivery and blackbox-exporter redundancy remain future work.
- **GitOps:** Argo CD uses manual sync; automated sync, self-heal, and automatic pruning are disabled. Its installation is bootstrapped manually and is not self-managed. Continuous HTTP availability during reconciliation was not tested.
- **Isolation:** Kubernetes NetworkPolicy is not claimed as implemented.

## About Lee

I am transitioning from manufacturing, field service, and paid computer repair into Linux systems, infrastructure operations, and cloud support. This portfolio shows how I build working systems, investigate failures, automate repeatable operations, and document what the evidence actually proves.

**Focus:** Linux / Infrastructure Support · Systems Administration · Cloud Operations · Junior DevOps

[GitHub](https://github.com/Capasiter) · [LinkedIn](https://www.linkedin.com/in/leeaustinmn/)

**[Download Lee Austin’s Infrastructure Support Resume (PDF)](resume/Lee_Austin_Infrastructure_Support_Resume_2026.pdf)**

## Future architecture — completed-state vision

> **Proposed end state, not current deployment evidence.** The diagram extends the original Architecture layout with completed recovery work and human-supervised local AI operations.

```mermaid
%%{init: {"flowchart": {"nodeSpacing": 22, "rankSpacing": 85, "curve": "basis"}, "themeVariables": {"fontSize": "20px"}}}%%
flowchart TD
    Git["Git repository<br/>Version-controlled<br/>infrastructure"]
    CI["GitHub Actions<br/>Static validation only"]
    Automation["Infrastructure automation<br/>OpenTofu + Ansible"]
    Proxmox["Proxmox VE<br/>One physical host"]
    Admin["Administrator<br/>SSH bastion access"]
    Gateway["OPNsense gateway<br/>Isolated vmbr1 network"]
    VIP["Kubernetes API VIP<br/>10.20.0.110:6443"]
    Cluster["Three K3s server VMs<br/>Control plane<br/>+ embedded etcd"]
    Services["Runtime services<br/>Traefik + WebDemo<br/>Argo CD delivery"]
    Observe["Observability<br/>Prometheus + Grafana<br/>Logs + delivered alerts"]
    Storage["Unraid NFS storage<br/>Shared application data<br/>+ volume backups"]
    Backup["Unraid recovery storage<br/>Etcd snapshots<br/>+ protected token"]
    Restore["Isolated restore lab<br/>Validated cluster<br/>+ volume recovery"]
    Agent["Linux agent VM<br/>Runs on Proxmox<br/>Tools + workspace"]
    Model["Desktop AI server<br/>LM Studio + Qwen<br/>Two RTX 3060 GPUs"]
    Roles["AI operations<br/>Health + incident triage<br/>Code + runbook assistance"]
    Reports["Unraid agent records<br/>Reports + memory<br/>+ handoffs"]
    Review["Administrator review<br/>Evidence + proposed fixes"]
    Approved["Approved changes<br/>Return through Git<br/>Validate + document"]

    Git --> CI
    Git --> Automation
    Automation --> Proxmox
    Admin --> Gateway
    Proxmox --> Gateway
    Gateway --> VIP
    VIP --> Cluster
    Cluster --> Services
    Cluster --> Observe
    Services --> Storage
    Cluster --> Backup
    Storage --> Restore
    Backup --> Restore
    Proxmox ----> Agent
    Agent <-->|Inference| Model
    Observe -.->|Read context| Roles
    Agent --> Roles
    Roles --> Reports
    Reports --> Review
    Review --> Approved

    classDef delivery fill:#DBEAFE,stroke:#2563EB,color:#111827,stroke-width:2px,font-size:20px
    classDef boundary fill:#F1F5F9,stroke:#475569,color:#111827,stroke-width:2px,font-size:20px
    classDef runtime fill:#DCFCE7,stroke:#16A34A,color:#111827,stroke-width:2px,font-size:20px
    classDef recovery fill:#F3E8FF,stroke:#9333EA,color:#111827,stroke-width:2px,font-size:20px
    classDef ai fill:#FEF3C7,stroke:#D97706,color:#111827,stroke-width:2px,font-size:20px

    class Git,CI,Automation,Approved delivery
    class Proxmox,Admin,Gateway,Review boundary
    class VIP,Cluster,Services,Observe runtime
    class Storage,Backup,Restore,Reports recovery
    class Agent,Model,Roles ai
```

**Blue:** delivery and automation · **Green:** running platform · **Purple:** storage and recovery · **Gray:** access and network boundaries · **Amber:** local AI agents and inference.

The diagram groups workloads logically, just like the current Architecture diagram. All three K3s VMs and the agent VM share one physical Proxmox host; the VIP is owned by one K3s server at a time. CI performs static checks and does not deploy to the live lab. Argo CD reads approved application changes from Git.

The dedicated agent VM gathers health, logs, events, backup status, repository context, and runbooks. It requests inference from LM Studio on the desktop GPUs and saves reports and handoffs to Unraid. Proposed fixes go through administrator review, Git validation, and the appropriate infrastructure or application delivery process.

<details>
<summary><strong>Expand: AI placement and completion targets</strong></summary>

| System | Role |
|---|---|
| **Proxmox** | Infrastructure VMs, K3s services, dedicated Linux agent VM, and an on-demand restore-lab VM |
| **Desktop** | LM Studio serves Qwen on two RTX 3060 GPUs; local AI tasks require this endpoint to be available |
| **Unraid** | Shared application data, separate etcd and volume backups, and durable agent reports, memory, and handoffs |

Hermes is the initial agent candidate. Prime Agent can be evaluated for repository tasks; OpenClaw is an optional later interface. The diagram shows logical AI workflows, not a requirement to run several agents continuously.

**Completed-state targets:** shared storage and application-volume recovery tested; full isolated etcd restore validated; notifications delivered and tested; agent tool use evaluated on real lab tasks; reviewed changes and resulting evidence documented.

Physical-host high availability remains outside this design. Etcd snapshots do not replace application-volume backups. GPU inference stays on the desktop, and restore experiments run on demand to control Proxmox resource use.

</details>
