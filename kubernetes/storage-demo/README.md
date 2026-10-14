# Unraid-backed storage demo

## Configuration

- Static NFS PV: storage-demo-nfs; PVC: storage-demo-data.
- Export: 192.168.0.102:/mnt/user/k3s-app-data, on Unraid Fast storage.
- NFSv3 over TCP; ReadWriteMany; Retain reclaim policy.
- Declared 1Gi capacity is binding metadata, not an enforced NFS quota.
- Demo container runs as UID 99/GID 100.
- Argo CD uses manual sync from feature/shared-app-storage.
- Export rule: 192.168.0.162(rw,sync,insecure,root_squash).
- All three node connection tests appeared to Unraid as 192.168.0.162.
  This restriction cannot distinguish clients behind that translated address.
- Ansible installs nfs-common through playbooks/k3s_storage_clients.yml.

## Live validation — 2026-10-13

- NFS client installation succeeded on all three K3s nodes.
- Second Ansible run: changed=0, unreachable=0, failed=0 on every node.
- Read-only NFSv3 mount and unmount succeeded on all three nodes.
- Initial mount with the secure export option was denied.
  Adding insecure resolved it, consistent with client-port translation.
- Namespace, PV, PVC, Deployment and Argo Application passed server dry-run.
- Manual Argo sync of commit 5285091 succeeded: Synced and Healthy.
- PVC Bound; Deployment 1/1 available.
- Container confirmed UID 99/GID 100 and wrote persistence-proof.txt.
- Original pod: storage-demo-5df449c886-tvkbb, on k3s-server-03.
- Replacement pod: storage-demo-5df449c886-kctxc, on k3s-server-03.
- File content and SHA-256 matched after pod replacement.

File content: homelab-storage-proof-5285091

SHA-256: 741681964e93ad07f5faba653cccaf87ce1922530efaa82e369961b65ac66958

## Remaining validation

Cross-node pod rescheduling and application-volume backup/restore have not
been tested in this demo. Etcd snapshots do not back up volume contents.
The shared Unraid host remains a storage dependency.

## Cross-node read validation — 2026-10-13

A temporary Pod, storage-demo-reader, mounted the same PVC read-only
on k3s-server-02 while the demo Deployment remained on k3s-server-03.
The reader completed successfully, printed the expected file content,
and returned /data/persistence-proof.txt: OK from sha256sum -c.
This proves cross-node read access, not Deployment rescheduling or recovery.
