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

if [ "${INPUT_CONFIG_FILE}" = "disabled" ]; then
    case "$INPUT_OUTPUT_FORMAT" in
    "asciidoc" | "asciidoc table" | "asciidoc document")
        INPUT_ARGS="--indent ${INPUT_INDENTION} ${INPUT_ARGS}"
        ;;

    "markdown" | "markdown table" | "markdown document")
        INPUT_ARGS="--indent ${INPUT_INDENTION} ${INPUT_ARGS}"
        ;;
    esac

    if [ -z "${INPUT_TEMPLATE}" ]; then
        INPUT_TEMPLATE=$(printf '# Usage\n\n<!--- BEGIN_TF_DOCS --->\n<!--- END_TF_DOCS --->\n')
    fi
fi

git_setup() {
    if [ -n "${INPUT_GIT_PUSH_USER_NAME}" ]; then
        git config --global user.name "${INPUT_GIT_PUSH_USER_NAME}"
    else
        git config --global user.name github-actions[bot]
    fi

    if [ -n "${INPUT_GIT_PUSH_USER_EMAIL}" ]; then
        git config --global user.email "${INPUT_GIT_PUSH_USER_EMAIL}"
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
        if [ "${INPUT_GIT_PUSH_SIGN_OFF}" = "true" ]; then
            signoff="-s"
        fi
        git commit ${signoff} -m "${INPUT_GIT_COMMIT_MESSAGE}"
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
    if [ -n "${INPUT_CONFIG_FILE}" ] && [ "${INPUT_CONFIG_FILE}" != "disabled" ]; then
        echo "::debug file=entrypoint.sh,line=80 command=terraform-docs --config ${INPUT_CONFIG_FILE} ${INPUT_ARGS} ${working_dir}"
        local config_file
        if [ -f "${INPUT_CONFIG_FILE}" ]; then
            config_file="${INPUT_CONFIG_FILE}"
        else
            config_file="${working_dir}/${INPUT_CONFIG_FILE}"
        fi
        terraform-docs --config ${config_file} ${INPUT_ARGS} ${working_dir} >/tmp/tf_generated
        success=$?
    else
        echo "::debug file=entrypoint.sh,line=84 command=terraform-docs ${INPUT_OUTPUT_FORMAT} ${INPUT_ARGS} ${working_dir}"
        terraform-docs ${INPUT_OUTPUT_FORMAT} ${INPUT_ARGS} ${working_dir} >/tmp/tf_generated
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

    case "${INPUT_OUTPUT_METHOD}" in
    print)
        echo "${generated}"
        ;;

    replace | inject)
        # Create file if it doesn't exist
        if [ "${INPUT_OUTPUT_METHOD}" = "replace" ]; then
            echo "${INPUT_TEMPLATE}" >"${working_dir}/${INPUT_OUTPUT_FILE}"
        else
            if [ ! -f "${working_dir}/${INPUT_OUTPUT_FILE}" ]; then
                echo "${INPUT_TEMPLATE}" >"${working_dir}/${INPUT_OUTPUT_FILE}"
            fi
        fi

        local has_delimiter
        has_delimiter=$(grep -c -E '(BEGIN|END)_TF_DOCS' "${working_dir}/${INPUT_OUTPUT_FILE}")
        echo "::debug file=entrypoint.sh,line=115 has_delimiter=${has_delimiter}"

        # Verify it has BEGIN and END markers
        if [ "${has_delimiter}" -ne 2 ]; then
            echo "::error file=entrypoint.sh,line=119::Output file ${working_dir}/${INPUT_OUTPUT_FILE} does not contain BEGIN_TF_DOCS and END_TF_DOCS"
            exit 1
        fi

        # Output generated markdown to temporary file with a trailing newline and then replace the block
        echo "${generated}" >/tmp/tf_doc.md
        echo "" >>/tmp/tf_doc.md
        sed -i -ne '/<!--- BEGIN_TF_DOCS --->/ {p; r /tmp/tf_doc.md' -e ':a; n; /<!--- END_TF_DOCS --->/ {p; b}; ba}; p' "${working_dir}/${INPUT_OUTPUT_FILE}"
        git_add "${working_dir}/${INPUT_OUTPUT_FILE}"
        rm -f /tmp/tf_doc.md
        ;;
    esac
}

# go to github repo
cd "${GITHUB_WORKSPACE}"

git_setup

if [ -f "${GITHUB_WORKSPACE}/${INPUT_ATLANTIS_FILE}" ]; then
    # Parse an atlantis yaml file
    while read -r line; do
        project_dir=${line//- /}
        update_doc "${project_dir}"
    done < <(yq e '.projects[].dir' "${GITHUB_WORKSPACE}/${INPUT_ATLANTIS_FILE}")
elif [ -n "${INPUT_FIND_DIR}" ] && [ "${INPUT_FIND_DIR}" != "disabled" ]; then
    # Find all tf
    while read -r project_dir; do
        update_doc "${project_dir}"
    done < <(find "${INPUT_FIND_DIR}" -name '*.tf' -exec dirname {} \; | uniq)
else
    # Split INPUT_WORKING_DIR by commas
    for project_dir in ${INPUT_WORKING_DIR//,/ }; do
        update_doc "${project_dir}"
    done
fi

if [ "${INPUT_GIT_PUSH}" = "true" ]; then
    git_commit
    git push
else
    set +e
    num_changed=$(git_status)
    set -e
    if [ "${INPUT_FAIL_ON_DIFF}" = "true" ] && [ "${num_changed}" -ne 0 ]; then
        echo "::error file=entrypoint.sh,line=169::Uncommitted change(s) has been found!"
        exit 1
    fi
    echo "::set-output name=num_changed::${num_changed}"
fi

exit 0
