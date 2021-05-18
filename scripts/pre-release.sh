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
    echo "Must have version like: v1.0.1"
    exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "${CURRENT_BRANCH}" = "main" ]; then
    git pull origin main
    git checkout -b "release/${NEW_VERSION}"
elif [ "${CURRENT_BRANCH}" = "release/${NEW_VERSION}" ]; then
    git pull origin main
else
    echo "Invalid branch"
    exit 1
fi

# Update README
VERSION=$NEW_VERSION gomplate -d action="${PWD}"/../action.yml -f "${PWD}"/../.github/templates/README.tpl -o "${PWD}"/../README.md

# Update action.yml
sed -i "s|docker://quay.io/terraform-docs/gh-actions:edge|docker://quay.io/terraform-docs/gh-actions:${NEW_VERSION//v/}|g" "${PWD}"/../action.yml

git add "${PWD}"/../README.md "${PWD}"/../action.yml
git commit -s -m "chore: prepare release ${NEW_VERSION}"
git push --set-upstream origin "release/${NEW_VERSION}"
