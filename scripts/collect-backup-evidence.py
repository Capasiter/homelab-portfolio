#!/usr/bin/env python3
"""Read-only systemd evidence collector. No backup or secret access."""
import argparse
import json
import re
import subprocess
from datetime import datetime, timezone

FIELDS = {
    "k3s-backup.timer": (
        "LoadState", "ActiveState", "UnitFileState",
    ),
    "k3s-backup.service": (
        "LoadState", "ActiveState", "Result", "ExecMainStatus",
        "ExecMainStartTimestamp", "ExecMainExitTimestamp",
    ),
}


def parse_properties(text, required):
    properties = {}
    for line in text.splitlines():
        key, separator, value = line.partition("=")
        if not separator or key not in required or key in properties:
            raise ValueError("Malformed, unexpected, or duplicate property")
        properties[key] = value
    if set(properties) != set(required):
        raise ValueError("Required properties missing")
    return properties


def collect_unit(host, unit, runner=subprocess.run):
    fields = FIELDS[unit]
    remote = "TZ=UTC LC_ALL=C systemctl show " + unit
    remote += "".join(" -p " + field for field in fields)
    command = [
        "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10",
        host, remote,
    ]
    evidence = {
        "command": command,
        "observed_at": datetime.now(timezone.utc).isoformat(),
        "exit_code": None,
        "stdout": None,
        "stderr": None,
        "properties": None,
        "collection_error": None,
    }
    try:
        result = runner(
            command, capture_output=True, text=True, timeout=25,
        )
    except subprocess.TimeoutExpired:
        evidence["collection_error"] = "SSH command timed out"
        return evidence
    except OSError:
        evidence["collection_error"] = "Unable to start SSH command"
        return evidence

    evidence.update(
        exit_code=result.returncode,
        stdout=result.stdout,
        stderr=result.stderr,
    )
    if result.returncode != 0:
        evidence["collection_error"] = "SSH command returned nonzero"
        return evidence
    try:
        evidence["properties"] = parse_properties(result.stdout, fields)
    except ValueError as error:
        evidence["collection_error"] = str(error)
    return evidence



def service_timing(evidence):
    """Calculate service-exit age at query start, not backup freshness."""
    result = {
        "service_exit_utc": None,
        "reference_time": evidence["observed_at"],
        "service_exit_age_seconds": None,
        "unknown_reason": None,
    }
    properties = evidence["properties"]
    if properties is None:
        result["unknown_reason"] = "Service properties unavailable"
        return result
    stamp = properties.get("ExecMainExitTimestamp")
    if not stamp:
        result["unknown_reason"] = "Service exit timestamp not supplied"
        return result
    try:
        exited = datetime.strptime(
            stamp, "%a %Y-%m-%d %H:%M:%S UTC"
        ).replace(tzinfo=timezone.utc)
        reference = datetime.fromisoformat(evidence["observed_at"])
        if reference.tzinfo is None or reference.utcoffset() is None:
            raise ValueError("Reference time lacks a timezone")
        reference = reference.astimezone(timezone.utc)
        age = (reference - exited).total_seconds()
        if age < 0:
            raise ValueError("Service exit is later than query start")
    except ValueError as error:
        result["unknown_reason"] = str(error)
        return result
    result["service_exit_utc"] = exited.isoformat()
    result["service_exit_age_seconds"] = age
    return result

