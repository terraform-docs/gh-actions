## Requirements

| Name | Version |
|------|---------|
| aws | < 2.2.0 |
| consul | >= 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | < 2.2.0 |
| consul | >= 1.0.0 |

## Modules

No Modules.

## Resources

| Name |
|------|
| [aws_acm_certificate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) |
| [consul_key](https://registry.terraform.io/providers/hashicorp/consul/latest/docs/data-sources/key) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
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
