<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_extra_environment"></a> [extra\_environment](#input\_extra\_environment) | List of additional environment variables | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Additional tags | `map(string)` | `{}` | no |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | Number of instances to create | `number` | `1` | no |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Instance name prefix | `string` | `"test-"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of subnet ids to use | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The id of the vpc | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The Id of the VPC |
<!-- END_TF_DOCS -->
