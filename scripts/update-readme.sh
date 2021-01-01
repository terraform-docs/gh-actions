#!/usr/bin/env bash

set -e

NEW_VERSION=$1

PWD=$(cd "$(dirname "$0")" && pwd -P)

if [ -z "${NEW_VERSION}" ]; then
    NEW_VERSION=$(grep "uses: terraform-docs/terraform-docs-gh-actions" "${PWD}"/../README.md | tr -s ' ' | uniq | cut -d"@" -f2)
fi

if [ -z "${NEW_VERSION}" ]; then
  echo "Must have version like: v1.0.1"
  exit 1
fi

# Update the README
VERSION=${NEW_VERSION} gomplate -d action="${PWD}"/../action.yml -f "${PWD}"/../.github/templates/README.tpl -o "${PWD}"/../README.md

echo "README.md updated."