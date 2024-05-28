{{/*
Generate the name of the postgres secret, expects AWX context passed in
*/}}
{{- define "postgres.secretName" -}}
{{ default (printf "%s-postgres-configuration" .Values.AWX.name) .Values.AWX.postgres.secretName }}
{{- end }}
{{/*
Generate liste of labels
*/}}
{{- define "awx.labels" }}
{{- if hasKey .Values.AWX "labels" -}}
{{- range $key, $value := .Values.AWX.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}
{{- end }}
