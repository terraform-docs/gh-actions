#!/bin/bash
set -e

. /common.sh

cd $GITHUB_WORKSPACE

gomplate -d action=action.yml -f .github/templates/README.tpl -o README.md
git_add_doc "./README.md"

if [ "${INPUT_TF_DOCS_GIT_PUSH}" = "true" ]; then
  git_commit
fi
