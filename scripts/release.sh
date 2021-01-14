#!/usr/bin/env bash

set -e

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "${CURRENT_BRANCH}" != "main" ]]; then
  echo "Must be on main branch"
  exit 1
fi

NEW_VERSION=$1

if [ -z "${NEW_VERSION}" ]; then
  echo "Must have version like: v1.0.1"
  exit 1
fi

git pull origin main
git pull --tags --all -f
git tag "${NEW_VERSION}"
git push --tags
