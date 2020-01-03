# Test tf11 basic

## Verify
Should use the template defined instead of the default
Should inject the table under usage

# Usage
<!--- BEGIN_TF_DOCS --->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| subnet\_ids | A list of subnet ids to use | `list` | n/a | yes |
| vpc\_id | The id of the vpc | `string` | n/a | yes |
| extra\_environment | List of additional environment variables | `list` | `[]` | no |
| extra\_tags | Additional tags | `map` | `{}` | no |
| instance\_count | Number of instances to create | `string` | `"1"` | no |
| instance\_name | Instance name prefix | `string` | `"test-"` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc\_id | The Id of the VPC |
<!--- END_TF_DOCS --->
