# homelab-portfolio

# Multi-Node Hybrid Homelab & Infrastructure Portfolio

Welcome to my homelab environment documentation. This repository outlines the architecture, configuration, and management of a multi-node, hybrid virtualized infrastructure. I utilize this environment to simulate enterprise IT workflows, test cross-platform operating systems, explore Infrastructure as Code (IaC), container orchestration, and secure networking.

---

## 🛠️ Infrastructure Architecture & Tech Stack

Across my environment, I manage a decentralized storage pool of **30TB (HDD & NVMe array)** across dedicated hypervisors, container stacks, and automated testing nodes.

### 1. Compute & Virtualization Nodes

| Node Name / Role | Hardware Specs | Operating System / Hypervisor | Key Workloads / Services |
| :--- | :--- | :--- | :--- |
| **Node 01: Core Storage & Compute** | Intel i7-11700K (11th Gen), 64GB RAM, NVIDIA RTX 3060 | **Unraid (Bare-Metal)** | SMB Shares, Portainer, Core Docker Stacks, Multi-OS VM Testing |
| **Node 02: Dedicated Microservices** | Intel i9-9900K, 16GB RAM, NVIDIA GTX 1060 | **Proxmox VE (Bare-Metal)** | Portainer Stacks, Uptime Kuma, Infrastructure Monitoring, LXC Containment |
| **Node 03: Engineering & Testing** | Intel i5-12600KF (12th Gen), 32GB RAM, NVIDIA RTX 3060 | **Windows 11 / WSL2** | Local Dev Environment, Podman, Docker Desktop, Network Gateway Testing |

### 2. Networking & Edge Infrastructure
* **Core Switch:** Netgear GS108Tv3 (Layer 2+ Managed Switch)
  * *Skills demonstrated:* Managed switching, VLAN segmentation capability, traffic prioritization.
* **Edge Gateway:** Zyxel C3000Z 
* **Secure Remote Access & Overlay Networking:** **Tailscale Mesh VPN** deployed across endpoints (Unraid, Dev Environment) for secure, zero-trust remote management without exposing vulnerable ports to the public internet.

---

## 📦 Containerization & Application Directory

I leverage microservices architectures to isolate applications, optimize system resources, and ensure high availability.

* **Core Networking & Security:** 
  * `Pi-hole`: Network-wide DNS sinkhole for ad-blocking and localized DNS management.
  * `ClamAV`: Automated open-source antivirus engine scanning storage layers.
* **DevOps, Automation & Infrastructure:**
  * `Terraform`: Utilized for Infrastructure as Code (IaC) execution, automating the deployment and provisioning of Ubuntu LXC containers.
  * `Uptime Kuma`: Real-time monitoring and alerting dashboard tracking node and service availability.
  * `Speedtest Tracker`: Automated internet performance auditing and logging.
  * `Portainer`: Centralized GUI container management deployed across Unraid and Proxmox nodes.
  * `Code-Server`: Browser-based VS Code instance for remote environment configuration and script editing.
* **Artificial Intelligence (AI) / ML Testing:**
  * `Ollama`: Local deployment of open-source Large Language Models (LLMs) leveraging dedicated GPU hardware acceleration.
* **Home Automation & Media:**
  * `HomeAssistant`: Centralized hub for IoT device integration and automated network triggers.
  * `BOINC`, `ChannelTube`, `Wreckfest / BeamNG dedicated game servers` (testing GPU pass-through capabilities and high-utilization network hosting).

---

## 🖥️ Cross-Platform Virtualization & OS Testing
Because this infrastructure boasts significant memory resources (including 64GB on Node 01), I actively maintain and provision a diverse catalog of Virtual Machines (VMs) and Linux Containers (LXCs) to simulate multi-platform client/server enterprise environments:

* **Enterprise Linux:** Ubuntu, Ubuntu Live, Fedora Desktop, DragonOS (SDR/RF focused Linux).
* **Windows Ecosystem:** Windows XP, Windows 7, Windows 8.1, Windows 10, Windows 11 (Legacy software testing, Active Directory environment preparation).
* **UNIX / Specialized OS:** macOS Sequoia testing environments, Commodore 64 emulation.

---

## 🔧 Core Competencies Demonstrated

