{{/*
Resolve the effective gateway for a route, merging route-level overrides with chart defaults.
*/}}
{{- define "route.gateway" -}}
{{- merge (default dict .route.gateway) .root.Values.defaults.gateway | toYaml -}}
{{- end }}

{{/*
Resolve the listener config for a given hostname index.
Uses listeners[index] if it exists, falls back to listeners[0] as a template.
Returns empty if no explicit listeners are defined.
*/}}
{{- define "route.listenerTemplate" -}}
{{- $listeners := .listeners | default list -}}
{{- if gt (len $listeners) 0 -}}
{{- index $listeners (min .index (sub (len $listeners) 1)) | toYaml -}}
{{- end -}}
{{- end }}

{{/*
Returns "true" if any listener in the route needs cert-manager to manage its TLS certificate.
Used to determine whether to add the cert-manager.io/cluster-issuer annotation.
*/}}
{{- define "route.hasCertManagerTLS" -}}
{{- $listeners := .route.listeners | default list -}}
{{- range $i := until (len ((default dict .route.httpRoute).hostnames | default list)) -}}
{{- $l := (include "route.listenerTemplate" (dict "listeners" $listeners "index" $i) | fromYaml | default dict) -}}
{{- if and (has ($l.protocol | default "HTTPS") (list "HTTPS" "TLS")) (not (default dict $l.tls).certificateRef) -}}
{{- "true" -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Renders a single ListenerSet listener entry for a given hostname and index.
Pass passthrough=true to render a TLS Passthrough listener (for TLSRoute).
Usage: include "route.listener" (dict "listeners" $listeners "index" $i "hostname" $hostname "namespace" $namespace "passthrough" false)
*/}}
{{- define "route.listener" -}}
{{- $l := (include "route.listenerTemplate" (dict "listeners" .listeners "index" .index) | fromYaml | default dict) -}}
{{- $passthrough := .passthrough | default false -}}
{{- $protocol := $l.protocol | default (ternary "TLS" "HTTPS" $passthrough) -}}
{{- $isTLS := has $protocol (list "HTTPS" "TLS") -}}
{{- $tlsCfg := default dict $l.tls -}}
{{- $mode := $tlsCfg.mode | default (ternary "Passthrough" "Terminate" $passthrough) -}}
{{- $isPassthrough := eq $mode "Passthrough" -}}
{{- $baseName := ternary "tls" (ternary "https" "http" $isTLS) $isPassthrough -}}
{{- $name := ternary (printf "%s-%d" $baseName .index) $baseName (gt .index 0) -}}
{{- if and $l.name (lt .index (len .listeners)) -}}{{- $name = $l.name -}}{{- end -}}
- name: {{ $name | quote }}
  hostname: {{ .hostname | quote }}
  protocol: {{ $protocol | quote }}
  port: {{ $l.port | default (ternary 443 80 $isTLS) }}
  {{- if $isTLS }}
  tls:
    mode: {{ $mode | quote }}
    {{- if not $isPassthrough }}
    certificateRefs:
      {{- if $tlsCfg.certificateRef }}
      - name: {{ $tlsCfg.certificateRef.name | quote }}
        kind: Secret
        namespace: {{ $tlsCfg.certificateRef.namespace | quote }}
      {{- else }}
      - name: {{ .hostname | quote }}
        kind: Secret
        namespace: {{ .namespace | quote }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Render common metadata for a route resource.
*/}}
{{- define "route.metadata" -}}
{{- include "common.metadata" (dict "root" .root "metadata" (default dict .route.metadata) "name" .name "extraAnnotations" .extraAnnotations) -}}
{{- end }}

{{- define "common.labels" -}}
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- end }}

{{- define "common.metadata" -}}
{{- $metadata := deepCopy (default dict .metadata) -}}
{{- if and .name (not (hasKey $metadata "name")) -}}
{{- $_ := set $metadata "name" .name -}}
{{- end -}}
{{- $namespace := .namespace | default .root.Release.Namespace -}}
{{- if and $namespace (not (hasKey $metadata "namespace")) -}}
{{- $_ := set $metadata "namespace" $namespace -}}
{{- end -}}
{{- $_ := set $metadata "labels" (merge (default dict $metadata.labels) (include "common.labels" .root | fromYaml)) -}}
{{- $annotations := merge (default dict .extraAnnotations) (default dict $metadata.annotations) -}}
{{- if $annotations -}}
{{- $_ := set $metadata "annotations" $annotations -}}
{{- end -}}
{{- toYaml $metadata -}}
{{- end }}
