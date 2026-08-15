# K3s Rolling-Update Reliability Lab

This lab validates application availability during a Kubernetes Deployment rolling restart on a three-server K3s cluster. It demonstrates the difference between a rollout that Kubernetes reports as successful and one that also maintains availability from the application user’s perspective.

The deployable workload is defined in [web-demo.yaml](./web-demo.yaml).

## Environment

| Component | Value |
|---|---|
| Cluster | Three-server K3s control plane |
| Kubernetes | `v1.36.2+k3s1` |
| Namespace | `k8s-learning` |
| Deployment | `web-demo` |
| Image | `traefik/whoami:v1.11.0` |
| Replicas | 3 |
| Ingress controller | Traefik |
| Ingress hostname | `web-demo.home.arpa` |
| Initial validation date | August 9, 2026 |
| Revalidation date | August 15, 2026 |

## Initial Observation

The original Deployment used the default rolling-update strategy:

```text
maxSurge: 25%
maxUnavailable: 25%
minReadySeconds: 0
readinessProbe: none
termination lifecycle: none
terminationGracePeriodSeconds: 30
```

With three replicas, Kubernetes rounded `maxSurge` up to one and `maxUnavailable` down to zero. The rollout controller therefore intended to maintain three available replicas.

A rolling restart completed successfully according to Kubernetes:

```text
deployment "web-demo" successfully rolled out
```

However, a live request loop recorded one client-visible failure:

```text
FAILED curl: (28) Operation timed out after 2002 milliseconds
```

The rollout was successful from the Deployment controller’s perspective, but it was not zero-failure from the application user’s perspective.

## Likely Cause

Without a readiness probe, Kubernetes did not verify that a new container could answer HTTP requests before treating it as Ready.

Without a `preStop` lifecycle delay, a terminating `whoami` process could exit before the Service EndpointSlice update had fully propagated to Traefik.

The timeout was therefore most likely caused by a brief routing race involving either a newly started backend or a terminating backend.

## Reliability Protections

The Deployment was updated with the following protections:

| Protection | Configuration | Purpose |
|---|---|---|
| Guaranteed rollout capacity | `maxUnavailable: 0` | Prevents Kubernetes from intentionally reducing available replicas |
| Controlled surge | `maxSurge: 1` | Allows one replacement pod above the desired replica count |
| HTTP readiness probe | `GET /` on port `80` | Confirms the application can answer HTTP before receiving traffic |
| Stable readiness window | `minReadySeconds: 5` | Requires a new pod to remain Ready before rollout progression |
| Endpoint propagation window | Native `preStop` sleep of 10 seconds | Gives Traefik time to stop routing new requests to a terminating pod |
| Termination budget | 30 seconds | Provides time for the lifecycle hook and container termination |

## Safe Validation

The manifest was checked against the live Kubernetes API without changing the cluster:

```bash
ssh k3s-server-01 \
  'sudo k3s kubectl apply --dry-run=server -f -' \
  < kubernetes/k8s-learning/web-demo.yaml
```

All four resources passed server-side validation:

```text
namespace/k8s-learning configured (server dry run)
deployment.apps/web-demo configured (server dry run)
service/web-demo configured (server dry run)
ingress.networking.k8s.io/web-demo configured (server dry run)
```

## Live-Traffic Test

The traffic generator ran from `k3s-server-01`, which is inside the isolated `10.20.0.0/24` lab network:

```bash
while true; do
  if curl -fsS \
    --connect-timeout 1 \
    --max-time 2 \
    --resolve web-demo.home.arpa:80:10.20.0.101 \
    http://web-demo.home.arpa \
    >/dev/null
  then
    printf '%s OK\n' "$(date +%H:%M:%S)"
  else
    printf '%s FAILED\n' "$(date +%H:%M:%S)"
  fi

  sleep 1
done | tee /tmp/web-demo-protected-rollout-traffic.log
```

While traffic continued, the Deployment was restarted from a separate terminal:

```bash
ssh k3s-server-01 \
  'sudo k3s kubectl -n k8s-learning rollout restart deployment/web-demo'

ssh k3s-server-01 \
  'sudo k3s kubectl -n k8s-learning rollout status deployment/web-demo --timeout=180s'
```

Kubernetes completed the rollout successfully:

```text
deployment "web-demo" successfully rolled out
```

The traffic log contained:

```text
OK=148 FAILED=0 TOTAL=148
```

Final Deployment state:

```text
generation: 5
observedGeneration: 5
desired replicas: 3
updated replicas: 3
ready replicas: 3
available replicas: 3
```

## Result

The protected rolling restart completed with:

- 148 successful requests
- 0 observed request failures
- 3 of 3 replicas updated, Ready, and available
- One running pod on each K3s server at the end of the test

This result demonstrates zero observed failures during this controlled validation run. It does not guarantee that every future rollout or infrastructure failure will be interruption-free.

A second validation run on August 15, 2026, observed 120 successful requests and 0 failures. The Deployment returned to 3/3 Ready and available, with one pod running on each K3s server.

## Skills Demonstrated

- Kubernetes Deployment and ReplicaSet troubleshooting
- Readiness-probe design
- Pod termination lifecycle management
- Traefik Ingress validation
- Server-side dry-run safety checks
- Live-traffic testing during infrastructure changes
- Evidence-based diagnosis and post-change verification

## Current Limitations

- The test used short HTTP requests rather than long-lived connections.
- Traffic originated inside the isolated lab network.
- The manifest does not currently enforce topology spread or pod anti-affinity.
- The test covers a controlled Deployment restart, not an unexpected node or network failure.
- The demonstration uses HTTP without TLS.