* **Hypervisor Administration:** Hands-on management of Type-1 (Proxmox VE) and Type-2/Hybrid (Unraid KVM, Windows WSL2) virtualization platforms.
* **Infrastructure as Code (IaC):** Writing declarative configurations using **Terraform** to rapidly spin up and tear down Linux instances.
* **Container Orchestration:** Managing decoupled applications using **Docker, Docker Desktop, Podman,** and **Portainer**.
* **Storage Architecture:** Implementing robust network storage with SMB file shares across 30TB of mixed hard drive and high-speed NVMe flash media arrays.
---

## 🛠️ Deep-Dive Project Spotlights & Engineering Logs (June 2026 Sprint)

### 🚀 Project 1: Multi-Node Configuration Management & Continuous Deployment (CD) Pipeline
* **Objective:** Transition the multi-node lab environment from manual machine provisioning to a centralized, enterprise-grade automated pipeline.
* **The Solution:** Engineered a centralized **Ansible Control Plane** running inside an Ubuntu instance on Windows Subsystem for Linux (WSL2). Generated an asymmetric SSH keypair to establish passwordless, agentless `root` administrative access across all physical and virtual nodes.
* **The Implementation:** 1. Built a **Proxmox "Golden Image" Template** using the official minimal Ubuntu Cloud-Init image. Configured a virtual serial display, injected public keys, and enabled the `QEMU Guest Agent` interface.
  2. Mapped out a static environment inventory (`hosts.ini`) leveraging Ansible group scopes (`proxmox_nodes`, `storage_servers`, `app_servers`).
  3. Structured and successfully executed automated playbooks for core OS hardening/patching (`system_prep.yml`), Docker engine daemon configuration (`install_docker.yml`), and Portainer infrastructure federation agent deployment (`deploy_agent.yml`).

### 🛡️ Project 2: Disaster Recovery Infrastructure (Proxmox Backup Server Deployment)
* **Objective:** Establish a high-integrity, automated backup and recovery environment featuring data deduplication and incremental snapshots.
* **The Solution:** Nuked a corrupted Docker LXC container locked in read-only filesystem purgatory to clear the pool. Spun up a dedicated **Proxmox Backup Server (PBS)** instance as a Virtual Machine.
* **Storage Pipeline:** Passed un-cached storage arrays directly from the Unraid storage tier into the PBS virtual instance using the high-performance `virtiofs` mounting protocol.
* **Result:** Successfully authorized and authenticated the PBS node with the primary Proxmox cluster, establishing a unified, green-status backup safety net. Additionally shared the master ISO library across nodes via optimized **NFS network mounts** to eliminate duplicate data allocation.

---

## 🧠 Technical Case Studies (Real-World Troubleshooting)

### Case Study 1: Resolving Upstream Go-Runtime Network Name Resolution Failures
* **Symptom:** Upstream Go-compiled binaries (specifically the Docker Engine Daemon) suddenly entered a handshake failure loop when attempting to contact `registry-1.docker.io`, completely bypassing native Linux address sorting rules configured in `/etc/gai.conf`.
* **Root Cause Analysis:** Discovered that Go’s native, internal pure-Go name resolver ignores system local RFC 3484 configuration files by design, triggering failed IPv6 connection handshakes on an IPv4-prioritized network.
* **Remediation Strategy:** Implemented a persistent Systemd service override inside `/etc/systemd/system/docker.service.d/override.conf`. Injected the environmental runtime flag `GODEBUG="netdns=cgo"`, forcing the Docker daemon runtime to drop the Go resolver and use the host's native GNU C Library (`glibc`) resolver instead. Adherence to system-wide IPv4 prioritization was instantly restored.

### Case Study 2: Watchtower Automation Container Engine Socket Mismatch
* **Symptom:** The lifecycle automation container (`Watchtower`) entered an infinite crash loop throwing `Exit Code 1: client version 1.25 is too old. Minimum supported API version is 1.40`.
* **Root Cause:** Upstream Docker Engine upgrades on the host system enforced stricter API contract enforcement, deprecating legacy handshakes. Watchtower defaulted back to a legacy client protocol.
* **Remediation Strategy:** Restructured the container orchestration deployment block to explicitly inject the environment parameter `DOCKER_API_VERSION=1.40`. This forced strict API protocol negotiation compliance across the Unix socket interface (`/var/run/docker.sock`), immediately restoring zero-touch image patching workflows without requiring host engine downgrades.

---

## 🔒 Advanced Architectural Paradigms Mastered

