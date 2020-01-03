{{- define "escape_chars" }}{{ . | strings.ReplaceAll "_" "\\_" | strings.ReplaceAll "|" "\\|" | strings.ReplaceAll "*" "\\*" }}{{- end }}
{{- define "sanatize_string" }}{{ . | strings.ReplaceAll "\n\n" "<br><br>" | strings.ReplaceAll "  \n" "<br>" | strings.ReplaceAll "\n" "<br>" | tmpl.Exec "escape_chars" }}{{- end }}
{{- $config := (datasource "config") -}}
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
{{- range $index, $input := $config.inputs }}
| {{ tmpl.Exec "escape_chars" $input.name }} | {{ if (has $input "description") }}{{ tmpl.Exec "sanatize_string" $input.description }}{{ else }}{{ tmpl.Exec "escape_chars" $input.name }}{{ end }} | {{ tmpl.Exec "sanatize_string" $input.type }} | {{ if (has $input "default") }}{{ tmpl.Exec "sanatize_string" $input.default }} | no {{ else }}n/a | yes {{ end }}|
{{- end }}

## Outputs

| Name | Description |
|------|-------------|
{{- range $index, $output := $config.outputs }}
| {{ tmpl.Exec "escape_chars" $output.name }} | {{ if (has $output "description") }}{{ tmpl.Exec "sanatize_string" $output.description }}{{ else }}{{ tmpl.Exec "escape_chars" $output.name }}{{ end }} |
{{- end }}
