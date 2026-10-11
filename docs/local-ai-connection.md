# Local AI connection

Verified setup for connecting the Linux devops-workstation to LM Studio
running on the Windows machine, via a reverse SSH tunnel.

## Endpoints and components

- [Windows] LM Studio serves OpenAI-compatible APIs at
  `http://127.0.0.1:1235/v1`.
- [Windows] PowerShell hosts the reverse SSH tunnel.
- [Linux] devops-workstation is the SSH destination and the machine that
  reaches LM Studio.
- Hermes uses the Linux endpoint `http://127.0.0.1:1235/v1`.
- Continue's "Qwen Local" entry uses `http://127.0.0.1:1235/v1`.
  Its extension execution location has not yet been verified.

## [Windows] Reverse SSH tunnel

In Windows PowerShell, keep this tunnel running:

```powershell
ssh -N -o ExitOnForwardFailure=yes -R 127.0.0.1:1235:127.0.0.1:1235 wickedgamingserver@192.168.0.159
```

- `-N` opens no remote command; the session only forwards the port.
- `-R 127.0.0.1:1235:127.0.0.1:1235` binds port 1235 on the Linux host
  (devops-workstation) and forwards it back to LM Studio on the Windows
  machine.
- `ExitOnForwardFailure=yes` exits if SSH cannot establish the requested
  forwarding. It does not guarantee that LM Studio remains reachable afterward.
- Closing the tunnel window disconnects the Linux endpoint;
  devops-workstation can no longer reach LM Studio until the tunnel is
  re-established.

## [Linux] Connectivity check

On devops-workstation, while the tunnel is running:

```bash
curl --connect-timeout 5 --max-time 10 http://127.0.0.1:1235/v1/models
```

A successful response confirms the tunnel and the LM Studio endpoint are
reachable from the Linux side.

## Assistant configuration

- Hermes: uses the Linux endpoint `http://127.0.0.1:1235/v1`.
- Continue, "Qwen Local" entry:
  - provider: `lmstudio`
  - model: `qwen/qwen3.8-27b`
  - apiBase: `http://127.0.0.1:1235/v1`

## Verification status and limits

- Both assistants returned Ready during the basic generation checks on October 11, 2026.
- These checks establish connectivity and basic generation only.
- They do not establish answer accuracy.
