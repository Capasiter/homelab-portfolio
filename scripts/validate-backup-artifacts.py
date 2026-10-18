#!/usr/bin/env python3
"""Offline backup-artifact validator. No backup mounts, SSH, Kubernetes, or secret access."""
import argparse
import json
import os
import re
import stat
import sys

CHECKSUM_RE = re.compile(r"^[0-9a-f]{64}$")
NAME_RE = re.compile(r"^[A-Za-z0-9._-]+$")


class ArtifactError(Exception):
    def __init__(self, check, message, path=None):
        super().__init__(message)
        self.check = check
        self.message = message
        self.path = path


def _check(check, ok, message, path=None):
    if not ok:
        raise ArtifactError(check, message, path)


def _is_regular(path, check):
    try:
        mode = os.lstat(path).st_mode
    except OSError as exc:
        raise ArtifactError(check, f"cannot stat: {exc}", path) from exc
    _check(check, stat.S_ISREG(mode), "not a regular file", path)
    _check(check, not os.path.islink(path), "is a symlink", path)


def _read_text(path, check, limit=65536):
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return handle.read(limit + 1)
    except (OSError, UnicodeDecodeError) as exc:
        raise ArtifactError(check, f"cannot read: {exc}", path) from exc


def _parse_sidecar(path, check, expected_name):
    raw = _read_text(path, check)
    lines = raw.split("\n")
    if raw.endswith("\n"):
        lines.pop()
    if len(lines) != 1:
        raise ArtifactError(check, "sidecar must contain exactly one line", path)
    line = lines[0]
    parts = line.split(None, 1)
    if len(parts) != 2:
        raise ArtifactError(check, "sidecar must be '<sha256>  <name>'", path)
    digest, name = parts
    _check(check, CHECKSUM_RE.fullmatch(digest) is not None,
           "checksum must be 64 lowercase hexadecimal characters", path)
    _check(check, NAME_RE.fullmatch(name) is not None,
           f"sidecar name is malformed: {name!r}", path)
    _check(check, name == expected_name,
           f"sidecar names differ: {name!r} != {expected_name!r}", path)
    _check(check, line == digest + "  " + name,
           "sidecar must use exactly two spaces between fields", path)
    return digest


def _record(check, path, result="pass"):
    return {
        "check": check,
        "path": path,
        "result": result,
    }


def validate_backup_dir(path, host, prefix="k3s-etcd"):
    findings = []
    errors = []

    def fail(check, message, artifact=None):
        findings.append(_record(check, artifact or path, "fail"))
        errors.append(f"{check}: {message}")

    root = os.path.abspath(path)
    if not os.path.isdir(root):
        raise ArtifactError("dir-missing", "backup directory does not exist")

    etcd_dir = os.path.join(root, "etcd", host, "rolling")
    baseline_dir = os.path.join(root, "etcd", host, "baseline")
    token_dir = os.path.join(root, "token", host)

    # --- rolling snapshots: existence and sidecar format only ---
    try:
        entries = sorted(os.listdir(etcd_dir))
    except OSError:
        entries = []
    snapshots = [
        e for e in entries
        if e.startswith(prefix + "-") and e.endswith(".zip")
    ]
    if not snapshots:
        fail("rolling-snapshot-missing",
             f"no {prefix}/*.zip snapshots in {etcd_dir}")
    else:
        for name in snapshots:
            sp = os.path.join(etcd_dir, name)
            sidecar = sp + ".sha256"
            try:
                _is_regular(sp, "snapshot-not-file")
                _is_regular(sidecar, "sidecar-missing")
                _parse_sidecar(sidecar, "sidecar-format", name)
                findings.append(_record("snapshot-ok", sp))
                findings.append(_record("sidecar-ok", sidecar))
            except ArtifactError as exc:
                fail(exc.check, exc.message, exc.path)

    # --- baseline: existence and sidecar format only ---
    try:
        blist = sorted(os.listdir(baseline_dir))
    except OSError:
        blist = []
    baseline_files = [
        e for e in blist
        if e.startswith(prefix + "-") and e.endswith(".zip")
    ]
    if not baseline_files:
        fail("baseline-snapshot-missing",
             f"no {prefix}/*.zip baselines in {baseline_dir}", baseline_dir)
    for name in baseline_files:
        sp = os.path.join(baseline_dir, name)
        sidecar = sp + ".sha256"
        try:
            _is_regular(sp, "snapshot-not-file")
            _is_regular(sidecar, "sidecar-missing")
            _parse_sidecar(sidecar, "sidecar-format", name)
            findings.append(_record("baseline-snapshot-ok", sp))
            findings.append(_record("baseline-sidecar-ok", sidecar))
        except ArtifactError as exc:
            fail(exc.check, exc.message, exc.path)

    # --- token: existence and sidecar format only; never open the token file ---
    try:
        tlist = sorted(os.listdir(token_dir))
    except OSError:
        tlist = []
    token_file = os.path.join(token_dir, "token")
    token_sidecar = os.path.join(token_dir, "token.sha256")
    if "token" not in tlist:
        fail("token-missing", f"token file not found in {token_dir}")
    else:
        try:
            _is_regular(token_file, "token-not-file")
            _is_regular(token_sidecar, "token-sidecar-missing")
            _parse_sidecar(token_sidecar, "token-sidecar-format", "token")
            findings.append(_record("token-ok", token_file))
            findings.append(_record("token-sidecar-ok", token_sidecar))
        except ArtifactError as exc:
            fail(exc.check, exc.message, exc.path)

    return {
        "schema_version": "1",
        "backup_dir": root,
        "host": host,
        "findings": findings,
        "errors": errors,
        "passed": len(errors) == 0,
        "limitations": [
            "Checksum values were not recomputed or compared against artifacts.",
            "Artifact freshness was not assessed.",
            "Restore testing was not performed.",
            "The token file was never opened or read.",
        ],
    }


