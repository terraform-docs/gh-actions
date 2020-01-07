#!/bin/bash
set -e

. /common.sh

export INPUT_TF_DOCS_GIT_COMMIT_MESSAGE="chore: automated release process"
cd $GITHUB_WORKSPACE
git_setup

VERSION=`gomplate -d meta=.github/meta.yml -i 'v{{ (ds "meta").major_version }}'`
git tag -f "${VERSION}"
git push -f --tags
