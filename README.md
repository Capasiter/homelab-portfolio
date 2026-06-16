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
