{{- define "escape_chars" }}{{ . | strings.ReplaceAll "_" "\\_" | strings.ReplaceAll "|" "\\|" | strings.ReplaceAll "*" "\\*" }}{{- end }}
{{- define "sanatize_string" }}{{ . | strings.ReplaceAll "\n\n" "<br><br>" | strings.ReplaceAll "  \n" "<br>" | strings.ReplaceAll "\n" "<br>" | tmpl.Exec "escape_chars" }}{{- end }}
{{- $action := (datasource "action") -}}{{- $version := or (getenv "VERSION") "master" -}}
# {{ $action.name }}
{{ $action.description }} In addition to statically defined directory modules, this module can search specific sub folders or parse atlantis.yaml for module identification and doc generation.  This action has the ability to auto commit docs to an open PR or after a push to a specific branch.
## Version
{{ $version }}

Using [terraform-docs](https://github.com/segmentio/terraform-docs) v0.8.0, which is supported and tested on terraform version 0.11+ & 0.12+ but may work for others.

{{ if eq $version "master" }}
| WARNING:  You should not rely on master being stable or to have accurate documentation.  Please use a git tagged semver or major version tag like `v1`. |
| --- |
{{ end }}

# Usage
To use terraform-docs github action, configure a YAML workflow file, e.g. `.github/workflows/documentation.yml`, with the following:
```yaml
name: Generate terraform docs
on:
  - pull_request
jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        ref: {{"${{"}} github.event.pull_request.head.ref {{"}}"}}

    - name: Render terraform docs inside the USAGE.md and push changes back to PR branch
      uses: Dirrk/terraform-docs@{{ $version }}
      with:
        tf_docs_working_dir: .
        tf_docs_output_file: USAGE.md
        tf_docs_output_method: inject
        tf_docs_git_push: 'true'
```
| WARNING: If USAGE.md already exists it will need to be updated, with the block delimeters `<!--- BEGIN_TF_DOCS --->` and `<!--- END_TF_DOCS --->`, where the generated markdown will be injected. |
| --- |

### Renders
![Example](examples/example.png?raw=true "Example Output")

# Configuration

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|----------|
{{- range $key, $input := $action.inputs }}
| {{ tmpl.Exec "escape_chars" $key }} | {{ if (has $input "description") }}{{ tmpl.Exec "sanatize_string" $input.description }}{{ else }}{{ tmpl.Exec "escape_chars" $key }}{{ end }} | {{ if (has $input "default") }}{{ tmpl.Exec "sanatize_string" $input.default }}{{ else }}N/A{{ end }} | {{ if (has $input "required") }}{{ $input.required }}{{ else }}false{{ end }} |
{{- end }}

## Outputs

| Name | Description |
|------|-------------|
{{- range $key, $output := $action.outputs }}
| {{ tmpl.Exec "escape_chars" $key }} | {{ if (has $output "description") }}{{ tmpl.Exec "sanatize_string" $output.description }}{{ else }}{{ tmpl.Exec "escape_chars" $key }}{{ end }} |
{{- end }}

# Important Notes

In addition to the below notes, further documentation on terraform-docs can be found [here](https://github.com/segmentio/terraform-docs)

## Output Method (tf\_docs\_output\_method)

### print
This will just print the generated file

### replace
This will create/replace the tf\_docs\_output\_file at the determined module path(s)

### inject
Instead of replacing the output file, this will inject the generated documentation into the existing file between the predefined delimeters: `<!--- BEGIN_TF_DOCS --->` and `<!--- END_TF_DOCS --->`.  If the file exists but does not contain the delimeters, the action will fail for the given module.  If the file doesn't exist, it will create it using the value tf\_docs\_template which MUST have the delimeters.

## Auto commit changes
To enable you need to ensure a few things first:
- set tf\_docs\_git\_push to 'true'
- use actions/checkout@v2 with the head ref for PRs or branch name for pushes

### PR
```yaml
on:
  - pull_request
jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        ref: {{"${{"}} github.event.pull_request.head.ref {{"}}"}}
```

### Push
```yaml
on:
  push:
    branches:
      - master
jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        ref: master
```

## Content type (tf\_docs\_content\_type)
- document - long form document
- table - github formatted table
- json - pure json output


# Examples

## Simple / Single folder
```
- name: Generate TF Docs
  uses: Dirrk/terraform-docs@{{ $version }}
  with:
    tf_docs_working_dir: .
    tf_docs_output_file: README.md
```

## Multi folder
```
- name: Generate TF Docs
  uses: Dirrk/terraform-docs@{{ $version }}
  with:
    tf_docs_working_dir: .,example1,example3/modules/test
    tf_docs_output_file: README.md
```

## Use atlantis.yaml v3 to find all dirs
```
- name: Generate TF docs
  uses: Dirrk/terraform-docs@{{ $version }}
  with:
    tf_docs_atlantis_file: atlantis.yaml
```

## Find all .tf file folders under a given directory
```yaml
- name: Generate TF docs
  uses: Dirrk/terraform-docs@{{ $version }}
  with:
    tf_docs_find_dir: examples/
```

Complete examples can be found [here](https://github.com/Dirrk/terraform-docs/tree/{{ $version }}/examples)