def self_test():
    fields = FIELDS["k3s-backup.timer"]
    valid = "LoadState=loaded\nActiveState=active\nUnitFileState=enabled\n"
    checks = 0

    assert parse_properties(valid, fields)["ActiveState"] == "active"
    checks += 1

    for invalid in (
        "LoadState=loaded\n",
        valid + "ActiveState=inactive\n",
        valid + "unexpected\n",
        valid + "Extra=value\n",
    ):
        try:
            parse_properties(invalid, fields)
        except ValueError:
            checks += 1
        else:
            raise AssertionError("Invalid properties accepted")

    def fake_success(*args, **kwargs):
        return subprocess.CompletedProcess(args[0], 0, valid, "")

    def fake_failure(*args, **kwargs):
        return subprocess.CompletedProcess(args[0], 255, valid, "Permission denied")

    def fake_timeout(*args, **kwargs):
        raise subprocess.TimeoutExpired(args[0], kwargs["timeout"])

    successful = collect_unit("fixture-host", "k3s-backup.timer", fake_success)
    assert successful["properties"]["UnitFileState"] == "enabled"
    assert successful["collection_error"] is None
    checks += 1

    failed = collect_unit("fixture-host", "k3s-backup.timer", fake_failure)
    assert failed["properties"] is None
    assert failed["exit_code"] == 255
    assert failed["collection_error"] is not None
    checks += 1

    timed_out = collect_unit("fixture-host", "k3s-backup.timer", fake_timeout)
    assert timed_out["properties"] is None
    assert timed_out["exit_code"] is None
    assert timed_out["collection_error"] is not None
    checks += 1

    service_fields = FIELDS["k3s-backup.service"]
    unused = "\n".join(
        field + "=" + {
            "LoadState": "loaded", "ActiveState": "inactive",
            "Result": "success", "ExecMainStatus": "0",
        }.get(field, "")
        for field in service_fields
    )
    parsed = parse_properties(unused, service_fields)
    assert parsed["ExecMainStartTimestamp"] == ""
    assert parsed["ExecMainExitTimestamp"] == ""
    checks += 1


    fixture = {
        "observed_at": "2026-10-11T00:15:38+00:00",
        "properties": {
            "ExecMainExitTimestamp": "Sat 2026-10-10 08:21:37 UTC",
        },
    }
    assert service_timing(fixture)["service_exit_age_seconds"] == 57241
    checks += 1

    offset_fixture = {
        **fixture,
        "observed_at": "2026-10-10T19:15:38-05:00",
    }
    assert service_timing(offset_fixture)["service_exit_age_seconds"] == 57241
    checks += 1

    for stamp in ("", "invalid", "Sat 2026-10-10 08:21:37 CDT"):
        invalid = {
            **fixture,
            "properties": {"ExecMainExitTimestamp": stamp},
        }
        result = service_timing(invalid)
        assert result["service_exit_age_seconds"] is None
        assert result["unknown_reason"] is not None
        checks += 1

    for reference in (
        "2026-10-10T08:00:00+00:00",
        "2026-10-11T00:15:38",
    ):
        result = service_timing({**fixture, "observed_at": reference})
        assert result["service_exit_age_seconds"] is None
        assert result["unknown_reason"] is not None
        checks += 1

    result = service_timing({**fixture, "properties": None})
    assert result["service_exit_age_seconds"] is None
    assert result["unknown_reason"] is not None
    checks += 1

    boundary = {**fixture, "observed_at": "2026-10-10T08:21:37+00:00"}
    assert service_timing(boundary)["service_exit_age_seconds"] == 0
    checks += 1

    print(f"PASS: {checks} collector checks (fake SSH only).")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="k3s-server-01")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.@-]*", args.host):
        parser.error("Host must be a hostname, IP, or user@hostname")

    observations = {
        unit: collect_unit(args.host, unit) for unit in FIELDS
    }
    report = {
        "schema_version": "1",
        "host": args.host,
        "observations": observations,
        "service_timing": service_timing(observations["k3s-backup.service"]),
        "limitations": [
            "Observations were collected separately, not atomically.",
            "Raw systemd timestamps are retained; backup freshness is not assessed.",
            "Service-exit age uses the local query-start time, not an artifact timestamp.",
            "Cross-machine clock synchronization was not verified.",
            "Service result and status alone do not establish a completed run.",
            "Artifact existence, checksums, and restore testing were not collected.",
            "Collection errors mean unavailable evidence, not backup failure.",
        ],
    }
    print(json.dumps(report, indent=2))
    return int(any(
        observation["collection_error"] is not None
        for observation in observations.values()
    ))


if __name__ == "__main__":
    raise SystemExit(main())
