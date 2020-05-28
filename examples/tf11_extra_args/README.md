# TF 11 Extra Args

## Input
```
- name: Should generate USAGE.md for tf11_extra_args
  uses: ./
  with:
    tf_docs_working_dir: examples/tf11_extra_args
    tf_docs_content_type: document
    tf_docs_indention: '3'
    tf_docs_args: '--no-sensitive --no-requirements --no-required'
    tf_docs_output_method: replace
```

## Verify
- Creates a document instead of table
- Indents the "##" by 3 instead of 2 ie: "###"
- Should not document required fields
- Should replace USAGE.md

# Usage
See USAGE.md
