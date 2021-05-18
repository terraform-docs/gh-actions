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

PWD=$(cd "$(dirname "$0")" && pwd -P)

if [ -z "${NEW_VERSION}" ]; then
    NEW_VERSION=$(grep "uses: terraform-docs/gh-actions" "${PWD}"/../README.md | tr -s ' ' | uniq | cut -d"@" -f2)
fi

if [ -z "${NEW_VERSION}" ]; then
    echo "Must have version like: v1.0.1"
    exit 1
fi

# Update the README
VERSION=${NEW_VERSION} gomplate -d action="${PWD}"/../action.yml -f "${PWD}"/../.github/templates/README.tpl -o "${PWD}"/../README.md

echo "README.md updated."
