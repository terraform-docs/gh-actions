#!/usr/bin/env bash
#
# Copyright 2021 The terraform-docs Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o pipefail
set -o errtrace

NEW_VERSION=$1
TF_DOCS_VERSION=$2

PWD=$(cd "$(dirname "$0")" && pwd -P)

if [ -z "${NEW_VERSION}" ]; then
    NEW_VERSION=$(grep "uses: terraform-docs/gh-actions" "${PWD}"/../../README.md | tr -s ' ' | uniq | cut -d"@" -f2)
fi
if [ -z "${NEW_VERSION}" ]; then
    echo "Usage: pre-release.sh <NEW_VERSION> <TF_DOCS_VERSION>"
    exit 1
fi

if [ -z "${TF_DOCS_VERSION}" ]; then
    TF_DOCS_VERSION=$(grep "FROM quay.io/terraform-docs/terraform-docs" "${PWD}"/../../Dockerfile | tr -s ' ' | uniq | cut -d":" -f2)
fi
if [ -z "${TF_DOCS_VERSION}" ]; then
    echo "Usage: pre-release.sh <NEW_VERSION> <TF_DOCS_VERSION>"
    exit 1
fi

# Update README
VERSION=v${NEW_VERSION//v/} TERRAFORM_DOCS_VERSION=v${TF_DOCS_VERSION//v/} \
    gomplate \
    -d action="${PWD}"/../../action.yml \
    -f "${PWD}"/../../.github/templates/README.tpl \
    -o "${PWD}"/../../README.md

# Update Dockerfile
sed -i -E "s|FROM quay.io/terraform-docs/terraform-docs:(.*)|FROM quay.io/terraform-docs/terraform-docs:${TF_DOCS_VERSION//v/}|g" "${PWD}"/../../Dockerfile

# Update action.yml
sed -i -E "s|docker://quay.io/terraform-docs/gh-actions:(.*)\"|docker://quay.io/terraform-docs/gh-actions:${NEW_VERSION//v/}\"|g" "${PWD}"/../../action.yml

if [ "$(git status --porcelain | grep -c 'M README.md')" -eq 1 ]; then
    echo "Modified: README.md"
fi
if [ "$(git status --porcelain | grep -c 'M Dockerfile')" -eq 1 ]; then
    echo "Modified: Dockerfile"
fi
if [ "$(git status --porcelain | grep -c 'M action.yml')" -eq 1 ]; then
    echo "Modified: action.yml"
fi
