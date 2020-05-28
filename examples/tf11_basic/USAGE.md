# Test tf11 basic

# Usage
<!--- BEGIN_TF_DOCS --->
## Providers

| Name | Version |
|------|---------|
| aws | < 2.2.0 |
| consul | >= 1.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| extra\_environment | List of additional environment variables | `list` | `[]` | no |
| extra\_tags | Additional tags | `map` | `{}` | no |
| instance\_count | Number of instances to create | `string` | `"1"` | no |
| instance\_name | Instance name prefix | `string` | `"test-"` | no |
| subnet\_ids | A list of subnet ids to use | `list` | n/a | yes |
| vpc\_id | The id of the vpc | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc\_id | The Id of the VPC |

<!--- END_TF_DOCS --->
