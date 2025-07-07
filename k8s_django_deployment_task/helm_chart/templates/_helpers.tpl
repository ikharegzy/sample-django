{{/*
Return full name (release-name‐chart-name)
*/}}
{{- define "django-sample.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}
