# Homelab Infrastructure Portfolio

### Build it. Operate it. Test what happens when it breaks.

A hands-on infrastructure portfolio by **Lee Austin**: isolated Linux infrastructure, a three-server Kubernetes control plane, repeatable automation, live monitoring, verified off-server backups, and a documented restore investigation.

> **Latest released milestone: Argo CD application delivery.** Deployed in the lab, with preserved drift-detection and manual-reconciliation evidence. [Read the configuration and validation evidence](kubernetes/argocd/README.md).

[![Infrastructure Validation](https://github.com/Capasiter/homelab-portfolio/actions/workflows/infrastructure-validation.yml/badge.svg)](https://github.com/Capasiter/homelab-portfolio/actions/workflows/infrastructure-validation.yml)
[![Infrastructure as Code](https://img.shields.io/badge/IaC-OpenTofu-844FBA?style=flat-square)](proxmox/opentofu/)
[![Automation](https://img.shields.io/badge/Automation-Ansible-EE0000?style=flat-square)](ansible/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-326CE5?style=flat-square)](ansible/docs/k3s-cluster-validation.md)
[![Observability](https://img.shields.io/badge/Observability-Prometheus%20%2B%20Grafana-F46800?style=flat-square)](kubernetes/observability/README.md)

**[Architecture](#architecture)** · **[Live evidence](#live-evidence)** · **[Engineering stories](#engineering-stories)** · **[Roadmap](#roadmap)** · **[About Lee](#about-lee)** · **[Résumé (PDF)](resume/Lee_Austin_Infrastructure_Support_Resume_2026.pdf)**

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
flowchart TB
    subgraph Build["BUILD AND VALIDATE"]
        Git["Git repository<br/>Version-controlled infrastructure"]
        CI["GitHub Actions<br/>Static validation only"]
        Automation["OpenTofu + Ansible<br/>Infrastructure automation"]
        Git --> CI
        Git --> Automation
    end
    subgraph Access["HOST AND ACCESS"]
        Proxmox["Proxmox VE<br/>One physical host"]
        Admin["Administrator<br/>SSH bastion access"]
        Gateway["OPNsense gateway<br/>Isolated vmbr1 network"]
        Proxmox --> Gateway
        Admin --> Gateway
    end
    subgraph Platform["RUN THE PLATFORM · THREE VMs ON ONE HOST"]
        VIP["Kubernetes API VIP<br/>10.20.0.110:6443"]
        Cluster["Three K3s server VMs<br/>Control plane + embedded etcd"]
        Argo["Argo CD<br/>Manual GitOps reconciliation"]
        Services["Runtime services<br/>Traefik + WebDemo"]
        Observe["Observability<br/>Prometheus + Grafana + alerts"]
        VIP --> Cluster
        Cluster --> Argo
        Argo -->|WebDemo delivery| Services
        Cluster --> Services
        Cluster --> Observe
    end
    subgraph Recovery["PRESERVE RECOVERY DATA · OFF-SERVER"]
        Backup["Unraid NFS recovery storage<br/>Etcd snapshots + protected token"]
    end
    Automation --> Proxmox
    Gateway --> VIP
    Git -.->|Application manifests| Argo
    Cluster --> Backup
    classDef blue fill:#243b53,stroke:#7ba7d1,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef green fill:#234338,stroke:#7cb99a,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef purple fill:#39304d,stroke:#b49bd4,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef gray fill:#293241,stroke:#a9b8c8,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef amber fill:#4a3b24,stroke:#d7b77b,color:#e2e8f0,stroke-width:2px,font-size:20px
    class Git,CI,Automation,Argo blue
    class Proxmox,Admin,Gateway gray
    class VIP,Cluster,Services,Observe green
    class Backup purple
    style Build fill:#182235,stroke:#64748b,color:#e2e8f0
    style Access fill:#182235,stroke:#64748b,color:#e2e8f0
    style Platform fill:#182235,stroke:#64748b,color:#e2e8f0
    style Recovery fill:#182235,stroke:#64748b,color:#e2e8f0
```

**Blue:** delivery and automation · **Green:** running platform · **Purple:** off-server recovery data · **Gray:** access and network boundaries.

The diagram groups workloads logically. The three K3s VMs share the same physical host; the VIP is owned by one server at a time, not a separate appliance. CI performs static checks and does not deploy to the live lab.

### Node sizing and network design

| Node | VM ID | Address | Role |
|---|---:|---|---|
| `k3s-server-01` | 401 | `10.20.0.101` | Control plane + etcd |
| `k3s-server-02` | 402 | `10.20.0.102` | Control plane + etcd |
| `k3s-server-03` | 403 | `10.20.0.103` | Control plane + etcd |

Each VM uses 4 CPU cores, 6144 MB RAM, a 32 GB disk, Ubuntu 24.04, cloud-init, and the QEMU guest agent. OpenTofu defines stable VM identities, addressing, and startup dependencies.

OPNsense VM 400 provides routing, DHCP, DNS forwarding, and outbound NAT. `vmbr0` carries management and OPNsense WAN traffic; `vmbr1` is the isolated lab bridge. No upstream-router changes or physical uplink on the isolated bridge are required.

[Provisioning and network implementation](proxmox/opentofu/environments/k3s/README.md)


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
flowchart TB
    subgraph Baseline["ESTABLISH THE BASELINE"]
        Before["Server 02 owns the API VIP"]
    end
    subgraph Exercise["TRIGGER A CONTROLLED FAILURE"]
        Action["Delete the leader pod<br/>Continue API probes through the VIP"]
    end
    subgraph Handoff["OBSERVE RECOVERY"]
        Move["VIP ownership moves<br/>Server 02 → server 03"]
        Replace["Replacement pod starts<br/>On server 02"]
    end
    subgraph Result["VERIFY THE RESULT"]
        Healthy["3 kube-vip pods running<br/>3 nodes Ready<br/>No failed API probes recorded"]
    end
    Before --> Action
    Action --> Move
    Action --> Replace
    Move --> Healthy
    Replace --> Healthy
    classDef blue fill:#243b53,stroke:#7ba7d1,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef green fill:#234338,stroke:#7cb99a,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef purple fill:#39304d,stroke:#b49bd4,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef gray fill:#293241,stroke:#a9b8c8,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef amber fill:#4a3b24,stroke:#d7b77b,color:#e2e8f0,stroke-width:2px,font-size:20px
    class Before blue
    class Action amber
    class Move,Replace,Healthy green
    style Baseline fill:#182235,stroke:#64748b,color:#e2e8f0
    style Exercise fill:#182235,stroke:#64748b,color:#e2e8f0
    style Handoff fill:#182235,stroke:#64748b,color:#e2e8f0
    style Result fill:#182235,stroke:#64748b,color:#e2e8f0
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
| Supervised local AI | [Workflow and review findings](docs/local-ai-workflow.md) · [LM Studio connection](docs/local-ai-connection.md) |
| Read-only backup evidence | [Collector usage, tests, and limits](docs/backup-evidence-collector.md) |
| CI and change history | [Validation workflow](.github/workflows/infrastructure-validation.yml) · [Changelog](CHANGELOG.md) |
| Earlier engineering detail | [Preserved v0.1–v0.7 portfolio record](docs/portfolio-history-through-v0.7.md) |

### Security and operating practices

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
| In progress | Human-supervised local AI assistance with Continue and Hermes | Supervised pilot documented; autonomous operations not validated |

The next-stage ordering is a roadmap, not a release commitment. The supervised AI pilot is documented separately; future operational automation will use an isolated sandbox and human-reviewed, auditable infrastructure changes.

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

> **Proposed design, not deployed evidence.** This connected architecture assigns different tools to operations, repository work, and Kubernetes diagnosis. Model assignments are starting points to test, not measured winners.

```mermaid
flowchart TB
    subgraph Build["BUILD AND DELIVER"]
        Git["Git repository<br/>Infrastructure · manifests · runbooks"]
        CI["GitHub Actions<br/>Static validation only"]
        Deploy["OpenTofu · Ansible · Argo CD<br/>Reviewed delivery"]
        Git --> CI
        Git --> Deploy
    end
    subgraph Lab["RUN THE LAB · ONE PHYSICAL PROXMOX HOST"]
        Network["SSH bastion · OPNsense<br/>Isolated network"]
        K3s["Kubernetes API VIP<br/>Three K3s server VMs + etcd"]
        Apps["Traefik · WebDemo<br/>Proposed: cert-manager + NetworkPolicy"]
        Observe["Prometheus · Grafana · alerts<br/>Proposed: Loki + Headlamp"]
        Network --> K3s
        K3s --> Apps
        K3s --> Observe
    end
    subgraph AI["LOCAL AI WORKSPACE"]
        Desktop["Desktop · LM Studio<br/>2 × RTX 3060 12 GB · 48 GB RAM<br/>One active model · queued tasks"]
        VM["Dedicated Linux agent VM<br/>On the same Proxmox host<br/>Scoped tools and workspaces"]
        Ops["Hermes<br/>Health reports · backup checks · triage"]
        Code["Continue / OpenCode<br/>Repository edits · checks · documentation"]
        Diagnose["K8sGPT<br/>Kubernetes diagnosis"]
        Prime["Optional Prime Agent trial<br/>Longer investigations"]
        Desktop <-->|Model API| VM
        VM --> Ops
        VM --> Code
        VM --> Diagnose
        VM -.-> Prime
    end
    subgraph Recovery["PRESERVE AND RECOVER · UNRAID"]
        Data["Shared application storage<br/>Separate volume backups"]
        Snapshots["Etcd snapshots<br/>Protected token"]
        Records["Agent reports<br/>Evidence and handoffs"]
    end
    Restore["Isolated restore drill<br/>On-demand Proxmox workspace<br/>Cluster + application data"]
    Review["Lee reviews<br/>Evidence · proposed fix · code diff"]
    Verify["Verify results<br/>Save tests and portfolio evidence"]
    Deploy --> Network
    Observe -.->|Read evidence| Ops
    K3s -.->|Scoped inspection| Diagnose
    Git -.->|Repository context| Code
    Apps --> Data
    K3s --> Snapshots
    Data --> Restore
    Snapshots --> Restore
    Ops --> Records
    Diagnose --> Records
    Records --> Review
    Code --> Review
    Prime -.-> Review
    Review -->|Approved change| Git
    Deploy --> Verify
    Verify --> Records
    classDef blue fill:#243b53,stroke:#7ba7d1,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef green fill:#234338,stroke:#7cb99a,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef purple fill:#39304d,stroke:#b49bd4,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef gray fill:#293241,stroke:#a9b8c8,color:#e2e8f0,stroke-width:2px,font-size:20px
    classDef amber fill:#4a3b24,stroke:#d7b77b,color:#e2e8f0,stroke-width:2px,font-size:20px
    class Git,CI,Deploy blue
    class K3s,Apps,Observe,Verify green
    class Data,Snapshots,Records,Restore purple
    class Network,Review gray
    class Desktop,VM,Ops,Code,Diagnose,Prime amber
    style Build fill:#182235,stroke:#64748b,color:#e2e8f0
    style Lab fill:#182235,stroke:#64748b,color:#e2e8f0
    style AI fill:#182235,stroke:#64748b,color:#e2e8f0
    style Recovery fill:#182235,stroke:#64748b,color:#e2e8f0
```

**Blue:** delivery and automation · **Green:** running platform · **Purple:** storage and recovery · **Gray:** access, network boundaries, and review · **Amber:** AI tools and local inference.

The connections show logical responsibilities and evidence flow. Hermes handles recurring operations and reporting; Continue and OpenCode assist with repository changes; K8sGPT provides specialized cluster diagnosis. Prime Agent is an optional comparison for longer investigations, not a dependency of OpenCode or a required always-on service.

### Agent tasks, model choices, and placement

| Task | Tool to evaluate | Initial model experiment |
|---|---|---|
| Daily health, capacity, and backup-freshness report | **Hermes Agent** | Qwen3.5-9B |
| Investigate events, logs, and incidents | **Hermes Agent** | Qwen3.5-27B for harder cases |
| DNS, TLS, endpoint, and firewall inspection | **Hermes Agent** with scoped commands | 9B summaries; 27B for difficult cases |
| Prepare Ansible, OpenTofu, and Kubernetes changes | **Continue / OpenCode** | The locally available Qwen Coder model |
| Explain unhealthy Kubernetes resources | **K8sGPT** | Test a supported local backend; verify the exact LM Studio connection |
| Longer repository investigations | **Prime Agent**, optional | Qwen Coder or 27B, evaluated on the same task |
| Runbook updates, handoffs, and evidence summaries | **Hermes Agent** | Qwen3.5-9B |

**Proxmox:** the existing infrastructure and K3s VMs, plus one dedicated Linux agent VM. General-purpose agents stay outside the cluster so they can investigate it when it is unhealthy. Run coding experiments and restore drills on demand.

**Desktop:** LM Studio serves local models on two RTX 3060 GPUs with 12 GB VRAM each; the desktop has 48 GB system RAM. Begin with one active model and queued tasks; validate model fit, context, speed, and tool use before adding concurrency.

**Unraid:** application storage, independent recovery artifacts, and durable agent reports and handoffs.

**K3s additions to evaluate:** Headlamp for a Kubernetes dashboard; cert-manager for certificate automation; Loki for logs; tested NetworkPolicies for scoped pod access. K8sGPT starts as a CLI on the agent VM; its operator is a later optional cluster experiment. These are proposed additions, not claims about the current cluster.

**Review path:** agents collect evidence and prepare fixes. Lee reviews changes before the appropriate infrastructure or application delivery process. GitHub Actions stays static validation only.

**Completed-state targets:** shared application storage and volume recovery tested; full isolated etcd restore validated; outbound notifications delivered and tested; network access rules verified; agent workflows evaluated on real lab tasks; reviewed changes and evidence preserved.

**Selection test:** compare agents with the same model on a broken-pod diagnosis, backup-freshness report, and small Ansible fix in a test branch. Check correct tool use, evidence quality, completion, elapsed time, and needed intervention.

Sources: [Hermes](https://hermes-agent.nousresearch.com/docs/) · [OpenCode](https://opencode.ai/v2/docs/providers) · [K8sGPT](https://github.com/k8sgpt-ai/k8sgpt) · [Prime Agent](https://github.com/PrimeIntellect-ai/prime-agent) · [Headlamp](https://kubernetes-sigs.github.io/headlamp/) · [K3s networking](https://docs.k3s.io/networking)

The three K3s servers and agent VM still share one physical host. GPU inference requires the desktop endpoint to be available. Full recovery, new networking controls, and local agent performance must be validated before they appear as deployed portfolio evidence.


