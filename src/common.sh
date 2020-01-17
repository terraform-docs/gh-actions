#!/bin/bash
set -e

git_add_doc () {

  MY_FILE="${1}"
  git add "${MY_FILE}"
}

git_changed () {
  GIT_FILES_CHANGED=`git status --porcelain | grep -E '([MA]\W).+' | wc -l`
  echo "::set-output name=num_changed::${GIT_FILES_CHANGED}"
}

git_setup () {
  git config --global user.name ${GITHUB_ACTOR}
  git config --global user.email ${GITHUB_ACTOR}@users.noreply.github.com
  git fetch --depth=1 origin +refs/tags/*:refs/tags/*
}

git_commit () {
  git_changed
  if [ "${GIT_FILES_CHANGED}" -eq 0 ]; then
    echo "::debug file=common.sh,line=20,col=1 No files changed, skipping commit"
  else
    git commit -m "${INPUT_TF_DOCS_GIT_COMMIT_MESSAGE}"
  fi
}

update_doc () {

  WORKING_DIR="${1}"
  echo "::debug file=common.sh,line=30,col=1 WORKING_DIR=${WORKING_DIR}"

  if [ "${INPUT_TF_DOCS_CONTENT_TYPE}" = "json" ]; then
    MY_DOC=`terraform-docs "${INPUT_TF_DOCS_CONTENT_TYPE}" "${WORKING_DIR}" $INPUT_TF_DOCS_ARGS`

    if [ -f "${INPUT_TF_DOCS_TEMPLATE_FILE}" ]; then
      echo "${MY_DOC}" > "/tmp/config.json"
      MY_DOC=`gomplate -d "config=/tmp/config.json" -f "${INPUT_TF_DOCS_TEMPLATE_FILE}"`
    fi
  else
    MY_DOC=`terraform-docs markdown "${INPUT_TF_DOCS_CONTENT_TYPE}" "${WORKING_DIR}" $TF_ARGS`
  fi

  if [ "${INPUT_TF_DOCS_OUTPUT_METHOD}" = "replace" ]; then
    echo "${MY_DOC}" > "${WORKING_DIR}/${INPUT_TF_DOCS_OUTPUT_FILE}"
    git_add_doc "${WORKING_DIR}/${INPUT_TF_DOCS_OUTPUT_FILE}"


  elif [ "${INPUT_TF_DOCS_OUTPUT_METHOD}" = "inject" ]; then

    # Create file if it doesn't exist
    if [ ! -f "${WORKING_DIR}/${INPUT_TF_DOCS_OUTPUT_FILE}" ]; then
       printf "${TF_DOCS_TEMPLATE}" > "${WORKING_DIR}/${INPUT_TF_DOCS_OUTPUT_FILE}"
    fi

    HAS_TF_DOCS=`grep -E '(BEGIN|END)_TF_DOCS' ${WORKING_DIR}/${INPUT_TF_DOCS_OUTPUT_FILE} | wc -l`
    echo "::debug file=common.sh,line=47,col=1 HAS_TF_DOCS=${HAS_TF_DOCS}"
    # Verify it has BEGIN and END markers
    if [ "${HAS_TF_DOCS}" -ne 2 ]; then
      echo "::error file=common.sh,line=50,col=1::Output file ${WORKING_DIR}/${INPUT_TF_DOCS_OUTPUT_FILE} does not contain BEGIN_TF_DOCS and END_TF_DOCS"
      exit 2
    fi

    # Output generated markdown to temporary file and then replace the block
    echo "${MY_DOC}" > /tmp/tf_doc.md
    sed -i -ne '/<!--- BEGIN_TF_DOCS --->/ {p; r /tmp/tf_doc.md' -e ':a; n; /<!--- END_TF_DOCS --->/ {p; b}; ba}; p' "${WORKING_DIR}/${INPUT_TF_DOCS_OUTPUT_FILE}"
    git_add_doc "${WORKING_DIR}/${INPUT_TF_DOCS_OUTPUT_FILE}"
  else
    echo "${MY_DOC}"
  fi
}
