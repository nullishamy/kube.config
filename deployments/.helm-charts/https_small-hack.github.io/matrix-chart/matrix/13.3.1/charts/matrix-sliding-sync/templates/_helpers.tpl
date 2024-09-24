{{/*
Expand the name of the chart.
*/}}
{{- define "matrix-sliding-sync.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "matrix-sliding-sync.fullname" -}}
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
{{- define "matrix-sliding-sync.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "matrix-sliding-sync.labels" -}}
helm.sh/chart: {{ include "matrix-sliding-sync.chart" . }}
{{ include "matrix-sliding-sync.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "matrix-sliding-sync.selectorLabels" -}}
app.kubernetes.io/name: {{ include "matrix-sliding-sync.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "matrix-sliding-sync.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "matrix-sliding-sync.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Helper function to get postgres instance name
*/}}
{{- define "matrix-sliding-sync.postgresql.hostname" -}}
{{- if .Values.postgresql.enabled -}}
{{ template "postgresql.v1.primary.fullname" .Subcharts.postgresql }}
{{- else -}}
{{- .Values.externalDatabase.hostname -}}
{{- end }}
{{- end }}

{{/*
Helper function to get the postgres secret containing the database credentials
*/}}
{{- define "matrix-sliding-sync.postgresql.secretName" -}}
{{- if and .Values.postgresql.enabled .Values.postgresql.global.postgresql.auth.existingSecret -}}
{{ .Values.postgresql.global.postgresql.auth.existingSecret }}
{{- else if and .Values.externalDatabase.enabled .Values.externalDatabase.existingSecret -}}
{{ .Values.externalDatabase.existingSecret }}
{{- else -}}
{{ template "matrix-sliding-sync.fullname" . }}-db-secret
{{- end }}
{{- end }}

{{/*
Helper function to get postgres hostname secret key
*/}}
{{- define "matrix-sliding-sync.postgresql.secretKeys.hostname" -}}
{{- if and .Values.postgresql.enabled .Values.postgresql.global.postgresql.auth.existingSecret -}}
{{- .Values.postgresql.global.postgresql.auth.secretKeys.databaseHostname -}}
{{- else if and .Values.externalDatabase.enabled .Values.externalDatabase.existingSecret -}}
{{- .Values.externalDatabase.secretKeys.databaseHostname -}}
{{- else -}}
{{- printf "hostname" }}
{{- end }}
{{- end }}

{{/*
Helper function to get postgres database secret key
*/}}
{{- define "matrix-sliding-sync.postgresql.secretKeys.database" -}}
{{- if and .Values.postgresql.enabled .Values.postgresql.global.postgresql.auth.existingSecret -}}
{{- .Values.postgresql.global.postgresql.auth.secretKeys.database -}}
{{- else if and .Values.externalDatabase.enabled .Values.externalDatabase.existingSecret -}}
{{- .Values.externalDatabase.secretKeys.database -}}
{{- else -}}
{{- printf "database" }}
{{- end }}
{{- end }}

{{/*
Helper function to get postgres user secret key
*/}}
{{- define "matrix-sliding-sync.postgresql.secretKeys.user" -}}
{{- if and .Values.postgresql.enabled .Values.postgresql.global.postgresql.auth.existingSecret -}}
{{- .Values.postgresql.global.postgresql.auth.secretKeys.databaseUsername -}}
{{- else if and .Values.externalDatabase.enabled .Values.externalDatabase.existingSecret -}}
{{- .Values.externalDatabase.secretKeys.databaseUsername -}}
{{- else -}}
{{- printf "username" }}
{{- end }}
{{- end }}

{{/*
Helper function to get postgres password secret key
*/}}
{{- define "matrix-sliding-sync.postgresql.secretKeys.password" -}}
{{- if and .Values.postgresql.enabled .Values.postgresql.global.postgresql.auth.existingSecret -}}
{{- .Values.postgresql.global.postgresql.auth.secretKeys.userPasswordKey -}}
{{- else if and .Values.externalDatabase.enabled .Values.externalDatabase.existingSecret -}}
{{- .Values.externalDatabase.secretKeys.userPasswordKey -}}
{{- else -}}
{{- printf "password" }}
{{- end }}
{{- end }}

{{/*
Helper function to get postgres ssl mode
*/}}
{{- define "matrix-sliding-sync.postgresql.sslEnvVars" -}}
{{- if and .Values.postgresql.enabled .Values.postgresql.sslmode -}}
- name: PGSSLMODE
  value: {{ .Values.postgresql.sslmode }}
- name: PGSSLCERT
  value: {{ .Values.postgresql.sslcert }}
- name: PGSSLKEY
  value: {{ .Values.postgresql.sslkey }}
- name: PGSSLROOTCERT
  value: {{ .Values.postgresql.sslrootcert }}
{{- else if .Values.externalDatabase.enabled -}}
- name: PGSSLMODE
  value: {{ .Values.externalDatabase.sslmode }}
- name: PGSSLCERT
  value: {{ .Values.externalDatabase.sslcert }}
- name: PGSSLKEY
  value: {{ .Values.externalDatabase.sslkey }}
- name: PGSSLROOTCERT
  value: {{ .Values.externalDatabase.sslrootcert }}
{{- end }}
{{- end }}

{{/*
templates out SYNCV3_DB which is a postgres connection string: https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING
*/}}
{{- define "matrix-sliding-sync.dbConnString" -}}
{{- if and (not .Values.existingEnvSecret) (not .Values.syncv3.existingDbSecret) }}
{{- if .Values.postgresql.enabled }}
{{- printf "user=%s dbname=%s host=%s sslmode=disable password=%s" .Values.postgresql.global.postgresql.auth.username .Values.postgresql.global.postgresql.auth.database (include "matrix-sliding-sync.postgresql.hostname" .) .Values.postgresql.global.postgresql.auth.password }}
{{- else if and .Values.externalDatabase.enabled .Values.externalDatabase.sslmode }}
{{- printf "user=%s dbname=%s host=%s sslmode=%s sslkey=%s sslcert=%s sslrootcert=%s" .Values.externalDatabase.username .Values.externalDatabase.database .Values.externalDatabase.hostname .Values.externalDatabase.sslmode .Values.externalDatabase.sslkey .Values.externalDatabase.sslcert .Values.externalDatabase.sslrootcert }}
{{- else if and .Values.externalDatabase.enabled .Values.externalDatabase.password }}
{{- printf "user=%s dbname=%s sslmode=disable host=%s password=%s" .Values.externalDatabase.username .Values.externalDatabase.database .Values.externalDatabase.hostname .Values.externalDatabase.password }}
{{- else if .Values.syncv3.db }}
{{- .Values.syncv3.db }}
{{- end }}
{{- end }}{{/* end if existing db secrets and not syncv3.db */}}
{{- end }}{{/* end define matrix-sliding-sync.dbConnString */}}
