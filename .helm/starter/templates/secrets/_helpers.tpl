{{/*
Generate certificates for ingress
*/}}
{{- define "ingress.gen-certs" -}}
{{- $ca := genCA "ingress-ca" 365 -}}
{{- $cert := genSignedCert ( $.Values.AWX.spec.hostname | required "AWX.spec.hostname is required!" ) nil nil 365 $ca -}}
tls.crt: {{ $cert.Cert | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
{{- end -}}

{{/*
Generate the name of the secret that contains the admin user password
*/}}
{{- define "admin.secretName" -}}
{{ default (printf "%s-admin-password" $.Values.AWX.name) (default $.Values.customSecrets.admin.secretName $.Values.AWX.spec.admin_password_secret) }}
{{- end }}

{{/*
Generate the name of the secret that contains the TLS information when ingress_type=route
*/}}
{{- define "routeTls.secretName" -}}
{{ default (printf "%s-route-tls" $.Values.AWX.name) (default $.Values.customSecrets.routeTls.secretName $.Values.AWX.spec.route_tls_secret) }}
{{- end }}

{{/*
Generate the name of the secret that contains the TLS information when ingress_type=ingress
*/}}
{{- define "ingressTls.secretName" -}}
{{ default (printf "%s-ingress-tls" $.Values.AWX.name) (default $.Values.customSecrets.ingressTls.secretName $.Values.AWX.spec.ingress_tls_secret) }}
{{- end }}

{{/*
Generate the name of the secret that contains the LDAP Certificate Authority
*/}}
{{- define "ldapCacert.secretName" -}}
{{ default (printf "%s-custom-certs" $.Values.AWX.name) (default ($.Values.customSecrets.ldapCacert).secretName $.Values.AWX.spec.ldap_cacert_secret) }}
{{- end }}

{{/*
Generate the name of the secret that contains the custom Certificate Authority
*/}}
{{- define "bundleCacert.secretName" -}}
{{ default (printf "%s-custom-certs" $.Values.AWX.name) (default ($.Values.customSecrets.bundleCacert).secretName $.Values.AWX.spec.bundle_cacert_secret) }}
{{- end }}

{{/*
Generate the name of the secret that contains the LDAP BIND DN password
*/}}
{{- define "ldap.secretName" -}}
{{ default (printf "%s-ldap-password" $.Values.AWX.name) (default $.Values.customSecrets.ldap.secretName $.Values.AWX.spec.ldap_password_secret) }}
{{- end }}

{{/*
Generate the name of the secret that contains the symmetric key for encryption
*/}}
{{- define "secretKey.secretName" -}}
{{ default (printf "%s-secret-key" $.Values.AWX.name) (default $.Values.customSecrets.secretKey.secretName $.Values.AWX.spec.secret_key_secret) }}
{{- end }}

{{/*
Generate the name of the secret that contains the default execution environment pull credentials
*/}}
{{- define "eePullCredentials.secretName" -}}
{{ default (printf "%s-ee-pull-credentials" $.Values.AWX.name) (default $.Values.customSecrets.eePullCredentials.secretName $.Values.AWX.spec.ee_pull_credentials_secret) }}
{{- end }}

{{/*
Generate the name of the secret that contains the default control plane pull credentials
*/}}
{{- define "cpPullCredentials.secretName" -}}
{{ default (printf "%s-cp-pull-credentials" $.Values.AWX.name) (default $.Values.customSecrets.cpPullCredentials.secretName $.Values.AWX.spec.image_pull_secrets) }}
{{- end }}

{{/*
Generate the .dockerconfigjson file unencoded.
*/}}
{{- define "dockerconfigjson.b64dec" }}
  {{- print "{\"auths\":{" }}
  {{- range $index, $item := . }}
    {{- if $index }}
      {{- print "," }}
    {{- end }}
    {{- printf "\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}" (default "https://index.docker.io/v1/" $item.registry) $item.username $item.password (default "" $item.email) (printf "%s:%s" $item.username $item.password | b64enc) }}
  {{- end }}
  {{- print "}}" }}
{{- end }}

{{/*
Generate the base64-encoded .dockerconfigjson.
*/}}
{{- define "dockerconfigjson.b64enc" }}
  {{- $list := ternary (list .) . (kindIs "map" .) }}
  {{- include "dockerconfigjson.required" $list }}
  {{- include "dockerconfigjson.b64dec" $list | b64enc }}
{{- end }}

{{/*
Required values for .dockerconfigjson
*/}}
{{- define "dockerconfigjson.required" -}}
  {{- range . -}}
    {{- $_ := required "cpPullCredentials.dockerconfigjson[].username is required!" .username -}}
    {{- $_ := required "cpPullCredentials.dockerconfigjson[].password is required!" .password -}}
  {{- end -}}
  {{/* Check for registry uniqueness */}}
  {{- $registries := list -}}
  {{- range . -}}
    {{- $registries = append $registries (default "https://index.docker.io/v1/" .registry) -}}
  {{- end -}}
  {{- $_ := required "All cpPullCredentials.dockerconfigjson[].registry's must be unique!" (or (eq (len $registries) (len ($registries | uniq))) nil) -}}
{{- end -}}

{{/*
Generate the name of the secrets
*/}}
{{- define "spec.secrets" -}}
{{- /* secret configs if enabled */}}
{{- if hasKey $.Values "customSecrets" }}
{{- with $.Values.customSecrets }}
{{- if .enabled }}
  {{- if hasKey . "admin" }}
  {{- if and (not (hasKey $.Values.AWX.spec "admin_password_secret")) .admin.enabled }}
  admin_password_secret: {{ include "admin.secretName" $ }}
  {{- end }}
  {{- end }}
  {{- if hasKey . "secretKey" }}
  {{- if and (not (hasKey $.Values.AWX.spec "secret_key_secret")) .secretKey.enabled }}
  secret_key_secret: {{ include "secretKey.secretName" $ }}
  {{- end }}
  {{- end }}
  {{- if hasKey . "routeTls" }}
  {{- if and (not (hasKey $.Values.AWX.spec "route_tls_secret")) .routeTls.enabled }}
  route_tls_secret: {{ include "routeTls.secretName" $ }}
  {{- end }}
  {{- end }}
  {{- if hasKey . "ingressTls" }}
  {{- if and (not (hasKey $.Values.AWX.spec "ingress_tls_secret")) .ingressTls.enabled }}
  ingress_tls_secret: {{ include "ingressTls.secretName" $ }}
  {{- end }}
  {{- end }}
  {{- if hasKey . "ldapCacert" }}
  {{- if and (not (hasKey $.Values.AWX.spec "ldap_cacert_secret")) .ldapCacert.enabled }}
  ldap_cacert_secret: {{ include "ldapCacert.secretName" $ }}
  {{- end }}
  {{- end }}
  {{- if hasKey . "bundleCacert" }}
  {{- if and (not (hasKey $.Values.AWX.spec "bundle_cacert_secret")) .bundleCacert.enabled }}
  bundle_cacert_secret: {{ include "bundleCacert.secretName" $ }}
  {{- end }}
  {{- end }}
  {{- if hasKey . "ldap" }}
  {{- if and (not (hasKey $.Values.AWX.spec "ldap_password_secret")) .ldap.enabled }}
  ldap_password_secret: {{ include "ldap.secretName" $ }}
  {{- end }}
  {{- end }}
  {{- if hasKey . "eePullCredentials" }}
  {{- if and (not (hasKey $.Values.AWX.spec "ee_pull_credentials_secret")) .eePullCredentials.enabled }}
  ee_pull_credentials_secret: {{ include "eePullCredentials.secretName" $ }}
  {{- end }}
  {{- end }}
  {{- if hasKey . "cpPullCredentials" }}
  {{- if and (not (hasKey $.Values.AWX.spec "image_pull_secrets")) .cpPullCredentials.enabled }}
  image_pull_secrets:
    - {{ include "cpPullCredentials.secretName" $ }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}