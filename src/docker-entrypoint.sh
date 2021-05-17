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

set -e

# Ensure all variables are present
WORKING_DIR="${1}"
ATLANTIS_FILE="${2}"
FIND_DIR="${3}"
OUTPUT_FORMAT="${4}"
OUTPUT_METHOD="${5}"
OUTPUT_FILE="${6}"
TEMPLATE="${7}"
ARGS="${8}"
INDENTION="${9}"
GIT_PUSH="${10}"
GIT_COMMIT_MESSAGE="${11}"
CONFIG_FILE="${12}"
FAIL_ON_DIFF="${13}"
GIT_PUSH_SIGN_OFF="${14}"
GIT_PUSH_USER_NAME="${15}"
GIT_PUSH_USER_EMAIL="${16}"

if [ "${CONFIG_FILE}" == "disabled" ]; then
  case "$OUTPUT_FORMAT" in
  "asciidoc" | "asciidoc table" | "asciidoc document")
    ARGS="--indent ${INDENTION} ${ARGS}"
    ;;

  "markdown" | "markdown table" | "markdown document")
    ARGS="--indent ${INDENTION} ${ARGS}"
    ;;
  esac

  if [ -z "${TEMPLATE}" ]; then
    TEMPLATE=$(printf '# Usage\n\n<!--- BEGIN_TF_DOCS --->\n<!--- END_TF_DOCS --->\n')
  fi
fi

git_setup() {
  if [ -n "${GIT_PUSH_USER_NAME}" ]; then
    git config --global user.name "${GIT_PUSH_USER_NAME}"
  else
    git config --global user.name "${GITHUB_ACTOR}"
  fi

  if [ -n "${GIT_PUSH_USER_EMAIL}" ]; then
    git config --global user.email "${GIT_PUSH_USER_EMAIL}"
  else
    git config --global user.email "${GITHUB_ACTOR}"@users.noreply.github.com
  fi

  git fetch --depth=1 origin +refs/tags/*:refs/tags/* || true
}

git_add() {
  local file
  file="$1"
  git add "${file}"
  if [ "$(git status --porcelain | grep "$file" | grep -c -E '([MA]\W).+')" -eq 1 ]; then
    echo "::debug file=entrypoint.sh,line=46 Added ${file} to git staging area"
  else
    echo "::debug file=entrypoint.sh,line=48 No change in ${file} detected"
  fi
}

git_status() {
  git status --porcelain | grep -c -E '([MA]\W).+'
}

git_commit() {
  local is_clean
  set +e
  is_clean=$(git_status)
  set -e
  if [ "${is_clean}" -eq 0 ]; then
    echo "::debug file=entrypoint.sh,line=54 No files changed, skipping commit"
    exit 0
  else
    local signoff
    signoff=""
    if [ "${GIT_PUSH_SIGN_OFF}" = "true" ]; then
      signoff="-s"
    fi
    git commit ${signoff} -m "${GIT_COMMIT_MESSAGE}"
  fi
}

update_doc() {
  local working_dir
  local generated
  local success

  working_dir="$1"
  echo "::debug file=entrypoint.sh,line=66 working_dir=${working_dir}"

  set +e

  # shellcheck disable=SC2086
  if [ -n "${CONFIG_FILE}" ] && [ "${CONFIG_FILE}" != "disabled" ]; then
    echo "::debug file=entrypoint.sh,line=80 command=terraform-docs --config ${CONFIG_FILE} ${ARGS} ${working_dir}"
    terraform-docs --config ${CONFIG_FILE} ${ARGS} ${working_dir} >/tmp/tf_generated
    success=$?
  else
    echo "::debug file=entrypoint.sh,line=84 command=terraform-docs ${OUTPUT_FORMAT} ${ARGS} ${working_dir}"
    terraform-docs ${OUTPUT_FORMAT} ${ARGS} ${working_dir} >/tmp/tf_generated
    success=$?
  fi

  set -e

  if [ $success -ne 0 ]; then
    echo "::error file=entrypoint.sh,line=89::$(cat /tmp/tf_generated)"
    rm -f /tmp/tf_generated
    exit $success
  fi

  generated=$(cat /tmp/tf_generated)
  rm -f /tmp/tf_generated

  case "${OUTPUT_METHOD}" in
  print)
    echo "${generated}"
    ;;

  replace)
    echo "${generated}" >"${working_dir}/${OUTPUT_FILE}"
    git_add "${working_dir}/${OUTPUT_FILE}"
    ;;

  inject)
    # Create file if it doesn't exist
    if [ ! -f "${working_dir}/${OUTPUT_FILE}" ]; then
      echo "${TEMPLATE}" >"${working_dir}/${OUTPUT_FILE}"
    fi

    local has_delimiter
    has_delimiter=$(grep -c -E '(BEGIN|END)_TF_DOCS' "${working_dir}/${OUTPUT_FILE}")
    echo "::debug file=entrypoint.sh,line=115 has_delimiter=${has_delimiter}"

    # Verify it has BEGIN and END markers
    if [ "${has_delimiter}" -ne 2 ]; then
      echo "::error file=entrypoint.sh,line=119::Output file ${working_dir}/${OUTPUT_FILE} does not contain BEGIN_TF_DOCS and END_TF_DOCS"
      exit 1
    fi

    # Output generated markdown to temporary file with a trailing newline and then replace the block
    echo "${generated}" >/tmp/tf_doc.md
    echo "" >>/tmp/tf_doc.md
    sed -i -ne '/<!--- BEGIN_TF_DOCS --->/ {p; r /tmp/tf_doc.md' -e ':a; n; /<!--- END_TF_DOCS --->/ {p; b}; ba}; p' "${working_dir}/${OUTPUT_FILE}"
    git_add "${working_dir}/${OUTPUT_FILE}"
    rm -f /tmp/tf_doc.md
    ;;
  esac
}

# go to github repo
cd "${GITHUB_WORKSPACE}"

git_setup

if [ -f "${GITHUB_WORKSPACE}/${ATLANTIS_FILE}" ]; then
  # Parse an atlantis yaml file
  while read -r line; do
    project_dir=${line//- /}
    update_doc "${project_dir}"
  done < <(yq e '.projects[].dir' "${GITHUB_WORKSPACE}/${ATLANTIS_FILE}")
elif [ -n "${FIND_DIR}" ] && [ "${FIND_DIR}" != "disabled" ]; then
  # Find all tf
  while read -r project_dir; do
    update_doc "${project_dir}"
  done < <(find "${FIND_DIR}" -name '*.tf' -exec dirname {} \; | uniq)
else
  # Split WORKING_DIR by commas
  for project_dir in ${WORKING_DIR//,/ }; do
    update_doc "${project_dir}"
  done
fi

if [ "${GIT_PUSH}" = "true" ]; then
  git_commit
  git push
else
  set +e
  num_changed=$(git_status)
  set -e
  if [ "${FAIL_ON_DIFF}" == "true" ] && [ "${num_changed}" -ne 0 ]; then
    echo "::error file=entrypoint.sh,line=169::Uncommitted change(s) has been found!"
    exit 1
  fi
  echo "::set-output name=num_changed::${num_changed}"
fi

exit 0
