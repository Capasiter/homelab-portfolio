# Backup evidence collector

## Run from the repository root

    python3 scripts/collect-backup-evidence.py

Requires the existing SSH keys loaded into the terminal's SSH agent.
Runs read-only systemd queries for the backup timer and service.
Does not trigger backups, read token contents, or modify remote systems.

JSON retains commands, raw output, exit codes, parsed properties, and
local query-start timestamps. Collection errors leave properties
unavailable and produce a nonzero exit code; they do not prove backup failure.

UTC service-exit age is calculated by Python relative to query start.
It is not backup-artifact freshness. Clock synchronization is unverified.
The timer and service observations are collected separately.

## Isolated tests

    python3 scripts/collect-backup-evidence.py --self-test

All 18 checks passed locally with exit code 0 using fake SSH responses.
CI is configured to run these tests without connecting to the lab.
A user-run live collection returned exit code 0. A separate check confirmed
saved raw output matched parsed properties before the timing extension.

Hermes quoted the calculated timing values correctly, but initially
miscalculated elapsed time and later cited incorrect limitation indexes.
Human review remains necessary.

## Limitations

Artifact existence, checksum integrity, backup freshness, and restore
testing are not collected. Collection success does not prove backup success.
Service result alone does not establish a completed execution.