* **Nested Containerization (`nesting=1`):** Configured secondary container runtime engines (Docker/containerd) inside OS-level Linux Containers (LXC). Bypassed standard kernel-space restrictions on `sys_admin` capabilities within the Linux namespace, allowing the guest container to safely mount internal overlay filesystems while preserving critical user namespace isolation (Unprivileged mode).
* **Automated Image Lifecycle Management:** Implemented detached daemon arrays (`Watchtower`) paired with real-time log aggregation engines (`Dozzle`). Attached directly to local Unix sockets to establish a zero-storage log streaming pipeline, completely eliminating the need to use interactive terminal SSH access during standard maintenance windows.
* **Network Discovery via MAC Signatures:** Bypassed private consumer router DHCP tracking limitations by logging into the core Proxmox bridge (`vmbr0`) and running low-level network discovery (`arp-scan`). Isolated newly deployed cloud instances using the explicit Proxmox hardware MAC address prefix signature (`bc:24:11`) to accurately hunt down blind network allocations.

---

## 🎮 Game Server Infrastructure Deployment Logs

### 🚀 Project 3: Containerized Multi-User Simulation Environment (Wreckfest 2)
* **Objective:** Deploy and stabilize a high-performance, containerized dedicated multiplayer environment for Wreckfest 2 (Steam App ID: 3519390).
* **The Architecture:** Orchestrated via Docker Engine and managed through the Pelican Panel administrative interface, hosted inside an Ubuntu Linux VM (Node 200) running on a bare-metal Intel Core i9 Proxmox VE hypervisor. Integrated a Wine translation layer for seamless Windows-on-Linux runtime execution.

### 🧠 Post-Mortem & Advanced Troubleshooting

#### 1. Hypervisor CPU Instruction Set Incompatibility (AVX/AVX2 Bypass)
* **Symptom:** The dedicated game server executable crashed immediately upon initial runtime initialization, throwing fatal `Unhandled illegal instruction` errors via the Wine translation layer.
* **Root Cause Analysis:** The Proxmox Virtual Machine defaulted to the standard virtual CPU type (`kvm64`). This legacy configuration strips away modern, advanced vector instruction sets (specifically AVX/AVX2 execution flags) required by modern gaming and compilation engines.
* **Remediation Strategy:** Hard-stopped the virtual node, navigated to the Proxmox Hardware Configuration panel, and upgraded the processor type topology from `kvm64` to `host`. This directly exposes the raw Intel Core i9 processor hardware flags to the guest OS, completely mitigating the instruction set conflict.

#### 2. Storage Subsystem I/O Throttle & Disk Write Bottlenecks
* **Symptom:** During heavy extraction and asset verification phases, SteamCMD download pipelines choked down to single-digit KB/s throughput while triggering persistent `[slow disk]` hardware fault flags.
* **Root Cause Analysis:** The underlying Proxmox virtual disk controller was provisioned with standard synchronized write behavior (`No Cache`). Under massive continuous parallel write loops, the hypervisor forced an immediate physical host disk commit for every block change, obliterating storage IOPS performance.
* **Remediation Strategy:** Expanded the storage pool allocation to eliminate capacity degradation. Modified the VM drive hardware profile to utilize the high-throughput **VirtIO SCSI** controller, explicitly setting the caching mechanism to **`Write back`**. This safely delegated disk synchronization buffers directly to system RAM pools, removing the physical disk access bottleneck.

#### 3. Administrative Session Token Masking (SteamCMD / Family View Lockdown)
* **Symptom:** SteamCMD configuration handshakes failed to fetch app manifests, throwing explicit credential authorization and permission errors despite verified MFA/Steam Guard bypass authentication.
* **Root Cause Analysis:** Active Steam Family View restrictions were masking the account profile backend, silently dropping API registration keys, token handshakes, and developer portal communication paths.
* **Remediation Strategy:** Executed an isolated web session inside an incognito browser runtime to drop corrupted local storage tokens. Successfully passed the 4-digit administrative PIN to transition the profile status to an unlocked state, unblocking the Steam Master Server communication handshakes.

### 🌐 Live Production Target Profile
* **Ingress Mapping:** Managed via UPnP/Static Port Forwarding configurations binding port `30100` (UDP Protocol) across the WAN.
* **Internal Routing Vector:** `192.168.0.187:30100`
* **Access Control Matrix:** Open Public Authentication mapping dynamic server-side AI bot population routines to optimize player tracking loops.
