# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Argo CD v3.5.3 installation manifests and a WebDemo Application tracking `main`.
- [Argo CD validation record with preserved command output](kubernetes/argocd/README.md) for manual sync, replica-drift detection, and controlled reconciliation.

### Changed

- Removed the external AI-hosted portfolio promotion; the repository README remains the portfolio entry point.
- Updated the landing page to distinguish implemented Argo CD work from the latest published release, v0.8.0.

### Validated

- The documented live exercise confirmed seven Argo CD pods Ready and WebDemo Synced and Healthy after manual sync.
- Scaling live replicas from three to four produced an OutOfSync Deployment; manual reconciliation restored 3/3 Ready and available replicas.

### Known limitations

- Automated sync, self-heal, and automatic pruning are disabled; automatic self-healing and continuous HTTP availability were not tested.
- Argo CD is a non-HA, manually bootstrapped installation on the existing single-physical-host lab.
- These changes are not yet published as v0.9.0. Full etcd restore remains incomplete.

## [0.8.0](https://github.com/Capasiter/homelab-portfolio/releases/tag/v0.8.0) - 2026-09-20

### Added

- An Ansible-managed kube-vip DaemonSet, RBAC manifest, defaults, rendering checks, and runtime validation.
- Internal API VIP `10.20.0.110` and K3s TLS SAN configuration.
- [Live validation report](ansible/docs/k3s-api-vip-validation.md) covering the September 19, 2026 leader-pod failover exercise.
- A redesigned portfolio landing page with architecture and failover diagrams, evidence links, and explicit delivered/planned status.
- A [historical portfolio record](docs/portfolio-history-through-v0.7.md) retaining the earlier detailed engineering write-ups.

### Validated

- All three kube-vip pods Running and all three K3s nodes Ready through the VIP.
- VIP present in the inspected API certificate's SANs.
- VIP ownership moved from server 02 to server 03 following deletion of the leader pod; a replacement pod ran on server 02.
- No failed API probes found in the recorded test log; request latency and a downtime bound were not measured.

### Known limitations

- The exercise covered a controlled kube-vip pod deletion, not node power loss or physical-host failure.
- Probes were sampled and had no explicit request deadline; zero downtime is not claimed.
- Application availability was not measured during the VIP test.
- Three control-plane VMs share one physical Proxmox host.

## [0.7.0](https://github.com/Capasiter/homelab-portfolio/releases/tag/v0.7.0)

This entry backfills the delivered milestone from the existing portfolio record. The release date is omitted rather than inferred.

### Added

- Ansible-managed off-server K3s etcd backups to Unraid NFS storage.
- Daily systemd scheduling, a protected baseline, and retention of the three newest rolling backups.
- SHA-256 sidecars and verification for snapshot and protected server-token backups.

### Fixed

- Backup-artifact ownership through a scoped NFS export configuration for the trusted backup client.
- Stale checksum-file ownership by using atomic write-then-rename handling.

### Validated

- Off-server storage access, successful on-demand backup execution, checksum verification, and retention.
- Protected token backup and active daily scheduling.
- Snapshot integrity and decompression during an isolated restore attempt using K3s `v1.36.2+k3s1`.

### Known limitations

- Full etcd restore was not completed: the documented standalone reset/restore attempt encountered a reproducible panic in the K3s reset path.
- Etcd backups do not include application persistent-volume contents.
- The NFS export's scoped `no_root_squash` setting is a deliberate lab tradeoff, not a general production default.

## [0.6.0](https://github.com/Capasiter/homelab-portfolio/releases/tag/v0.6.0) - 2026-08-23

### Added

- Version-pinned `kube-prometheus-stack` chart `88.3.0` configuration with Prometheus Operator `v0.93.0`, Prometheus, Grafana, Alertmanager, kube-state-metrics, and node-exporter.
- Resource requests and limits, seven-day Prometheus retention, and persistent K3s local-path storage for Prometheus, Grafana, and Alertmanager.
- Initial live-validation evidence covering pod readiness, restart state, persistent volumes, resource usage, scrape health, and `web-demo` replica state.
- GitHub Actions validation that installs Helm `v4.2.4` and renders the pinned monitoring configuration without accessing the live cluster.
- A hardened `prom/blackbox-exporter:v0.28.0` ConfigMap, Deployment, and ClusterIP Service with health checks and explicit resource controls.
- A Prometheus Operator `Probe` for 30-second HTTP 2xx checks and a `PrometheusRule` containing the `WebDemoUnavailable` alert with a one-minute firing hold.

