#!/usr/bin/env bash
set -e

NEW_VERSION=$1

if [ -z "${NEW_VERSION}" ]; then
  echo "Must have version like: v1.0.1"
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "${CURRENT_BRANCH}" == "master" ]]; then
  git pull origin master
  git checkout -b "release/${NEW_VERSION}"
elif [[ "${CURRENT_BRANCH}" == "release/${NEW_VERSION}" ]]; then
  git pull origin master
else
  echo "Invalid branch"
  exit 1
fi

# Update the README
VERSION=$NEW_VERSION gomplate -d action=action.yml -f .github/templates/README.tpl -o README.md

# Update Dockerfile
gsed -i "s|FROM derekrada/terraform-docs:.*|FROM derekrada/terraform-docs:${NEW_VERSION}|" ./Dockerfile

git commit -am "chore: prepare release ${NEW_VERSION}"
git push --set-upstream origin "release/${NEW_VERSION}"
