# Test tf12 with config file

## Input

```yaml
- name: Should generate README.md for tf12_config
  uses: ./
  with:
    working-dir: examples/tf12_config
    output-file: README.md
    config-file: .terraform-docs.yml
```

## Verify

- Should generate based on `examples/tf12_config/.terraform-docs.yml` spec
- Should inject below Usage in README.md

## Usage

<!--- BEGIN_TF_DOCS --->
### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| subnet\_ids | A list of subnet ids to use | `list(string)` | n/a | yes |
| vpc\_id | The id of the vpc | `string` | n/a | yes |
| extra\_environment | List of additional environment variables | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| extra\_tags | Additional tags | `map(string)` | `{}` | no |
| instance\_count | Number of instances to create | `number` | `1` | no |
| instance\_name | Instance name prefix | `string` | `"test-"` | no |

<!--- END_TF_DOCS --->
