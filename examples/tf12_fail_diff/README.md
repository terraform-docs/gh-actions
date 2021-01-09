# Test tf12 with fail on diff

## Input

```yaml
- name: Should generate README.md for tf12_fail_diff and fail on diff
  uses: ./
  with:
    working-dir: examples/tf12_fail_diff
    output-file: README.md
    fail-on-diff: true
```

## Verify

- Should inject below Usage in README.md

## Usage

<!--- BEGIN_TF_DOCS --->
### Requirements

| Name | Version |
|------|---------|
| aws | ~> 2.20.0 |
| consul | >= 2.4.0 |

### Providers

| Name | Version |
|------|---------|
| aws | ~> 2.20.0 |
| consul | >= 2.4.0 |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| extra\_environment | List of additional environment variables | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| extra\_tags | Additional tags | `map(string)` | `{}` | no |
| instance\_count | Number of instances to create | `number` | `1` | no |
| instance\_name | Instance name prefix | `string` | `"test-"` | no |
| subnet\_ids | A list of subnet ids to use | `list(string)` | n/a | yes |
| vpc\_id | The id of the vpc | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| vpc\_id | The Id of the VPC |

<!--- END_TF_DOCS --->
