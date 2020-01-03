#!/bin/bash
set -e

TF_ARGS="--indent ${INPUT_TF_DOCS_INDENTION} ${INPUT_TF_DOCS_ARGS}"

export TF_DOCS_TEMPLATE=`printf '# Usage\n\n<!--- BEGIN_TF_DOCS --->\n<!--- END_TF_DOCS --->\n'`
if [ ! -z "$INPUT_TF_DOCS_TEMPLATE" ]; then
  TF_DOCS_TEMPLATE=$INPUT_TF_DOCS_TEMPLATE
fi

. /common.sh

# go to github repo
cd $GITHUB_WORKSPACE

if [ -f "${GITHUB_WORKSPACE}/${INPUT_TF_DOCS_ATLANTIS_FILE}" ]; then

  # Parse an atlantis yaml file
  yq r "${GITHUB_WORKSPACE}/${INPUT_TF_DOCS_ATLANTIS_FILE}" 'projects[*].dir' > /tmp/atlantis_dirs.txt
  while read line
  do
    project_dir=`echo $line | sed 's/- //'`
    update_doc "${project_dir}"
  done < /tmp/atlantis_dirs.txt

elif [ "${INPUT_TF_DOCS_FIND_DIR}" != "disabled" ]; then
  # Find all tf
  find "${INPUT_TF_DOCS_FIND_DIR}" -name '*.tf' -exec dirname {} \; | uniq > /tmp/find_dirs.txt
  while read project_dir
  do
    update_doc "${project_dir}"
  done < /tmp/find_dirs.txt

else
  # Split WORKING_DIR by commas
  for project_dir in $(echo "${INPUT_TF_DOCS_WORKING_DIR}" | sed "s/,/ /g")
  do
    update_doc "${project_dir}"
  done
fi

if [ "${INPUT_TF_DOCS_GIT_PUSH}" = "true" ]; then
  git_commit
else
  git_changed
fi

exit 0
