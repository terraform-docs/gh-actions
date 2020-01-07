# Test tf11 basic

## Input
```
- name: Should generate USAGE.md for tf11_basic
  uses: ./
  with:
    tf_docs_working_dir: examples/tf11_basic
    tf_docs_template: |
      # Test tf11 basic

      ## Verify
      Should use the template defined instead of the default
      Should inject the table under usage

      # Usage
      <!--- BEGIN_TF_DOCS --->
      <!--- END_TF_DOCS --->
```

## Verify
- Should use the template defined instead of the default
- Should inject the table under usage


## Output
See USAGE.md
