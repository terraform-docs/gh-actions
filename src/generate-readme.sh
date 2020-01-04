#!/bin/bash
set -e

. /common.sh

export INPUT_TF_DOCS_GIT_COMMIT_MESSAGE="chore: automated release process"
cd $GITHUB_WORKSPACE

TAG_PREFIX="v"
RELEASE_BRANCH_VERSION=`git rev-parse --abbrev-ref HEAD | sed "s|release/||" | sed "s/${TAG_PREFIX}//"`
RELEASE_BRANCH_SHA=`git rev-parse HEAD`

set +e
git describe --contains "${RELEASE_BRANCH_SHA}" 2>/dev/null
IS_TAGGED=$?
set -e

if [ "${IS_TAGGED}" -eq 0 ]; then
  echo "Release is already tagged"
  exit
fi

MAJOR_VERSION=`echo $RELEASE_BRANCH_VERSION | cut -d. -f1`
MINOR_VERSION=`echo $RELEASE_BRANCH_VERSION | cut -d. -f2`
PATCH_VERSION=`echo $RELEASE_BRANCH_VERSION | cut -d. -f3`

if [ -z "$MAJOR_VERSION" ] || [ -z "$MINOR_VERSION" ] || [ -z "$PATCH_VERSION" ]; then
  echo "Invalid release branch name"
  exit 1
fi

NEW_VERSION="${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION}"

# update meta.yml
echo "major_version: ${MAJOR_VERSION}" > .github/meta.yml
echo "version: ${NEW_VERSION}" >> .github/meta.yml
git_add_doc ".github/meta.yml"

# generate README.md with version
gomplate -d action=action.yml -d meta=.github/meta.yml -f .github/templates/README.tpl -o README.md
git_add_doc "./README.md"

# generate CHANGELOG.md
git-chglog --tag-filter-pattern '^v[0-9]+.+' --next-tag "${TAG_PREFIX}${NEW_VERSION}" -o CHANGELOG.md
git_add_doc "./CHANGELOG.md"

# update the dockerfile to be locked down at this specific version
sed -i "s|FROM derekrada/terraform-docs:latest|FROM derekrada/terraform-docs:${TAG_PREFIX}${NEW_VERSION}|" ./Dockerfile
git_add_doc "./Dockerfile"

git_commit

git tag -f "${TAG_PREFIX}${RELEASE_BRANCH_VERSION}"
git push --tags
