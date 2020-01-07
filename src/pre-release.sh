#!/bin/bash
set -e

. /common.sh

export INPUT_TF_DOCS_GIT_COMMIT_MESSAGE="chore: automated release process"
cd $GITHUB_WORKSPACE
git_setup

export TAG_PREFIX="v"
export MAJOR_VERSION=0
export MINOR_VERSION=0
export PATCH_VERSION=1
export NEW_VERSION="${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION}"

parse_version () {
  VERSION="${1}"
  MAJOR_VERSION=`echo $VERSION | cut -d. -f1`
  MINOR_VERSION=`echo $VERSION | cut -d. -f2`
  PATCH_VERSION=`echo $VERSION | cut -d. -f3`

  if [ -z "$MAJOR_VERSION" ] || [ -z "$MINOR_VERSION" ] || [ -z "$PATCH_VERSION" ]; then
    echo "failed to parse version=${VERSION}"
    exit 1
  fi
  NEW_VERSION=${VERSION}
}

is_sha_tagged () {
  set +e
  git describe --contains "${SHA}" 2>/dev/null
  IS_TAGGED=$?
  set -e

  if [ "${IS_TAGGED}" -eq 0 ]; then
    echo "Release is already tagged"
    exit
  fi
}

create_release () {

  # update the meta.yml only done for v1.x.x
  update_meta "${NEW_VERSION}"

  # update the readme unaffected by major_version changes
  update_readme

  # replace the module Dockerfile only done for v1.x.x
  overwrite_docker_tag "${TAG_PREFIX}${NEW_VERSION}"

  # generate changelog.md for the next tag
  git-chglog --tag-filter-pattern '^v[0-9]+.+' \
    --next-tag "${TAG_PREFIX}${NEW_VERSION}" \
    "${TAG_PREFIX}${NEW_VERSION}" \
    -o /tmp/tag_msg.md

  git-chglog --tag-filter-pattern '^v[0-9]+.+' --next-tag "${TAG_PREFIX}${NEW_VERSION}" -o CHANGELOG.md
  git_add_doc "./CHANGELOG.md"

  # commit and push
  git_commit
  git push
  git tag -f "${TAG_PREFIX}${NEW_VERSION}" -a --file /tmp/tag_msg.md
  git push --tags
}

RELEASE_BRANCH_VERSION=`git rev-parse --abbrev-ref HEAD | sed "s|release/||" | sed "s/${TAG_PREFIX}//"`
RELEASE_BRANCH_SHA=`git rev-parse HEAD`

parse_version "${RELEASE_BRANCH_VERSION}"
is_sha_tagged "${RELEASE_BRANCH_SHA}"
create_release "${TAG_PREFIX}${NEW_VERSION}"
