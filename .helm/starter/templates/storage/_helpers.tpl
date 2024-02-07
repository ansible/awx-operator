{{/*
Generate the name of the persistent volume for postgres folders
*/}}
{{- define "postgres.persistentVolumeName" -}}
{{ printf "%s-postgres-volume" $.Values.AWX.name }}
{{- end }}

{{/*
Generate the name of the persistent volume for projects folder
*/}}
{{- define "projects.persistentVolumeName" -}}
{{ printf "%s-projects-volume" $.Values.AWX.name }}
{{- end }}

{{/*
Generate the name of the persistent volume claim for the projects volume
*/}}
{{- define "projects.persistentVolumeClaim" -}}
{{ printf "%s-projects-claim" $.Values.AWX.name }}
{{- end }}

{{/*
Generate the name of the storage class to use for the postgres volume
*/}}
{{- define "postgres.storageClassName" -}}
{{ default (printf "%s-postgres-volume" $.Values.AWX.name) (default $.Values.AWX.spec.postgres_storage_class (($.Values.customVolumes).postgres).storageClassName) }}
{{- end }}

{{/*
Generate the name of the storage class to use for the projects volume
*/}}
{{- define "projects.storageClassName" -}}
{{ default (printf "%s-projects-volume" $.Values.AWX.name) (default $.Values.AWX.spec.projects_storage_class (($.Values.customVolumes).projects).storageClassName) }}
{{- end }}

{{/*
Generate the name of the storage class names, expects AWX context passed in
*/}}
{{- define "spec.storageClassNames" -}}
{{- if and (not $.Values.AWX.postgres.enabled) (eq (($.Values.AWX.spec).postgres_configuration_secret | default "") "") -}}
{{- if (($.Values.customVolumes).postgres).enabled -}}
  {{- if not (hasKey $.Values.AWX.spec "postgres_storage_class") }}
  postgres_storage_class: {{ include "postgres.storageClassName" $ }}    
  {{- end }}
  {{- if not (hasKey $.Values.AWX.spec "postgres_storage_requirements") }}
  postgres_storage_requirements:
    requests:
      storage: {{ default "8Gi" $.Values.customVolumes.postgres.size | quote }}
  {{- end }}
{{- end }}
{{- end }}
{{- if and ($.Values.AWX.spec.projects_persistence) (eq (($.Values.AWX.spec).projects_existing_claim | default "") "") -}}
{{- if (($.Values.customVolumes).projects).enabled }}
  projects_existing_claim: {{ include "projects.persistentVolumeClaim" $ }} 
{{- end }}
{{- end }}
{{- end }}