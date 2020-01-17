#!/bin/bash
set -e

. /common.sh

export INPUT_TF_DOCS_GIT_COMMIT_MESSAGE="skip: automated release process"
cd $GITHUB_WORKSPACE
git_setup

export TAG_PREFIX="v"
export MAJOR_VERSION=0
export MINOR_VERSION=0
export PATCH_VERSION=1
export NEW_VERSION="${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION}"
export IS_TAGGED=1

parse_version () {
  VERSION="${1}"
  MAJOR_VERSION=`echo $VERSION | cut -d. -f1`
  MINOR_VERSION=`echo $VERSION | cut -d. -f2`
  PATCH_VERSION=`echo $VERSION | cut -d. -f3`

  if [ -z "$MAJOR_VERSION" ] || [ -z "$MINOR_VERSION" ] || [ -z "$PATCH_VERSION" ]; then
    echo "::error failed to parse version=${VERSION}"
    exit 1
  fi
  NEW_VERSION=${VERSION}
}

is_sha_tagged () {
  SHA="${1}"
  set +e
  git describe --contains "${SHA}" 2>/dev/null
  IS_TAGGED=$?
  set -e
}

update_readme () {
  # generate README.md with version
  VERSION="${1:-master}" gomplate -d action=action.yml -f .github/templates/README.tpl -o README.md
  git_add_doc "./README.md"
}

overwrite_docker_tag () {
  NEW_TAG="${1:-"latest"}"
  # update the dockerfile to be locked down at this specific version
  sed -i "s|FROM derekrada/terraform-docs:.*|FROM derekrada/terraform-docs:${NEW_TAG}|" ./Dockerfile
  git_add_doc "./Dockerfile"
}

create_release () {

  # update the readme unaffected by major_version changes
  update_readme "${TAG_PREFIX}${NEW_VERSION}"

  # replace the module Dockerfile only done for v1.x.x
  overwrite_docker_tag "${TAG_PREFIX}${NEW_VERSION}"

  # commit and push
  git_commit
  git push
  echo "::debug pushed changes"
}

master_release () {
  update_readme "master"

  overwrite_docker_tag "stable"

  # commit and push
  git_commit
  git push
  echo "::debug pushed changes"
}

RELEASE_BRANCH_VERSION=`git rev-parse --abbrev-ref HEAD | sed "s|release/||" | sed "s/${TAG_PREFIX}//"`
RELEASE_BRANCH_SHA=`git rev-parse HEAD`
is_sha_tagged "${RELEASE_BRANCH_SHA}"

if [ "${IS_TAGGED}" -eq 0 ]; then
  echo "::debug Release is already tagged"
  exit
fi

if [ "${RELEASE_BRANCH_VERSION}" = "master" ]; then
  master_release
else
  parse_version "${RELEASE_BRANCH_VERSION}"
  create_release "${TAG_PREFIX}${NEW_VERSION}"
fi
