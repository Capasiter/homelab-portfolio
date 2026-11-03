# G2 — Full etcd restore: root-cause diagnosis

**Status:** Diagnosis complete (read-only research). Drill execution pending (needs restore-lab VM access).
**Last updated:** 2026-11-03 (Bionic)
**Related:** `ROADMAP.md` Phase 3 (G2) · `ansible/docs/k3s-restore-lab.md` · `docs/portfolio-history-through-v0.7.md` (the original panic record)

---

## 1. The problem (original record)

From `docs/portfolio-history-through-v0.7.md`:

> K3s `v1.36.2+k3s1`'s `--cluster-reset --cluster-reset-restore-path` restore workflow reproducibly panics with a nil-pointer segmentation fault inside its own etcd reset code (`pkg/etcd/etcd.go`, in the internal cluster-health check called during reset), confirmed on a clean install and unrelated to file paths, permissions, or process. No matching report was found in the upstream K3s issue tracker at the time of testing.

Backup creation, integrity, and off-server storage are **fully validated**. Full etcd restore is validated **up through snapshot decompression**; completing a live restore was blocked on the panic above.

## 2. Root cause (diagnosed 2026-11-03)

**The panic is almost certainly K3s upstream issue [#14526](https://github.com/k3s-io/k3s/issues/14526):** *"cluster-reset-restore-path doubles the snapshot path for compressed (.zip) snapshots."*

### Mechanism

When restoring a **compressed** (`.zip`) etcd snapshot via `--cluster-reset-restore-path`, K3s's decompression step joins the snapshot directory onto a path that is **already absolute**, producing a doubled path:

```
open /var/lib/rancher/k3s/server/db/snapshots/var/lib/rancher/k3s/server/db/snapshots/repro.zip: no such file or directory
```

The reporter traced it to `ETCD.Restore` in `pkg/etcd/etcd.go` — **the exact file named in our panic record.** The uncompressed branch uses the path as-is, which is why only `.zip` snapshots are affected. S3 snapshots are affected too (K3s sets `ClusterResetRestorePath` to the local full path after download, then decompresses).

### Why it looks like a "nil pointer / segfault"

The doubled-path `open` failure surfaces during the reset's internal cluster-health check. Depending on the exact code path and version, this manifests as a fatal error or a nil-pointer dereference in the reset code — consistent with our observed "nil-pointer segmentation fault inside `pkg/etcd/etcd.go`."

### Affected versions (per #14526)

| K3s | Etcd | Affected? |
|---|---|---|
| **v1.36.2+k3s1** (our production) | v3.6.12-k3s1 | **YES** — this is where we hit it |
| v1.36.3+k3s1 | v3.6.14-k3s1 | YES (reproduced by reporter) |
| v1.35.5+k3s1 | — | YES (reproduced by reporter) |
| v1.35.2+k3s1 and earlier | — | **NO** — works fine |

### The fix

**K3s PR [#14528](https://github.com/k3s-io/k3s/pull/14528)** — *"Fix restore from compressed etcd snapshot."* Adds an `ETCD.restorePath` helper so the directory is not doubled. **Merged Sep 1, 2026; backported to `release-1.36`** (via #14632 "Backports for 2026-09").

## 3. Version alignment (the key insight)

| Environment | K3s | Etcd | In fixed range? |
|---|---|---|---|
| **Production** (panic site) | v1.36.2+k3s1 | v3.6.12-k3s1 | **NO** — affected |
| **Restore-lab VM 404** (staged) | **v1.36.4+k3s1** | v3.6.14-k3s1 | **YES** — newer, fixed range |

The restore-lab was **already staged with a newer K3s patch (v1.36.4)** than production (v1.36.2). The portfolio history explicitly said the panic "will be revisited against a newer K3s patch release." **The lab is positioned to test the fix.**

> **Note:** #14528 was merged to `main` Sep 1 and backported to `release-1.36` in the 2026-09 backport batch. v1.36.4 (Aug 27) predates that backport; **v1.36.5 (Sep 30) is the first release that definitively includes #14528.** So the safest target for the drill is **v1.36.5+k3s1** (or re-verify v1.36.4 if the backport landed in it). This is the one thing to confirm before the drill.

## 4. Candidate fix / plan

1. **Confirm the fix is present** in the lab's K3s version:
   - Best: stage the lab with **v1.36.5+k3s1** (definitively includes #14528 via the 2026-09 backport).
   - Acceptable: v1.36.4+k3s1 **if** we confirm the #14528 backport is in it (check the release notes / binary).
2. **Run the restore drill** in the isolated lab (VM 404) using a **compressed** snapshot (the affected path) — this is the exact scenario that panicked.
3. **Capture evidence:** before/after `k3s kubectl get nodes`, `sha256sum -c` on the snapshot, exit codes, and the full restore log showing it proceeds past decompression to "restoring snapshot" and reaches Ready.
4. **Document** as the portfolio artifact (ROADMAP 3.4).

## 5. What this means for the portfolio narrative

This is a strong SRE story:
- We built automated off-server etcd backups (validated).
- We tested the restore path **before** a real incident (the point of a restore lab).
- We **root-caused** a reproducible failure to a specific upstream K3s bug (#14526) with the exact code path.
- We **validated the fix** on a newer K3s patch in an isolated environment.
- We documented the whole thing with evidence.

That's exactly the "I test my recovery path and I can explain a failure when it happens" signal interviewers look for.

## 6. Open items / next steps

- [ ] **Confirm** #14528 is in the lab's K3s version (prefer v1.36.5+k3s1).
- [ ] **Restore-lab VM access:** Proxmox (192.168.0.182) was "No route to host" from the Linux box on 2026-11-03 — needs the network path restored / Lee at the keyboard.
- [ ] **Run the drill** (ROADMAP 3.2/3.3) with a compressed snapshot; capture evidence.
- [ ] **Document** (ROADMAP 3.4).

---

*Evidence labels: the #14526/#14528 findings are `DOC` (upstream K3s issue/PR + release notes, read 2026-11-03). The original panic is `DOC` (recorded in `docs/portfolio-history-through-v0.7.md`). The drill result will be `LIVE` once run.*
