# helm-gateway-routes-chart

Helm chart for exposing services through Istio ambient mesh using Gateway API resources.
The chart renders nothing by default — resources are created only when explicitly configured.

The chart is located at [`charts/gateway-routes`](charts/gateway-routes).

---

## Architecture

### Traffic flow

```
External client (HTTPS)
        │
        ▼
┌───────────────────────┐
│   ingressgateway      │  Namespace: istio-ingress
│   Envoy proxy         │  TLS termination, cert-manager certs
│   GatewayClass: istio │  Shared by all tenants via ListenerSet
└──────────┬────────────┘
           │ HBONE (HTTP/2 CONNECT + mTLS, port 15008)
           ▼
┌───────────────────────┐
│   ztunnel (DaemonSet) │  Per-node transparent proxy
│   L4 mTLS (SPIFFE)    │  eBPF/iptables traffic intercept
└──────────┬────────────┘
           │ HBONE → waypoint (if service has istio.io/use-waypoint label)
           ▼
┌───────────────────────┐
│   waypoint (Envoy)    │  Per-namespace, optional
│   L7 policy           │  AuthorizationPolicy, telemetry
│   GatewayClass:       │  Only in path for labelled Services
│   istio-waypoint      │
└──────────┬────────────┘
           │ plain HTTP
           ▼
┌───────────────────────┐
│   Backend pod         │  No sidecar
└───────────────────────┘
```

### Moving parts

| Component | Kind | Namespace | Who manages |
|---|---|---|---|
| `ingressgateway` | Gateway (GatewayClass: istio) | istio-ingress | Platform |
| `istiod` | Deployment | istio-system | Platform |
| `ztunnel` | DaemonSet | istio-system | Platform |
| `ListenerSet` | per-hostname HTTPS listeners | tenant ns | Tenant (via this chart) |
| `HTTPRoute` | routing rules | tenant ns | Tenant (via this chart) |
| `waypoint` | Gateway (GatewayClass: istio-waypoint) | tenant ns | Tenant bootstrap chart |
| `AuthorizationPolicy` | IP allowlist, path policy | tenant ns | Tenant (via this chart) |
| Dedicated Gateway (mTLS) | Gateway (GatewayClass: istio) | istio-ingress | Platform, per app |

### Namespace model

Tenants attach to the shared ingressgateway via **ListenerSet** resources in their own namespace.
cert-manager provisions TLS certificates automatically when a `ClusterIssuer` annotation is present.

```
istio-ingress/
  Gateway/ingressgateway           ← shared entry point (platform-managed)
  ConfigMap/ingressgateway-options ← Deployment/HPA/PDB config

tenant-ns/
  ListenerSet/myapp                ← adds HTTPS listeners to the shared gateway
  HTTPRoute/myapp                  ← routes to backend Services
  AuthorizationPolicy/myapp-*      ← IP allowlists, path blocking
  Gateway/waypoint                 ← per-namespace L7 proxy (optional)
  NetworkPolicy/waypoint           ← restricts waypoint ingress/egress
```

---

## Repository structure

```
.
├── charts/
│   └── gateway-routes/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-docs.yaml
│       ├── README.md.gotmpl
│       ├── README.md
│       ├── templates/
│       └── ci/
│           └── *-values.yaml
├── Makefile
├── ct.yaml
└── README.md
```

---

## Development

### Prerequisites

- Docker (for `make docs` and `make lint`)

### Generate docs

```sh
make docs
```

Runs helm-docs in a container and regenerates [`charts/gateway-routes/README.md`](charts/gateway-routes/README.md)
from `README.md.gotmpl`, `values-docs.yaml`, and the `ci/` example files.

### Lint

```sh
make lint
```

Runs chart-testing (`ct lint`) against all charts.

---

## values.yaml vs values-docs.yaml vs ci/*-values.yaml

| File | Purpose |
|---|---|
| `values.yaml` | Actual Helm defaults — intentionally minimal |
| `values-docs.yaml` | Documentation only — expands map-based values into a readable table for helm-docs |
| `ci/*-values.yaml` | Concrete, copy-paste-friendly examples embedded in the chart README |
