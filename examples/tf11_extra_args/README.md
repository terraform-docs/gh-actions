# Test tf11 extra args

## Input

```yaml
- name: Should generate USAGE.md for tf11_extra_args
  uses: ./
  with:
    working-dir: examples/tf11_extra_args
    output-format: markdown document
    output-method: replace
    args: --sensitive=false --hide requirements --required=false
    indention: 3
```

## Verify

- Creates a document instead of table
- Indents the "##" by 3 instead of 2 ie: "###"
- Should not show required fields
- Should replace USAGE.md

## Usage

See USAGE.md
