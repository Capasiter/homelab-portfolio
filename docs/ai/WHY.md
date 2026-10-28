# AI Why-Notebook — homelab-portfolio

> **Purpose:** the running explanation of *why* — for Lee (this is also his learning vehicle) and for
> any future reader. It has two halves: **A. Operating principles** (why we work this way) and
> **B. Technical why** (why each capability matters to an employer).
>
> **Status:** FINAL (reconciled 2026-10-25). Part of the shared brain; read via `INDEX.md`.
>
> **How to use:** read the principle before doing the task. If a rule feels arbitrary, the "why" here
> is the answer. Add a line when a new "why" comes up.

---

## A. Operating principles (why we work this way)

### A1. Evidence before claims
**Rule:** label every conclusion `LIVE / CI / DOC / INFER`; a "pass" needs command + output + exit code.
**Why:** this is a job portfolio. A recruiter or interviewer can ask *"how do you know?"* The difference
between a senior and a junior answer is exactly this: the senior shows the evidence, the junior asserts.
Confident-but-unverified claims are what make a project look "half-finished."

### A2. Read-only on live infra by default
**Rule:** no writes to the cluster / Unraid / Proxmox / firewall / GitHub without a specific, explicit go.
**Why:** one accidental `kubectl apply` or `rm` can take down a homelab Lee actually uses. A slow session
is recoverable; a lost cluster is not. "I meant to only inspect" is not a defensible answer to "why is
Prometheus down."

### A3. Secrets never leave the keyboard
**Rule:** passwords/tokens are typed by Lee at the prompt; never pasted, printed, saved, or hashed into
any artifact.
**Why:** this project will be public. A token in a commit, a screenshot, or a handoff is a real breach and a
disqualifying detail on a portfolio. The sidecar checksum already proves integrity — we never need the token.

### A4. One brain, many tools
**Rule:** state lives in `docs/ai/` in the repo; every tool (Bionic, Hermes, Continue) reads it.
**Why:** switching tools kept dropping context. A file the *repo* owns is the only artifact that is (a)
every tool can read, (b) versioned, and (c) survives a tool or session dying. That's the whole point.

### A5. Small steps, repo as source of truth
**Rule:** one concrete action at a time; trust `git` and the files over memory or a summary.
**Why:** small steps are easy to verify and easy to undo. And "the repo" is the thing that's actually true —
notes and chat go stale. Read the file; don't recall it.

### A6. Accuracy over speed — but don't be *needlessly* slow
**Rule:** prefer the correct, verified result; but don't re-derive what the brain already holds.
**Why:** Lee's two complaints are real: he wants accuracy **and** he's frustrated by slowness. The fix isn't
to go fast-and-wrong — it's to stop re-reading context every session (which is what the brain is for).

---

## B. Technical why (why an employer should care)

### B1. Why the etcd backup set is the crown jewel
etcd is K3s' source of truth — **all** cluster state (nodes, deployments, secrets, PVCs) lives in it.
A 1-baseline + 3-rolling set with per-snapshot checksums means "we can prove we can get the cluster back
to a known-good state." That's the difference between "I run K8s" and "I operate K8s." The checksum sidecars
are the proof layer; the retention pattern (baseline + rolling) is the operational pattern.

### B2. Why "full etcd restore" is the #1 SRE interview question
Anyone can set up a backup. The question is: **can you actually restore, and have you done it?** A backup you
have never restored is a *hope*, not a *capability*. The K3s reset-path panic on `v1.36.2+k3s1` is the honest
reason it's still open — and closing it (with an isolated drill + logs) is the single most credible thing in the
whole project.

### B3. Why PVC full-volume backup/restore matters
etcd restore gets you the *metadata* (the PVC object), but **not the bytes** on a local-path or NFS volume.
If a node dies, the data is gone unless you separately back up the volume. Proving `storage-demo-data`
survives a restore is what turns "I made a PVC" into "I understand storage durability."

### B4. Why alert delivery is "teeth"
Prometheus *detects*; Alertmanager *decides*; a receiver like ntfy *delivers*. Without a receiver, you have a
dashboard, not an alerting system. A one-line ntfy route is the minimal honest step from "I can see it" to
"it will page me." It's small, and it's the thing that makes the whole monitoring story real.

### B5. Why GitOps / Argo CD (and why auto-sync is still off)
Argo CD makes the cluster a function of a repo: drift is detected and reconciled. We deliberately kept
auto-sync **off** until we prove the pipeline is safe — turning it on before that would be "automation"
without "control," which is how things go wrong in prod. Turning it on *after* the evidence is the senior move.

### B6. Why a validator is a "production" signal
A checksum validator and a PVC-status validator are small scripts, but they encode a habit: **make correctness
checkable and repeatable**, instead of trusting a one-time manual check. Employers pattern-match on that — it's
the seed of CI, of testing, of "shift left."

---

## C. Open "why" questions (to fill as we learn)
- Why do we keep the baseline snapshot separate from the rolling set? *(draft answer: recovery from different
  points in time; the rolling set ages out, the baseline is the guaranteed floor.)*
- Why ntfy over email/Slack for a homelab? *(draft answer: no server to run, phone-native, trivially revocable.)*
- Why `sudo -n` (non-interactive) on the node? *(draft answer: fail fast instead of hanging on a prompt.)*
