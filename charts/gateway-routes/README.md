# gateway-routes

Helm chart for exposing services through Istio ambient mesh using Gateway API resources. Renders ListenerSet, HTTPRoute, and AuthorizationPolicy resources from values. The chart renders nothing by default; resources are created only when explicitly configured.

**Homepage:** <https://github.com/KvalitetsIT>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| KvalitetsIT | <kithosting@kvalitetsit.dk> | <https://github.com/KvalitetsIT/helm-repo> |

## Source Code

* <https://github.com/KvalitetsIT/helm-gateway-routes-chart>

## Values

### Defaults

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| defaults.gateway | object | `{"name":"ingressgateway","namespace":"istio-ingress"}` | Default gateway to attach ListenerSets to. |
| defaults.gateway.name | string | `"ingressgateway"` | Gateway name. |
| defaults.gateway.namespace | string | `"istio-ingress"` | Gateway namespace. |
| defaults.clusterIssuer | string | `"letsencrypt-prod-istio"` | Default cert-manager cluster issuer for TLS certificates. |

### ReferenceGrant

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| referenceGrant | object | `{"enabled":false,"gatewayNamespace":"istio-ingress"}` | Optional. Creates a ReferenceGrant allowing the gateway namespace to reference ConfigMaps in this release namespace. Required for client certificate authentication via a dedicated Gateway with `spec.tls.frontend.validation.caCertificateRefs` pointing to a CA ConfigMap in the tenant namespace. The Gateway itself must be created by an admin in the gateway namespace (`istio-ingress`). See [Client certificate authentication](#client-certificate-authentication). |
| referenceGrant.enabled | bool | `false` | Optional. Enable the ReferenceGrant. |
| referenceGrant.gatewayNamespace | string | `"istio-ingress"` | Optional. Override the source gateway namespace. |

### Routes

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| routes | object | {} | Map of routes to render. Each top-level key becomes the name of the ListenerSet and HTTPRoute. See [Examples](#examples) for usage. |
| routes.\<name>.metadata.name | string | `""` | Optional. Override the rendered resource name. |
| routes.\<name>.metadata.namespace | string | `""` | Optional. Override the rendered resource namespace. |
| routes.\<name>.metadata.labels | object | {} | Optional. Additional labels merged with common labels on all resources for this route. |
| routes.\<name>.metadata.annotations | object | {} | Optional. Annotations added to all resources for this route. The cert-manager.io/cluster-issuer annotation is managed via clusterIssuer. |
| routes.\<name>.gateway.name | string | `""` | Optional. Gateway name. Defaults to defaults.gateway.name. |
| routes.\<name>.gateway.namespace | string | `""` | Optional. Gateway namespace. Defaults to defaults.gateway.namespace. |
| routes.\<name>.gateway.sectionName | string | `""` | Optional. Gateway listener section name. When set, the ListenerSet is skipped and the HTTPRoute attaches directly to the named Gateway listener section. Use this when a listener is managed on the Gateway itself rather than via a per-tenant ListenerSet. |
| routes.\<name>.clusterIssuer | string | `""` | Optional. Override the default cert-manager cluster issuer for this route. Defaults to defaults.clusterIssuer. |
| routes.\<name>.service | object | {} | Optional. Creates a waypoint wrapper Service named `<route-name>-mesh` with `istio.io/use-waypoint` and `istio.io/ingress-use-waypoint` labels, routing ingressgateway traffic through the waypoint without affecting east-west traffic. When set, `httpRoute.rules` defaults to a single catch-all rule pointing to `<route-name>-mesh` — no explicit `backendRefs` needed. |
| routes.\<name>.service.selector | object | {} | Required. Pod selector labels for the wrapper Service. Must match the pod labels of the existing app deployment. |
| routes.\<name>.service.ports | list | [] | Required. Ports exposed on the wrapper Service. |
| routes.\<name>.service.ports[0].name | string | "http" for the first port, "http-N" for additional ports | Optional. Port name. |
| routes.\<name>.service.ports[0].port | int | `80` | Optional. Service port. |
| routes.\<name>.service.ports[0].targetPort | int | `nil` | Required. Pod target port. |
| routes.\<name>.service.ports[0].protocol | string | `"TCP"` | Optional. Protocol. |
| routes.\<name>.service.waypoint | string | `"waypoint"` | Optional. Waypoint Gateway name to bind to. |
| routes.\<name>.listeners | list | [] | Optional. Listener overrides for the ListenerSet. Hostnames always come from `httpRoute.hostnames` — one listener is rendered per hostname. When `listeners` has fewer entries than hostnames, the first entry is used as a template for remaining hostnames. When omitted entirely, HTTPS with all defaults is used. Use explicit listeners only when you need non-default protocol, port, or TLS settings. |
| routes.\<name>.listeners[0].name | string | "https" / "http" based on protocol; "https-N" / "http-N" for additional listeners | Optional. Listener name. Must be unique within the ListenerSet. |
| routes.\<name>.listeners[0].protocol | string | `"HTTPS"` | Optional. Protocol. HTTPS or HTTP. |
| routes.\<name>.listeners[0].port | int | 443 for HTTPS/TLS, 80 for HTTP | Optional. Port. |
| routes.\<name>.listeners[0].tls | object | {} | Optional. TLS configuration. Defaults to Terminate mode with a Secret named after the hostname, managed by cert-manager via the clusterIssuer default. |
| routes.\<name>.listeners[0].tls.mode | string | `"Terminate"` | Optional. TLS mode. |
| routes.\<name>.listeners[0].tls.certificateRef | object | Secret named after the listener hostname in the route namespace | Optional. Override the certificate reference. When set, the cert-manager.io/cluster-issuer annotation is omitted. Use this to reference a certificate Secret managed outside the chart. Requires a ReferenceGrant in the target namespace if the secret is in a different namespace than the ListenerSet. |
| routes.\<name>.listeners[0].tls.certificateRef.name | string | `""` | Required when certificateRef is set. Secret name. |
| routes.\<name>.listeners[0].tls.certificateRef.namespace | string | `""` | Required when certificateRef is set. Secret namespace. |
| routes.\<name>.httpRoute | object | {} | Required. HTTPRoute configuration. |
| routes.\<name>.httpRoute.hostnames | list | [] | Optional. Hostnames for the HTTPRoute and auto-generated ListenerSet listeners. When `listeners` is omitted, one HTTPS listener is auto-generated per hostname here. When `listeners` is set, this field is unused for the ListenerSet — hostnames are collected from the listener entries instead. Required when `gateway.sectionName` is set (no ListenerSet rendered). |
| routes.\<name>.httpRoute.rules | list | [] | Optional. Routing rules. When omitted and `service` is defined, defaults to a single catch-all rule pointing to `<route-name>-mesh`. Required otherwise. |
| routes.\<name>.httpRoute.rules[0].matches | list | [] | Optional. Match conditions (path, headers, method). If omitted, the rule matches all requests. |
| routes.\<name>.httpRoute.rules[0].filters | list | [] | Optional. Filters to apply (URLRewrite, RequestRedirect, RequestHeaderModifier). |
| routes.\<name>.httpRoute.rules[0].backendRefs | list | [] | Optional. Backend services to forward matched requests to. Required when the rule has no `filters` and `service` is not defined. When omitted and `service` is defined, defaults to `<route-name>-mesh`. |
| routes.\<name>.httpRoute.rules[0].backendRefs[0].name | string | `""` | Required. Service name. |
| routes.\<name>.httpRoute.rules[0].backendRefs[0].port | int | `80` | Optional. Service port. |
| routes.\<name>.httpRoute.rules[0].backendRefs[0].weight | int | `100` | Optional. Traffic weight (0-100). Used for traffic splitting. |
| routes.\<name>.authorizationPolicies | object | {} | Optional. Map of AuthorizationPolicy resources for this route. Each key becomes part of the policy name: <route-name>-<key>. |
| routes.\<name>.authorizationPolicies.\<policy-name>.metadata.name | string | `""` | Optional. Override the rendered AuthorizationPolicy name. |
| routes.\<name>.authorizationPolicies.\<policy-name>.metadata.labels | object | {} | Optional. Additional labels for this AuthorizationPolicy. |
| routes.\<name>.authorizationPolicies.\<policy-name>.metadata.annotations | object | {} | Optional. Annotations for this AuthorizationPolicy. |
| routes.\<name>.authorizationPolicies.\<policy-name>.targetRefs | list | [] | Optional. Target refs for the policy. Defaults to the first backendRef service if not set. kind defaults to "Service", group defaults to "". |
| routes.\<name>.authorizationPolicies.\<policy-name>.action | string | `"DENY"` | Optional. Policy action. |
| routes.\<name>.authorizationPolicies.\<policy-name>.rules | list | [] | Required. Authorization rules. |

## Hostname resolution

Hostnames are always defined in `httpRoute.hostnames` — they flow to both the `ListenerSet` and `HTTPRoute`.
The `listeners` field controls only protocol, port, and TLS settings — never hostnames.

| Configuration | ListenerSet listeners | HTTPRoute hostnames |
|---|---|---|
| No `listeners` | One HTTPS listener auto-generated per hostname | From `httpRoute.hostnames` |
| `listeners` with one entry | That entry used as a template for all hostnames | From `httpRoute.hostnames` |
| `listeners` with N entries | Entries matched 1:1 to hostnames; first entry used as template for any extras | From `httpRoute.hostnames` |
| `gateway.sectionName` set | No ListenerSet rendered | From `httpRoute.hostnames` |

## nginx-ingress annotation migration

| nginx annotation | Equivalent |
|---|---|
| _(none)_ | [Simple HTTPS route](#simple-https-route) |
| `nginx.ingress.kubernetes.io/backend-protocol: HTTP` | No action needed — Envoy always uses HTTP to the backend |
| `nginx.ingress.kubernetes.io/force-ssl-redirect: "true"` | No action needed — the ListenerSet only exposes port 443 |
| `nginx.ingress.kubernetes.io/rewrite-target` + `nginx.ingress.kubernetes.io/use-regex` | [Path rewrite](#path-rewrite) |
| `nginx.ingress.kubernetes.io/app-root` | [App-root redirect](#app-root-redirect) |
| `nginx.ingress.kubernetes.io/whitelist-source-range` | [IP allowlist](#ip-allowlist) |
| `nginx.ingress.kubernetes.io/enable-cors` / `nginx.ingress.kubernetes.io/cors-allow-*` | [CORS](#cors) |
| `nginx.ingress.kubernetes.io/ssl-passthrough` | [SSL passthrough](#ssl-passthrough) |
| `nginx.ingress.kubernetes.io/auth-tls-verify-client` / `nginx.ingress.kubernetes.io/auth-tls-secret` | [Client certificate authentication](#client-certificate-authentication) |
| `nginx.ingress.kubernetes.io/auth-tls-pass-certificate-to-upstream` | Handled automatically — `x-forwarded-client-cert` is forwarded to the backend via a global EnvoyFilter |
| `nginx.ingress.kubernetes.io/proxy-body-size` | No action needed — Envoy streams request bodies without buffering |
| `nginx.ingress.kubernetes.io/proxy-buffer-size` / `nginx.ingress.kubernetes.io/proxy-buffers-number` | No action needed — Envoy streams, no buffering |
| `nginx.ingress.kubernetes.io/large-client-header-buffers` | No action needed — Envoy default header limit is 60 KB (nginx is 32 KB) |
| `nginx.ingress.kubernetes.io/server-snippet` (block path) | [Block paths](#block-paths) |
| `nginx.ingress.kubernetes.io/configuration-snippet: more_set_headers` | [Response headers](#response-headers) |

## Examples

Each `routes` entry renders a `ListenerSet`, an `HTTPRoute`, and optionally one or more `AuthorizationPolicy` resources.
By default, the chart renders nothing — routes are created only when explicitly configured.

### Simple HTTPS route

Forward all traffic for a hostname to a backend service over HTTPS.
cert-manager provisions the TLS certificate automatically.

```yaml
routes:
  myapp:
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - backendRefs:
            - name: myapp
              port: 80
```

### HTTP route

Expose a service over plain HTTP.

```yaml
routes:
  myapp:
    listeners:
      - protocol: HTTP
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - backendRefs:
            - name: myapp
              port: 80
```

### Path rewrite

Strip a path prefix before forwarding to the backend.

```yaml
routes:
  myapp:
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /api
          filters:
            - type: URLRewrite
              urlRewrite:
                path:
                  type: ReplacePrefixMatch
                  replacePrefixMatch: /
          backendRefs:
            - name: myapp
              port: 8080
```

### App-root redirect

Redirect requests to `/` to a specific path, then forward all traffic under that path to the backend.

```yaml
routes:
  myapp:
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - matches:
            - path:
                type: Exact
                value: /
          filters:
            - type: RequestRedirect
              requestRedirect:
                path:
                  type: ReplaceFullPath
                  replaceFullPath: /app
        - matches:
            - path:
                type: PathPrefix
                value: /app
          backendRefs:
            - name: myapp
              port: 8080
```

### IP allowlist

Deny all traffic not originating from the specified IP ranges.

```yaml
routes:
  myapp:
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - backendRefs:
            - name: myapp
              port: 80
    authorizationPolicies:
      ip-allowlist:
        rules:
          - from:
              - source:
                  notRemoteIpBlocks:
                    - "1.2.3.4/32"
                    - "10.0.0.0/8"
```

### CORS

Add CORS headers to responses.

```yaml
routes:
  myapp:
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - filters:
            - type: CORS
              cors:
                allowOrigins:
                  - "https://myapp.example.com"
                allowMethods:
                  - GET
                  - POST
                  - PUT
                  - DELETE
                  - PATCH
                  - OPTIONS
                allowHeaders:
                  - "*"
          backendRefs:
            - name: myapp
              port: 8080
```

### SSL passthrough

Forward the raw TLS stream to the backend without terminating TLS at the gateway.
cert-manager is not involved — the backend manages its own certificate.

```yaml
routes:
  myapp:
    tlsRoute:
      hostnames:
        - myapp.example.com
      rules:
        - backendRefs:
            - name: myapp
              port: 8443
```

### Multiple paths on a single hostname

Route different paths to different backend services under one hostname.

```yaml
routes:
  myapp:
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /api
          backendRefs:
            - name: myapp-api
              port: 8080
        - matches:
            - path:
                type: PathPrefix
                value: /
          backendRefs:
            - name: myapp-frontend
              port: 80
```

### Shared Gateway listener

Attach the HTTPRoute directly to an existing listener on a centrally managed Gateway.
Setting `gateway.sectionName` skips the ListenerSet entirely — no cert-manager annotation is added.

```yaml
routes:
  myapp:
    gateway:
      sectionName: https
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - backendRefs:
            - name: myapp
              port: 80
```

### Client certificate authentication

Verify an external client certificate at the ingressgateway. Requires an admin to create a dedicated
Gateway resource in `istio-ingress` (e.g. `myapp-gateway`) that attaches to the shared ingressgateway
deployment via `addresses[].value: ingressgateway-istio.istio-ingress.svc.cluster.local`. The dedicated
Gateway adds its own listener alongside the shared ingressgateway listeners.

The Gateway must reference a CA ConfigMap in the tenant namespace via
`spec.tls.frontend.default.validation.caCertificateRefs`. The ConfigMap must have a `ca.crt` key
containing the PEM-encoded CA certificate. The CA ConfigMap and the Gateway are not managed by this chart.

Enable `referenceGrant` to allow the Gateway in `istio-ingress` to read the CA ConfigMap cross-namespace.
Set `gateway.name` to the dedicated Gateway name and `gateway.sectionName` to the listener name on that Gateway.

The `x-forwarded-client-cert` header is forwarded to the backend automatically via a global EnvoyFilter.
The `ssl-client-cert` header (nginx compat) is available via a per-namespace Lua EnvoyFilter.

```yaml
referenceGrant:
  enabled: true

routes:
  myapp:
    gateway:
      name: myapp-gateway
      sectionName: https
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - backendRefs:
            - name: myapp
              port: 8080
```

### Waypoint service

Route ingressgateway traffic through a waypoint proxy for L7 policy enforcement without affecting
east-west pod-to-pod traffic. The chart creates a `<route-name>-mesh` Service with the required
Istio waypoint labels. `httpRoute.rules` defaults to a single catch-all rule pointing to
`<route-name>-mesh` when `service` is defined and no explicit rules are given.

```yaml
routes:
  myapp:
    service:
      selector:
        app: httpbin
      ports:
        - targetPort: 8080
    httpRoute:
      hostnames:
        - myapp.example.com
```

### Block paths

Deny requests to specific paths using an `AuthorizationPolicy` DENY rule.
Requires a waypoint in the traffic path for L7 policy enforcement — use the `service` field
to route through the waypoint, or deploy a namespace-level waypoint separately.

```yaml
routes:
  myapp:
    service:
      selector:
        app: myapp
      ports:
        - targetPort: 8080
    httpRoute:
      hostnames:
        - myapp.example.com
    authorizationPolicies:
      block-paths:
        action: DENY
        rules:
          - to:
              - operation:
                  paths:
                    - /metrics
                    - /auth/metrics
```

### Response headers

Add or override response headers using the `ResponseHeaderModifier` filter.

```yaml
routes:
  myapp:
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - filters:
            - type: ResponseHeaderModifier
              responseHeaderModifier:
                set:
                  - name: X-Frame-Options
                    value: SAMEORIGIN
                  - name: X-Content-Type-Options
                    value: nosniff
                  - name: Strict-Transport-Security
                    value: max-age=31536000; includeSubDomains
          backendRefs:
            - name: myapp
              port: 80
```

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
