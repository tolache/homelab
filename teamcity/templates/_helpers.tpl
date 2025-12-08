{{- define "teamcity.selectorLabels" -}}
app: {{ .Release.Name }}
{{- end }}

{{- define "teamcity.labels" -}}
{{ include "teamcity.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
