{{- define "teamcity.selectorLabels" -}}
app: {{ .Release.Name }}
{{- end }}

{{- define "teamcity.labels" -}}
{{ include "teamcity.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- if not (regexMatch "teamcity-.*" .Release.Name) -}}
WARNING: Your release name ({{ .Release.Name }}) does not follow the recommended convention (teamcity-<env>).
{{- end -}}
