# Test tf11 basic extra args

## Input

```yaml
- name: Should generate USAGE.md for tf11_extra_args
  uses: ./
  with:
    working-dir: examples/tf11_extra_args
    output-format: markdown document
    output-file: USAGE.md
    output-method: replace
    args: --sensitive=false --hide requirements --required=false
    indention: 3
```

## Verify

- Should not have requirements section
- Should not have sensitive and required columns

## Output

See USAGE.md