def self_test():
    import hashlib
    import tempfile

    scratch = tempfile.TemporaryDirectory(prefix="bv-test-")

    def build_fixture(name, **kwargs):
        """Build a synthetic backup directory tree inside a temp dir."""
        root = tempfile.mkdtemp(prefix=f"{name}-", dir=scratch.name)
        host = kwargs.get("host", "fixture-host")
        prefix = kwargs.get("prefix", "k3s-etcd")
        etcd_dir = os.path.join(root, "etcd", host, "rolling")
        baseline_dir = os.path.join(root, "etcd", host, "baseline")
        token_dir = os.path.join(root, "token", host)
        os.makedirs(etcd_dir)
        os.makedirs(baseline_dir)
        os.makedirs(token_dir)

        snap = f"{prefix}-20261016-031500.zip"
        snap_data = b"fake-etcd-snapshot"
        snap_path = os.path.join(etcd_dir, snap)
        with open(snap_path, "wb") as fh:
            fh.write(snap_data)
        digest = hashlib.sha256(snap_data).hexdigest()
        with open(snap_path + ".sha256", "w") as fh:
            fh.write(digest + "  " + snap + "\n")

        bl = f"{prefix}-20261001-000000.zip"
        bl_data = b"fake-baseline"
        bl_path = os.path.join(baseline_dir, bl)
        with open(bl_path, "wb") as fh:
            fh.write(bl_data)
        bl_digest = hashlib.sha256(bl_data).hexdigest()
        with open(bl_path + ".sha256", "w") as fh:
            fh.write(bl_digest + "  " + bl + "\n")

        token_data = b"fake-token"
        with open(os.path.join(token_dir, "token"), "wb") as fh:
            fh.write(token_data)
        tk_digest = hashlib.sha256(token_data).hexdigest()
        with open(os.path.join(token_dir, "token.sha256"), "w") as fh:
            fh.write(tk_digest + "  token\n")

        return root

    checks = 0

    # 1. fully valid fixture passes
    root = build_fixture("valid")
    result = validate_backup_dir(root, "fixture-host")
    assert result["passed"], f"valid fixture should pass: {result['errors']}"
    checks += 1

    # 2. missing rolling snapshot fails
    root = build_fixture("no-rolling")
    for f in os.listdir(os.path.join(root, "etcd", "fixture-host", "rolling")):
        os.remove(os.path.join(root, "etcd", "fixture-host", "rolling", f))
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("rolling-snapshot-missing" in e for e in result["errors"])
    checks += 1

    # 3. missing sidecar fails
    root = build_fixture("no-sidecar")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in os.listdir(snap_dir):
        if f.endswith(".sha256"):
            os.remove(os.path.join(snap_dir, f))
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("sidecar-missing" in e for e in result["errors"])
    checks += 1

    # 4. bad checksum format fails
    root = build_fixture("bad-checksum")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in os.listdir(snap_dir):
        if f.endswith(".sha256"):
            with open(os.path.join(snap_dir, f), "w") as fh:
                fh.write("not-a-valid-checksum  " + f[:-len(".sha256")] + "\n")
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("sidecar-format" in e for e in result["errors"])
    checks += 1

    # 5. wrong name in sidecar fails
    root = build_fixture("wrong-name")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in os.listdir(snap_dir):
        if f.endswith(".sha256"):
            digest = open(os.path.join(snap_dir, f)).read().split()[0]
            with open(os.path.join(snap_dir, f), "w") as fh:
                fh.write(digest + "  different-name.zip\n")
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("sidecar names differ" in e for e in result["errors"])
    checks += 1

    # 6. missing token fails
    root = build_fixture("no-token")
    token_dir = os.path.join(root, "token", "fixture-host")
    os.remove(os.path.join(token_dir, "token"))
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("token-missing" in e for e in result["errors"])
    checks += 1

    # 7. missing token sidecar fails
    root = build_fixture("no-token-sidecar")
    token_dir = os.path.join(root, "token", "fixture-host")
    os.remove(os.path.join(token_dir, "token.sha256"))
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("token-sidecar-missing" in e for e in result["errors"])
    checks += 1

    # 8. non-hex checksum fails
    root = build_fixture("non-hex")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in os.listdir(snap_dir):
        if f.endswith(".sha256"):
            with open(os.path.join(snap_dir, f), "w") as fh:
                fh.write("Z" * 64 + "  " + f[:-len(".sha256")] + "\n")
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    checks += 1

    # 9. uppercase checksum fails (sha256sum uses lowercase)
    root = build_fixture("upper")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in os.listdir(snap_dir):
        if f.endswith(".sha256"):
            raw = open(os.path.join(snap_dir, f)).read()
            digest = raw.split()[0].upper()
            with open(os.path.join(snap_dir, f), "w") as fh:
                fh.write(digest + "  " + f[:-len(".sha256")] + "\n")
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    checks += 1

    # 10. missing backup directory raises ArtifactError
    try:
        validate_backup_dir("/nonexistent/path/xyz", "h")
    except ArtifactError:
        checks += 1
    else:
        raise AssertionError("missing dir should raise")

    # 11. symlink snapshot fails (must be a real regular file)
    root = build_fixture("symlink-snap")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in sorted(os.listdir(snap_dir)):
        if f.startswith("k3s-etcd-") and f.endswith(".zip"):
            real = os.path.join(snap_dir, f)
            target = os.path.join(snap_dir, f + ".real")
            os.rename(real, target)
            os.symlink(target, real)
            break
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("not a regular file" in e or "symlink" in e for e in result["errors"])
    checks += 1

    # 11b. symlink sidecar fails (must be a real regular file)
    root = build_fixture("symlink-sidecar")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in sorted(os.listdir(snap_dir)):
        if f.endswith(".sha256"):
            real = os.path.join(snap_dir, f)
            target = os.path.join(snap_dir, f + ".real")
            os.rename(real, target)
            os.symlink(target, real)
            break
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("not a regular file" in e or "symlink" in e for e in result["errors"])
    checks += 1

    # 12. sidecar with extra lines fails
    root = build_fixture("extra-line")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in os.listdir(snap_dir):
        if f.endswith(".sha256"):
            raw = open(os.path.join(snap_dir, f)).read()
            with open(os.path.join(snap_dir, f), "w") as fh:
                fh.write(raw + "deadbeef  extra.zip\n")
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("exactly one line" in e for e in result["errors"])
    checks += 1

    # 13. sidecar with single space fails
    root = build_fixture("one-space")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in os.listdir(snap_dir):
        if f.endswith(".sha256"):
            raw = open(os.path.join(snap_dir, f)).read()
            digest, name = raw.split()
            with open(os.path.join(snap_dir, f), "w") as fh:
                fh.write(digest + " " + name + "\n")
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("two spaces" in e for e in result["errors"])
    checks += 1

    # 14. sidecar with trailing garbage in name fails
    root = build_fixture("bad-name-chars")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in os.listdir(snap_dir):
        if f.endswith(".sha256"):
            raw = open(os.path.join(snap_dir, f)).read()
            digest = raw.split()[0]
            with open(os.path.join(snap_dir, f), "w") as fh:
                fh.write(digest + "  bad name with spaces.zip\n")
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("malformed" in e for e in result["errors"])
    checks += 1

    # 15. empty sidecar fails
    root = build_fixture("empty-sidecar")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    for f in os.listdir(snap_dir):
        if f.endswith(".sha256"):
            open(os.path.join(snap_dir, f), "w").close()
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    checks += 1

    # 16. token sidecar with wrong name fails
    root = build_fixture("token-wrong-name")
    token_dir = os.path.join(root, "token", "fixture-host")
    digest = open(os.path.join(token_dir, "token.sha256")).read().split()[0]
    with open(os.path.join(token_dir, "token.sha256"), "w") as fh:
        fh.write(digest + "  not-a-token\n")
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("sidecar names differ" in e for e in result["errors"])
    checks += 1

    # 17. multiple snapshots: one bad, one good → fails overall
    root = build_fixture("mixed")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    extra = "k3s-etcd-20261015-031500.zip"
    with open(os.path.join(snap_dir, extra), "wb") as fh:
        fh.write(b"second-snapshot")
    with open(os.path.join(snap_dir, extra + ".sha256"), "w") as fh:
        fh.write("BAD  " + extra + "\n")
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("BAD" in e or "checksum" in e for e in result["errors"])
    checks += 1

    # 18. regression: a failed finding records the offending artifact path,
    #     not the backup root (self-test 5 corrupts only the rolling sidecar)
    root = build_fixture("failure-path")
    snap_dir = os.path.join(root, "etcd", "fixture-host", "rolling")
    bad_sidecar = None
    for f in os.listdir(snap_dir):
        if f.endswith(".sha256"):
            raw = open(os.path.join(snap_dir, f)).read()
            bad_sidecar = os.path.join(snap_dir, f)
            with open(os.path.join(snap_dir, f), "w") as fh:
                fh.write(raw + "deadbeef  extra.zip\n")
    assert bad_sidecar is not None
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("sidecar-format" in e for e in result["errors"])
    failed = [f for f in result["findings"] if f["result"] == "fail"]
    assert failed, "expected at least one failed finding"
    assert all(f["path"] == bad_sidecar for f in failed), (
        f"failed findings must point at the offending artifact, got: "
        f"{[f['path'] for f in failed]}")
    checks += 1

    # 19. regression: baseline and token failure findings record the
    #     offending artifact path, not the backup root
    root = build_fixture("baseline-failure-path")
    baseline_dir = os.path.join(root, "etcd", "fixture-host", "baseline")
    bad_sidecar = None
    for f in os.listdir(baseline_dir):
        if f.endswith(".sha256"):
            bad_sidecar = os.path.join(baseline_dir, f)
            with open(bad_sidecar, "w") as fh:
                fh.write("not-a-valid-checksum  " + f[:-len(".sha256")] + "\n")
    assert bad_sidecar is not None
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    failed = [f for f in result["findings"] if f["result"] == "fail"]
    assert failed, "expected at least one failed finding"
    assert all(f["path"] == bad_sidecar for f in failed), (
        f"baseline failed findings must point at the offending sidecar, got: "
        f"{[f['path'] for f in failed]}")

    root = build_fixture("token-failure-path")
    token_sidecar = os.path.join(root, "token", "fixture-host", "token.sha256")
    with open(token_sidecar, "w") as fh:
        fh.write("not-a-valid-checksum  token\n")
    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    failed = [f for f in result["findings"] if f["result"] == "fail"]
    assert failed, "expected at least one failed finding"
    assert all(f["path"] == token_sidecar for f in failed), (
        f"token failed findings must point at the offending sidecar, got: "
        f"{[f['path'] for f in failed]}")
    checks += 1

    # 20. a missing required baseline fails and identifies its directory
    root = build_fixture("no-baseline")
    baseline_dir = os.path.join(root, "etcd", "fixture-host", "baseline")
    for name in os.listdir(baseline_dir):
        os.remove(os.path.join(baseline_dir, name))

    result = validate_backup_dir(root, "fixture-host")
    assert not result["passed"]
    assert any("baseline-snapshot-missing" in error for error in result["errors"])
    assert any(
        finding["check"] == "baseline-snapshot-missing"
        and finding["path"] == baseline_dir
        and finding["result"] == "fail"
        for finding in result["findings"]
    ), f"missing-baseline finding should point to {baseline_dir}"
    checks += 1

    print(f"PASS: {checks} validator self-test checks (synthetic fixtures only).")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--backup-dir")
    parser.add_argument("--host")
    parser.add_argument("--prefix", default="k3s-etcd")
    parser.add_argument("--json", action="store_true", dest="as_json")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return 0

    if not args.backup_dir or not args.host:
        parser.error("--backup-dir and --host are required unless --self-test is given")

    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.@-]*", args.host):
        parser.error("Host must be a hostname or user@hostname")

    result = validate_backup_dir(args.backup_dir, args.host, args.prefix)
    if args.as_json:
        print(json.dumps(result, indent=2))
    else:
        for f in result["findings"]:
            print(f"  {f['check']:30s} {f['result']:5s} {f['path']}")
        for e in result["errors"]:
            print(f"  ERROR: {e}", file=sys.stderr)
        if result["passed"]:
            print(f"\nAll backup artifacts validated: {args.backup_dir}")
        else:
            print(f"\n{len(result['errors'])} validation error(s) found.",
                  file=sys.stderr)
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
