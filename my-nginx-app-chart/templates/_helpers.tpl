{{- define "my-nginx-app.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "my-nginx-app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name -}}
{{- end -}}
