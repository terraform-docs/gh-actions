# terraform-docs-action
A Github action for generating terraform documentation (using terraform-docs)

# Usage
<!-- Generated via jq '. | to_entries | map({name: .key, description: .value.description, default: .value.default, required: .value.required }) | map("| " + .name + " | " + .description + " | " + .default + " | " + (.required | tostring) + " |" ) | .[]' -->

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|:-----:|
| tf\_docs\_working\_dir | Directories of terraform modules to generate docs for seperated by commas (conflicts with atlantis/find dirs) | . | false |
| tf\_docs\_atlantis\_file | Generate directories by parsing an atlantis formatted yaml to enable provide the file name to parse (eg atlantis.yaml) (disabled by default) | disabled | false |
| tf\_docs\_find\_dir | Generate directories by running find ./tf\_docs\_find\_dir -name *.tf (disabled by default) | disabled | false |
| tf\_docs\_output\_file | File in module directory where the docs should be placed | USAGE.md | false |
| tf\_docs\_content\_type | Generate document or table | table | false |
| tf\_docs\_indention | Indention level of Markdown sections [1, 2, 3, 4, 5] (default 2) | 2 | false |
| tf\_docs\_args | Additional args to pass | --sort-inputs-by-required | false |
| tf\_docs\_output\_method | Method should be one of (replace/inject/print) where replace will replace the tf\_docs\_output\_file, inject will inject the content between start and close delims and print will just print the output | inject | false |
| tf\_docs\_git\_commit | If true it will add and commit the files | true | false |
| tf\_docs\_git\_push | If true it will push the committed changes | false | false |
| tf\_docs\_git\_commit\_message | Commit message | terraform-docs Automated render | false |
| tf\_docs\_template | When provided will be used as the template if/when the OUTPUT\_FILE does not exist | # Usage
\<!--- BEGIN\_TF\_DOCS --->
\<!--- END\_TF\_DOCS --->
 | false |


## Outputs
| Name | Description | Default | Required |
|------|-------------|---------|:-----:|
