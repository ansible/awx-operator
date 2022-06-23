{{/*
Generate the name of the postgres secret, expects AWX context passed in
*/}}
{{- define "postgres.secretName" -}}
{{ default (printf "%s-postgres-configuration" .Values.AWX.name) .Values.AWX.postgres.secretName }}
{{- end }}
