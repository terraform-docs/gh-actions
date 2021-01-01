# Test tf11 basic

## Input

```yaml
- name: Should generate USAGE.md for tf11_basic
  uses: ./
  with:
    working-dir: examples/tf11_basic
    template: |
      # Test tf11 basic

      ## Verify

      Should use the template defined instead of the default
      Should inject the table under usage

      # Usage

      <!--- BEGIN_TF_DOCS --->
      <!--- END_TF_DOCS --->
    indention: 3
```

## Verify

- Should use the template defined instead of the default
- Should inject the table under usage

## Output

See USAGE.md
