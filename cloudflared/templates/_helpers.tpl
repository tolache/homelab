{{- define "cloudflared.selectorLabels" -}}
app: {{ .Release.Name }}
{{- end }}

{{- define "cloudflared.labels" -}}
{{ include "cloudflared.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- if not (regexMatch "cloudflared-.*" .Release.Name) -}}
WARNING: Your release name ({{ .Release.Name }}) does not follow the recommended convention (cloudflared-<env>).
{{- end -}}