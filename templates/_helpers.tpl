{{/*
Expand the name of the chart.
*/}}
{{- define "blocky.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "blocky.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "blocky.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "blocky.labels" -}}
helm.sh/chart: {{ include "blocky.chart" . }}
{{ include "blocky.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "blocky.selectorLabels" -}}
app.kubernetes.io/name: {{ include "blocky.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "blocky.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "blocky.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "blocky.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end }}

{{/*
Return the MySQL secret name
*/}}
{{- define "blocky.mysql.secretName" -}}
{{- if .Values.config.queryLog.mysql.external.hostname -}}
{{- .Values.config.queryLog.mysql.external.secretName -}}
{{- else if .Values.config.queryLog.mysql.existingSecret -}}
{{- .Values.config.queryLog.mysql.existingSecret -}}
{{- else -}}
{{- include "blocky.fullname" . -}}-mysql
{{- end -}}
{{- end }}

{{/*
Return the MySQL secret key
*/}}
{{- define "blocky.mysql.secretKey" -}}
{{- if .Values.config.queryLog.mysql.external.hostname -}}
{{- .Values.config.queryLog.mysql.external.secretKey -}}
{{- else -}}
mysql-password
{{- end -}}
{{- end }}

{{/*
Return the MySQL host
*/}}
{{- define "blocky.mysql.host" -}}
{{- if .Values.config.queryLog.mysql.external.hostname -}}
{{- .Values.config.queryLog.mysql.external.hostname -}}
{{- else -}}
{{- include "blocky.fullname" . -}}-mysql
{{- end -}}
{{- end }}

{{/*
Return the MySQL port
*/}}
{{- define "blocky.mysql.port" -}}
{{- if .Values.config.queryLog.mysql.external.hostname -}}
{{- .Values.config.queryLog.mysql.external.port -}}
{{- else -}}
3306
{{- end -}}
{{- end }}

{{/*
Return the PostgreSQL secret name
*/}}
{{- define "blocky.postgresql.secretName" -}}
{{- if .Values.config.queryLog.postgresql.external.hostname -}}
{{- .Values.config.queryLog.postgresql.external.secretName -}}
{{- else if .Values.config.queryLog.postgresql.existingSecret -}}
{{- .Values.config.queryLog.postgresql.existingSecret -}}
{{- else -}}
{{- include "blocky.fullname" . -}}-postgresql
{{- end -}}
{{- end }}

{{/*
Return the PostgreSQL secret key
*/}}
{{- define "blocky.postgresql.secretKey" -}}
{{- if .Values.config.queryLog.postgresql.external.hostname -}}
{{- .Values.config.queryLog.postgresql.external.secretKey -}}
{{- else -}}
postgresql-password
{{- end -}}
{{- end }}

{{/*
Return the PostgreSQL host
*/}}
{{- define "blocky.postgresql.host" -}}
{{- if .Values.config.queryLog.postgresql.external.hostname -}}
{{- .Values.config.queryLog.postgresql.external.hostname -}}
{{- else -}}
{{- include "blocky.fullname" . -}}-postgresql
{{- end -}}
{{- end }}

{{/*
Return the PostgreSQL port
*/}}
{{- define "blocky.postgresql.port" -}}
{{- if .Values.config.queryLog.postgresql.external.hostname -}}
{{- .Values.config.queryLog.postgresql.external.port -}}
{{- else -}}
5432
{{- end -}}
{{- end }}

{{/*
Validate queryLog type
*/}}
{{- define "blocky.validateQueryLogType" -}}
{{- $validTypes := list "none" "mysql" "postgresql" "console" -}}
{{- if not (has .Values.config.queryLog.type $validTypes) -}}
{{- fail (printf "Invalid queryLog.type '%s'. Must be one of: %s" .Values.config.queryLog.type (join ", " $validTypes)) -}}
{{- end -}}
{{- end }}

{{/*
Return the MySQL password (for embedding in config)
*/}}
{{- define "blocky.mysql.password" -}}
{{- if .Values.config.queryLog.mysql.external.hostname -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace .Values.config.queryLog.mysql.external.secretName -}}
{{- if $secret -}}
{{- index $secret.data .Values.config.queryLog.mysql.external.secretKey | b64dec -}}
{{- end -}}
{{- else if .Values.config.queryLog.mysql.existingSecret -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace .Values.config.queryLog.mysql.existingSecret -}}
{{- if $secret -}}
{{- index $secret.data "mysql-password" | b64dec -}}
{{- end -}}
{{- else -}}
{{- $secretName := printf "%s-mysql" (include "blocky.fullname" .) -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if $secret -}}
{{- index $secret.data "mysql-password" | b64dec -}}
{{- else -}}
{{- randAlphaNum 16 -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Return the PostgreSQL password (for embedding in config)
*/}}
{{- define "blocky.postgresql.password" -}}
{{- if .Values.config.queryLog.postgresql.external.hostname -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace .Values.config.queryLog.postgresql.external.secretName -}}
{{- if $secret -}}
{{- index $secret.data .Values.config.queryLog.postgresql.external.secretKey | b64dec -}}
{{- end -}}
{{- else if .Values.config.queryLog.postgresql.existingSecret -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace .Values.config.queryLog.postgresql.existingSecret -}}
{{- if $secret -}}
{{- index $secret.data "postgresql-password" | b64dec -}}
{{- end -}}
{{- else -}}
{{- $secretName := printf "%s-postgresql" (include "blocky.fullname" .) -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if $secret -}}
{{- index $secret.data "postgresql-password" | b64dec -}}
{{- else -}}
{{- randAlphaNum 16 -}}
{{- end -}}
{{- end -}}
{{- end }}
