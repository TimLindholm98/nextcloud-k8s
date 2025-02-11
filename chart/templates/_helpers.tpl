{{- define "servicePrefix" -}}
{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}


{{- define "objectstoreEnv" -}}
- name: OBJECTSTORE_HOST
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: OBJECTSTORE_HOST
- name: OBJECTSTORE_PORT
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: OBJECTSTORE_PORT
- name: OBJECTSTORE_KEY
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: OBJECTSTORE_KEY
- name: OBJECTSTORE_SECRET
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: OBJECTSTORE_SECRET
- name: OBJECTSTORE_BUCKET
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: OBJECTSTORE_BUCKET
{{- end -}}


{{- define "postgresService" -}}
{{- if and .Values.cloudnativepg.enabled (required "cloudnativepg.databaseName is required, when cloudnativepg is enabled" .Values.cloudnativepg.databaseName) -}}
{{ .Values.cloudnativepg.databaseName }}-rw.{{ include "servicePrefix" . }}
{{- end -}}
{{- end -}}


{{- define "postgresEnv" -}}
{{- if and .Values.cloudnativepg.enabled (required "cloudnativepg.databaseName is required, when cloudnativepg is enabled" .Values.cloudnativepg.databaseName) -}}
- name: POSTGRES_HOST
  value: {{ include "postgresService" . }}
- name: POSTGRES_PORT
  valueFrom:
    secretKeyRef:
      name: {{ .Values.cloudnativepg.databaseName }}-{{ .Values.cloudnativepg.databaseName }}
      key: port
- name: POSTGRES_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.cloudnativepg.databaseName }}-{{ .Values.cloudnativepg.databaseName }}
      key: user
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.cloudnativepg.databaseName }}-{{ .Values.cloudnativepg.databaseName }}
      key: password
- name: POSTGRES_DB
  valueFrom:
    secretKeyRef:
      name: {{ .Values.cloudnativepg.databaseName }}-{{ .Values.cloudnativepg.databaseName }}
      key: dbname
{{- end -}}
{{- end -}}


{{- define "redisEnv" -}}
{{- if .Values.redis.enabled  -}}
- name: REDIS_HOST
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: REDIS_HOST
- name: REDIS_PORT
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: REDIS_PORT
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: REDIS_PASSWORD
{{- end -}}{{/* enabled */}}
{{- end -}}{{/* redisEnv */}}


{{- define "nextcloudDirectories" -}}
- name: NEXTCLOUD_DIRECTORY
  value: /var/www/html
- name: DATA_DIRECTORY
  value: /mnt/ncdata
{{- end -}}


{{- define "nextcloudCredentials" -}}
- name: NEXTCLOUD_ADMIN_USER
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: NEXTCLOUD_ADMIN_USER
- name: NEXTCLOUD_ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: NEXTCLOUD_ADMIN_PASSWORD
{{- end -}}


{{- define "trustedDomains" -}}
{{- if .Values.nextcloud.trustedDomains -}}
{{- $trustedDomains := .Values.nextcloud.trustedDomains | join " " -}}
- name: TRUSTED_DOMAINS
  value: "{{ $trustedDomains }} "
{{- else -}}
- name: TRUSTED_DOMAINS
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: TRUSTED_DOMAINS
{{- end -}}
{{- end -}}


{{- define "trustedProxies" -}}
{{- if .Values.nextcloud.trustedProxies -}}
{{- $trustedProxies := .Values.nextcloud.trustedProxies | join " " -}}
- name: TRUSTED_PROXIES
  value: "{{ $trustedProxies }}"
{{- else -}}
- name: TRUSTED_PROXIES
  valueFrom:
    secretKeyRef:
      name: nextcloud-env
      key: TRUSTED_PROXIES
{{- end -}}
{{- end -}}

