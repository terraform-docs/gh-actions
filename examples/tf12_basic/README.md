# Test TF12 Basic

## Input
```
- name: Should inject into README.md
  uses: ./
  with:
    tf_docs_working_dir: examples/tf12_basic
    tf_docs_output_file: README.md
```

## Verify
- Should inject below Usage in README.md

# Usage

<!--- BEGIN_TF_DOCS --->
<!--- END_TF_DOCS --->
