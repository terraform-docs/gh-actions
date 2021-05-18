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

if [ "${CONFIG_FILE}" = "disabled" ]; then
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
        git config --global user.name github-actions[bot]
    fi

    if [ -n "${GIT_PUSH_USER_EMAIL}" ]; then
        git config --global user.email "${GIT_PUSH_USER_EMAIL}"
    else
        git config --global user.email github-actions[bot]@users.noreply.github.com
    fi

    git fetch --depth=1 origin +refs/tags/*:refs/tags/* || true
}

git_add() {
    local file
    file="$1"
    git add "${file}"
    if [ "$(git status --porcelain | grep "$file" | grep -c -E '([MA]\W).+')" -eq 1 ]; then
        echo "::debug Added ${file} to git staging area"
    else
        echo "::debug No change in ${file} detected"
    fi
}

git_status() {
    git status --porcelain | grep -c -E '([MA]\W).+'
}

git_commit() {
    if [ "$(git_status)" -eq 0 ]; then
        echo "::debug No files changed, skipping commit"
        exit 0
    fi

    local signoff
    if [ "${GIT_PUSH_SIGN_OFF}" = "true" ]; then
        signoff="-s"
    fi
    git commit ${signoff} -m "${GIT_COMMIT_MESSAGE}"
}

update_doc() {
    local working_dir

    working_dir="$1"
    echo "::debug working_dir=${working_dir}"

    local config_file

    if [ -n "${CONFIG_FILE}" ] && [ "${CONFIG_FILE}" != "disabled" ]; then
        if [ -f "${CONFIG_FILE}" ]; then
            config_file="${CONFIG_FILE}"
        else
            config_file="${working_dir}/${CONFIG_FILE}"
        fi

        echo "::debug config_file=${config_file}"
        config_file="--config ${config_file}"
    fi

    local output_mode
    local output_file

    if [ "${OUTPUT_METHOD}" == "inject" ] || [ "${OUTPUT_METHOD}" == "replace" ]; then
        echo "::debug output_mode=${OUTPUT_METHOD}"
        output_mode="--output-mode ${OUTPUT_METHOD}"

        echo "::debug output_file=${OUTPUT_FILE}"
        output_file="--output-file ${OUTPUT_FILE}"
    fi

    local success

    echo "::debug terraform-docs ${config_file} ${OUTPUT_FORMAT} ${ARGS} ${output_mode} ${output_file} ${working_dir}"
    # shellcheck disable=SC2086
    terraform-docs \
        ${config_file} \
        ${OUTPUT_FORMAT} \
        ${ARGS} \
        ${output_mode} \
        ${output_file} \
        ${working_dir}
    success=$?

    if [ $success -ne 0 ]; then
        exit $success
    fi

    if [ "${OUTPUT_METHOD}" == "inject" ] || [ "${OUTPUT_METHOD}" == "replace" ]; then
        git_add "${working_dir}/${OUTPUT_FILE}"
    fi

}

# go to github repo
cd "${GITHUB_WORKSPACE}"

git_setup

if [ -f "${GITHUB_WORKSPACE}/${ATLANTIS_FILE}" ]; then
    # Parse an atlantis yaml file
    for line in $(yq e '.projects[].dir' "${GITHUB_WORKSPACE}/${ATLANTIS_FILE}"); do
        project_dir=${line//- /}
        update_doc "${project_dir}"
    done
elif [ -n "${FIND_DIR}" ] && [ "${FIND_DIR}" != "disabled" ]; then
    # Find all tf
    for project_dir in $(find "${FIND_DIR}" -name '*.tf' -exec dirname {} \; | uniq); do
        update_doc "${project_dir}"
    done
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
    num_changed=$(git_status)
    if [ "${FAIL_ON_DIFF}" = "true" ] && [ "${num_changed}" -ne 0 ]; then
        echo "::error ::Uncommitted change(s) has been found!"
        exit 1
    fi
    echo "::set-output name=num_changed::${num_changed}"
fi

exit 0