### Changed

- Disabled monitoring and default rules for loopback-only K3s controller-manager, scheduler, kube-proxy, and etcd metrics endpoints to prevent unreachable targets and false alerts.
- Updated portfolio documentation for the completed v0.6.0 observability milestone.

### Validated

- [GitHub Actions run 20](https://github.com/Capasiter/homelab-portfolio/actions/runs/32668970647) passed OpenTofu, Ansible, and Kubernetes observability validation, including pinned Helm rendering and manifest validation without cluster credentials.
- A controlled scale-to-zero test changed `probe_http_status_code` from `200` to `0` and `probe_success` from `1` to `0`; `WebDemoUnavailable` transitioned from inactive to pending to firing while its rule remained healthy.
- Restoring `web-demo` to three replicas returned the Deployment to 3/3 Ready and available, restored `probe_success` to `1`, cleared the alert to inactive, and left one Ready pod on each K3s server with zero restarts.
- Both repository manifests matched the live cluster with no `kubectl diff` output.

### Security

- Ran the exporter as UID/GID 65534 with a read-only root filesystem, all capabilities dropped, and service-account token automount disabled.
- Kept Grafana credentials, Kubernetes Secrets, tokens, and kubeconfig contents outside version control.

### Known Limitations

- Alertmanager notification delivery and human acknowledgement were not validated.
- The exporter remains a single replica, and the exercise did not cover partial replica loss, node failure, network failure, slow responses, or intermittent errors.

## [0.5.0] - 2026-08-16

### Added

- Version-controlled Kubernetes Namespace, three-replica Deployment, ClusterIP Service, and Traefik Ingress for the `web-demo` workload.
- Explicit rollout protections with an HTTP readiness probe, `minReadySeconds: 5`, `maxUnavailable: 0`, `maxSurge: 1`, and a 10-second `preStop` drain window.
- A rolling-update reliability lab documenting the initial client-visible timeout, diagnosis, corrective configuration, and live-traffic testing.

### Changed

- Advanced the portfolio from K3s platform deployment to operating and validating an application workload under live traffic.
- Updated milestone, technology, engineering-practice, and roadmap documentation for v0.5.0.

### Validated

- The complete workload manifest passed server-side dry-run validation against the live K3s API.
- The initial rolling restart completed successfully in Kubernetes but produced one client-visible timeout.
- The protected rollout observed 148 successful requests with 0 failures.
- A separate August 15 revalidation observed 120 successful requests with 0 failures and returned the Deployment to 3/3 Ready and available, with one pod on each K3s server.

### Known Limitations

- Testing used short HTTP requests from inside the isolated network and did not cover long-lived connections, TLS, unexpected node failure, or network failure.

## [0.4.0] - 2026-07-26

### Added

- OpenTofu-managed three-VM Ubuntu environment on an isolated OPNsense network for the K3s control plane.
- Deterministic VM identities, reserved addresses, dependency-aware startup, guest-agent integration, and serial-console recovery.
- Restricted OpenSSH bastion path for managing servers that are not directly reachable from the automation controller.
- `k3s_cluster.yml` playbook and reusable `k3s_server` role for preflight validation, prerequisites, configuration, installation, and runtime checks.
- Explicit bootstrap and sequential-join inventory groups for the three K3s servers.
- Live cluster validation report covering health, networking, security controls, snapshots, and idempotence.

### Changed

- Expanded GitHub Actions validation to syntax-check the K3s playbook.
- Corrected runtime validation to require the current `control-plane` and `etcd` labels instead of the obsolete `master` label.
- Updated portfolio and Ansible documentation from pre-installation status to the validated live deployment.
- Documented delivered capabilities separately from remaining production-oriented improvements.

### Security

- Pinned the K3s installer to an immutable Git commit and verified installer and binary SHA-256 checksums.
- Protected root-owned K3s configuration and token files with mode `0600`.
- Suppressed sensitive token operations with `no_log`, disabled token-file diffs, and transferred the bootstrap token through a non-cacheable in-memory Ansible fact.
- Enabled Kubernetes Secrets encryption and validated matching encryption hashes across all servers.
- Kept live inventory, private keys, tokens, kubeconfig contents, and infrastructure credentials out of Git and public CI.

### Validated

- All three servers reported `Ready` on K3s `v1.36.2+k3s1` with `control-plane` and `etcd` roles.
- Kubernetes API readiness, embedded-etcd readiness, server membership, and Secrets encryption passed.
- Cross-node scheduling, Flannel networking, Service routing, and CoreDNS resolution passed.
- Metrics Server, Traefik, ServiceLB, Local Path Provisioner, and the default StorageClass were healthy.
- Local etcd snapshot creation completed successfully.
- A complete Ansible rerun converged with `changed=0`, `failed=0`, and `unreachable=0` on every server.
- OpenTofu reconciliation and both GitHub Actions validation jobs passed.

### Known Limitations

- Kubernetes API access does not yet use a virtual IP or external load balancer.
- The validated etcd snapshot is local-only, and a restore exercise has not yet been completed.
- Local Path Provisioner storage is node-local; shared Unraid-backed persistent storage is not yet integrated.
- Monitoring, alerting, NetworkPolicy, GitOps, and application workloads remain future milestones.

## [0.3.0] - 2026-07-18

### Added

- GitHub Actions workflow with independent OpenTofu and Ansible validation jobs.
- Automated OpenTofu formatting, backend-disabled initialization, and configuration validation.
- Automated sanitized-inventory parsing, playbook syntax checking, and production-profile Ansible linting.
- Validation on pull requests and pushes to the `main` branch.

### Changed

- Renamed the sanitized inventory from `hosts.yml.example` to `hosts.example.yml` so Ansible recognizes it as YAML.
- Updated Ansible documentation to use the parseable example-inventory filename.

### Security

- Restricted workflow permissions to read-only repository contents.
- Kept Proxmox credentials, SSH keys, live inventory, state, plans, and live-host connections out of CI.
- Prevented public CI from running OpenTofu `plan` or `apply`.

## [0.2.0] - 2026-07-18

### Added

- Role-based Ansible Linux baseline for the OpenTofu-provisioned Ubuntu container.
- Repository-scoped Ansible configuration, structured inventory, reusable role, and deployment playbook.
- Automated administration-package installation and timezone configuration.
- SSH hardening with configuration validation before service restart.
- Sanitized example inventory and live-validation documentation.

### Changed

- Updated the portfolio landing page to show live-validated Ansible configuration management.
- Advanced the project roadmap to automated CI validation and future K3s infrastructure.

### Security

- Added a dedicated password-locked automation account using ED25519 key authentication and controlled sudo escalation.
- Disabled SSH password authentication, keyboard-interactive authentication, and direct root login.
- Excluded live inventory, private keys, vault-password files, and retry files from version control.

## [0.1.0] - 2026-07-18

### Added

- Reusable OpenTofu module for provisioning Ubuntu LXC containers on Proxmox VE.
- Development environment with configurable compute, storage, networking, and container settings.
- Input validation, documented outputs, and pinned provider requirements.
- Live Ubuntu 24.04 LXC deployment with two CPU cores, 3072 MB memory, 512 MB swap, and a 16 GB disk.
- Runtime verification for container identity, resource allocation, networking, start-on-boot behavior, unprivileged operation, and nesting.
- Live-validation report documenting the deployed stack, validation results, API troubleshooting, security controls, and current limitations.
- Sanitized example configuration containing all required inputs.
- Project and module documentation for setup, structure, requirements, security, and future work.

### Changed

- Updated the portfolio landing page to reflect the live-validated OpenTofu deployment.
- Replaced the outdated OpenTofu project status and workflow documentation.
- Expanded `.gitignore` coverage for local variables, state, saved plans, provider data, logs, override files, and CLI configuration.

### Security

- Kept real API credentials, local variable files, state, and provider data out of version control.
- Used a dedicated Proxmox service identity and API token for automation.
- Documented the distinction between authentication failures (`401`) and authorization failures (`403`).
- Revoked and replaced a previously exposed development API token.
