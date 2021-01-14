#!/usr/bin/env bash

set -e

NEW_VERSION=$1
PWD=$(cd "$(dirname "$0")" && pwd -P)

if [ -z "${NEW_VERSION}" ]; then
  echo "Must have version like: v1.0.1"
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "${CURRENT_BRANCH}" == "main" ]]; then
  git pull origin main
  git checkout -b "release/${NEW_VERSION}"
elif [[ "${CURRENT_BRANCH}" == "release/${NEW_VERSION}" ]]; then
  git pull origin main
else
  echo "Invalid branch"
  exit 1
fi

# Update the README
VERSION=$NEW_VERSION gomplate -d action="${PWD}"/../action.yml -f "${PWD}"/../.github/templates/README.tpl -o "${PWD}"/../README.md

git add "${PWD}"/../README.md
git commit -s -m "chore: prepare release ${NEW_VERSION}"
git push --set-upstream origin "release/${NEW_VERSION}"
