# Proxmox OpenTofu Infrastructure

This project manages Proxmox VE resources using OpenTofu.

## Environment

Hypervisor:
- Proxmox VE 9.2

Node:
- pve

Network:
- vmbr0 - Home LAN management network
- vmbr1 - Secondary lab network

## Goals

- Provision LXC containers and VMs through Infrastructure as Code
- Configure systems using Ansible
- Deploy Kubernetes workloads
- Document all infrastructure changes through Git

## Current Resources

Managed by OpenTofu:
- Initial test LXC container (planned)

## Workflow

GitHub
|
OpenTofu
|
Proxmox API
|
Resources
|
Ansible Configuration
