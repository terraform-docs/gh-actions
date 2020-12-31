#!/usr/bin/env bash

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

git_setup() {
  git config --global user.name "${GITHUB_ACTOR}"
  git config --global user.email "${GITHUB_ACTOR}"@users.noreply.github.com
  git fetch --depth=1 origin +refs/tags/*:refs/tags/* || true
}

git_add() {
  local files
  files="$1"
  git add "${files}"
  echo "::debug file=entrypoint.sh,line=34,col=1 Added ${files} to git staging area"
}

git_status() {
  git status --porcelain | grep -c -E '([MA]\W).+'
}

git_commit() {
  local is_clean
  is_clean=$(git_status)
  if [ "${is_clean}" -eq 0 ]; then
    echo "::debug file=entrypoint.sh,line=45,col=1 No files changed, skipping commit"
  else
    git commit -m "${GIT_COMMIT_MESSAGE}"
  fi
}

update_doc() {
  local working_dir
  local generated

  working_dir="$1"
  echo "::debug file=entrypoint.sh,line=56,col=1 working_dir=${working_dir}"

  # shellcheck disable=SC2086
  generated=$(terraform-docs ${OUTPUT_FORMAT} ${ARGS} ${working_dir})

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
    echo "::debug file=entrypoint.sh,line=78,col=1 has_delimiter=${has_delimiter}"

    # Verify it has BEGIN and END markers
    if [ "${has_delimiter}" -ne 2 ]; then
      echo "::error file=entrypoint.sh,line=82,col=1::Output file ${working_dir}/${OUTPUT_FILE} does not contain BEGIN_TF_DOCS and END_TF_DOCS"
      exit 1
    fi

    # Output generated markdown to temporary file with a trailing newline and then replace the block
    echo "${generated}" >/tmp/tf_doc.md
    echo "" >>/tmp/tf_doc.md
    sed -i -ne '/<!--- BEGIN_TF_DOCS --->/ {p; r /tmp/tf_doc.md' -e ':a; n; /<!--- END_TF_DOCS --->/ {p; b}; ba}; p' "${working_dir}/${OUTPUT_FILE}"
    git_add "${working_dir}/${OUTPUT_FILE}"
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
  done < <(yq r "${GITHUB_WORKSPACE}/${ATLANTIS_FILE}" 'projects[*].dir') # NOTE(khos2ow): this is v3 specific syntax
elif [ -n "${FIND_DIR}" ] && [ "${FIND_DIR}" != "disabled" ]; then
  # Find all tf
  while read -r project_dir; do
    update_doc "${project_dir}"
  done < <(find "${FIND_DIR}" -name '*.tf' -exec dirname {} \; | uniq)
else
  # Split WORKING_DIR by commas
  for project_dir in ${WORKING_DIR//,/}; do
    update_doc "${project_dir}"
  done
fi

if [ "${GIT_PUSH}" = "true" ]; then
  git_commit
  git push
else
  echo "::set-output name=num-changed::$(git_status)"
fi

exit 0
