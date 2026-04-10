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
| defaults | object | `{"clusterIssuer":"letsencrypt-prod-istio","gateway":{"name":"ingressgateway","namespace":"istio-ingress"}}` | Default values shared across all routes. |
| defaults.gateway | object | `{"name":"ingressgateway","namespace":"istio-ingress"}` | Default gateway to attach ListenerSets to. |
| defaults.gateway.name | string | "ingressgateway" | Gateway name. |
| defaults.gateway.namespace | string | "istio-ingress" | Gateway namespace. |
| defaults.clusterIssuer | string | "letsencrypt-prod-istio" | Default cert-manager cluster issuer for TLS certificates. |

### Routes

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| routes | object | {} | Map of routes to render. Each top-level key becomes the name of the ListenerSet and HTTPRoute. See [Examples](#examples) for usage. |
| routes.\<name>.metadata.name | string | "" | Optional. Override the rendered resource name. |
| routes.\<name>.metadata.namespace | string | "" | Optional. Override the rendered resource namespace. |
| routes.\<name>.metadata.labels | object | {} | Optional. Additional labels merged with common labels on all resources for this route. |
| routes.\<name>.metadata.annotations | object | {} | Optional. Annotations added to all resources for this route. The cert-manager.io/cluster-issuer annotation is managed via clusterIssuer. |
| routes.\<name>.gateway | object | `{"name":"ingressgateway","namespace":"istio-ingress","sectionName":""}` | Optional. Override the default gateway for this route. |
| routes.\<name>.gateway.sectionName | string | "" | Optional. Gateway listener section name. When set, the ListenerSet is skipped and the HTTPRoute attaches directly to the named Gateway listener section. Use this when a listener is managed on the Gateway itself rather than via a per-tenant ListenerSet. |
| routes.\<name>.clusterIssuer | string | `"letsencrypt-prod-istio"` | Optional. Override the default cert-manager cluster issuer for this route. |
| routes.\<name>.listeners | list | auto-generated from httpRoute.hostnames with HTTPS defaults | Optional. Listener overrides for the ListenerSet. Hostnames always come from `httpRoute.hostnames` — one listener is rendered per hostname. When `listeners` has fewer entries than hostnames, the first entry is used as a template for remaining hostnames. When omitted entirely, HTTPS with all defaults is used. Use explicit listeners only when you need non-default protocol, port, or TLS settings. |
| routes.\<name>.listeners[0].name | string | "https" / "http" based on protocol; "https-N" / "http-N" for additional listeners | Optional. Listener name. Must be unique within the ListenerSet. |
| routes.\<name>.listeners[0].protocol | string | "HTTPS" | Optional. Protocol. HTTPS or HTTP. |
| routes.\<name>.listeners[0].port | int | 443 for HTTPS/TLS, 80 for HTTP | Optional. Port. |
| routes.\<name>.listeners[0].tls | object | `{"certificateRef":{"name":"shared-cert","namespace":"istio-ingress"},"mode":"Terminate"}` | Optional. TLS configuration. Defaults to Terminate mode with a Secret named after the hostname, managed by cert-manager via the clusterIssuer default. |
| routes.\<name>.listeners[0].tls.mode | string | "Terminate" | Optional. TLS mode. |
| routes.\<name>.listeners[0].tls.certificateRef | object | Secret named after the listener hostname in the route namespace | Optional. Override the certificate reference. When set, the cert-manager.io/cluster-issuer annotation is omitted. Use this to reference a certificate Secret managed outside the chart. Requires a ReferenceGrant in the target namespace if the secret is in a different namespace than the ListenerSet. |
| routes.\<name>.listeners[0].tls.certificateRef.name | string | `"shared-cert"` | Required when certificateRef is set. Secret name. |
| routes.\<name>.listeners[0].tls.certificateRef.namespace | string | `"istio-ingress"` | Required when certificateRef is set. Secret namespace. |
| routes.\<name>.httpRoute | object | `{"hostnames":["myapp.example.com","new-myapp.example.com"],"rules":[{"backendRefs":[{"name":"my-service","port":80,"weight":100}],"filters":[{"type":"URLRewrite","urlRewrite":{"path":{"replacePrefixMatch":"/","type":"ReplacePrefixMatch"}}}],"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]}` | Required. HTTPRoute configuration. |
| routes.\<name>.httpRoute.hostnames | list | collected from listeners[].hostname | Optional. Hostnames for the HTTPRoute and auto-generated ListenerSet listeners. When `listeners` is omitted, one HTTPS listener is auto-generated per hostname here. When `listeners` is set, this field is unused for the ListenerSet — hostnames are collected from the listener entries instead. Required when `gateway.sectionName` is set (no ListenerSet rendered). |
| routes.\<name>.httpRoute.rules | list | `[{"backendRefs":[{"name":"my-service","port":80,"weight":100}],"filters":[{"type":"URLRewrite","urlRewrite":{"path":{"replacePrefixMatch":"/","type":"ReplacePrefixMatch"}}}],"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]` | Required. Routing rules. |
| routes.\<name>.httpRoute.rules[0].matches | list | `[{"path":{"type":"PathPrefix","value":"/"}}]` | Optional. Match conditions (path, headers, method). If omitted, the rule matches all requests. |
| routes.\<name>.httpRoute.rules[0].filters | list | `[{"type":"URLRewrite","urlRewrite":{"path":{"replacePrefixMatch":"/","type":"ReplacePrefixMatch"}}}]` | Optional. Filters to apply (URLRewrite, RequestRedirect, RequestHeaderModifier). |
| routes.\<name>.httpRoute.rules[0].backendRefs | list | `[{"name":"my-service","port":80,"weight":100}]` | Required. Backend services to forward matched requests to. |
| routes.\<name>.httpRoute.rules[0].backendRefs[0].name | string | `"my-service"` | Required. Service name. |
| routes.\<name>.httpRoute.rules[0].backendRefs[0].port | int | `80` | Required. Service port. |
| routes.\<name>.httpRoute.rules[0].backendRefs[0].weight | int | "" | Optional. Traffic weight (0-100). Used for traffic splitting. |
| routes.\<name>.authorizationPolicies | object | {} | Optional. Map of AuthorizationPolicy resources for this route. Each key becomes part of the policy name: <route-name>-<key>. |
| routes.\<name>.authorizationPolicies.\<policy-name>.metadata.name | string | "<route-name>-<policy-name>" | Optional. Override the rendered AuthorizationPolicy name. |
| routes.\<name>.authorizationPolicies.\<policy-name>.metadata.labels | object | {} | Optional. Additional labels for this AuthorizationPolicy. |
| routes.\<name>.authorizationPolicies.\<policy-name>.metadata.annotations | object | {} | Optional. Annotations for this AuthorizationPolicy. |
| routes.\<name>.authorizationPolicies.\<policy-name>.targetRefs | list | `[{"group":"","kind":"Service","name":"my-service"}]` | Optional. Target refs for the policy. Defaults to the first backendRef service if not set. kind defaults to "Service", group defaults to "". |
| routes.\<name>.authorizationPolicies.\<policy-name>.action | string | "DENY" | Optional. Policy action. |
| routes.\<name>.authorizationPolicies.\<policy-name>.rules | list | `[{"from":[{"source":{"notRemoteIpBlocks":["1.2.3.4/32"]}}]}]` | Required. Authorization rules. |

## Hostname resolution

Hostnames are always defined in `httpRoute.hostnames` — they flow to both the `ListenerSet` and `HTTPRoute`.
The `listeners` field controls only protocol, port, and TLS settings — never hostnames.

| Configuration | ListenerSet listeners | HTTPRoute hostnames |
|---|---|---|
| No `listeners` | One HTTPS listener auto-generated per hostname | From `httpRoute.hostnames` |
| `listeners` with one entry | That entry used as a template for all hostnames | From `httpRoute.hostnames` |
| `listeners` with N entries | Entries matched 1:1 to hostnames; first entry used as template for any extras | From `httpRoute.hostnames` |
| `gateway.sectionName` set | No ListenerSet rendered | From `httpRoute.hostnames` |

## Examples

Each `routes` entry renders a `ListenerSet`, an `HTTPRoute`, and optionally one or more `AuthorizationPolicy` resources.
By default, the chart renders nothing — routes are created only when explicitly configured.

### Simple route

Forward all traffic for a hostname to a backend service.
Hostname is defined once in `httpRoute.hostnames` — the HTTPS listener is auto-generated.

```yaml
routes:
  httpbingo:
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - backendRefs:
            - name: myapp
```

### HTTP route

Expose a service over plain HTTP. Explicit `listeners` are required to override the default HTTPS protocol.

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
```

### IP allowlist

Deny all traffic not originating from the specified IP ranges using an `AuthorizationPolicy`.

```yaml
routes:
  myapp:
    httpRoute:
      hostnames:
        - myapp.example.com
      rules:
        - backendRefs:
            - name: myapp
    authorizationPolicies:
      ip-allowlist:
        rules:
          - from:
              - source:
                  notRemoteIpBlocks:
                    - "1.2.3.4/32"
                    - "10.0.0.0/8"
```

### Shared Gateway listener

Attach the HTTPRoute directly to an existing listener on the Gateway (e.g. a shared HTTPS listener
with a certificate managed centrally). Setting `gateway.sectionName` skips the ListenerSet entirely —
no ListenerSet is rendered and no cert-manager annotation is added.
`httpRoute.hostnames` is required since there are no listeners to collect from.

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
```

### Path rewrite

Strip a path prefix before forwarding to the backend.
Useful when the application is mounted at `/` but exposed at a subpath.

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
                value: /myapp
          filters:
            - type: URLRewrite
              urlRewrite:
                path:
                  type: ReplacePrefixMatch
                  replacePrefixMatch: /
          backendRefs:
            - name: myapp
```

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
