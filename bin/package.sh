# get package root
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Working directory is: ${WORKDIR}"

WORKDIR_BN="$(basename "${WORKDIR}")"
OUTPUT_DIR="${WORKDIR}/out"

if [[ ! -d "${OUTPUT_DIR}" ]]
then
  mkdir -p "${OUTPUT_DIR}"
fi

OUTPUT_FILENAME="${OUTPUT_DIR}/${WORKDIR_BN}_$(date +"%Y%m%d_%H%M%S").zip"
echo "Target filename is: ${OUTPUT_FILENAME}"

# Create empty zip file (use the empty file tactic)
MKTEMP="$(mktemp)"
zip -9q "${OUTPUT_FILENAME}" "${MKTEMP}"
zip -dq "${OUTPUT_FILENAME}" "${MKTEMP}"

# Add python files in workdir root to
echo "Adding main files to zip file."
pushd "${WORKDIR}" >/dev/null
find . -name "*.py" -type f -exec zip -9u "${OUTPUT_FILENAME}" '{}' \;
popd >/dev/null


# Add requirements packages to installer
REQUIREMENTS="${WORKDIR}/requirements.txt"

if [[ -f "${REQUIREMENTS}" ]]
then
  echo "Requirements found in ${REQUIREMENTS}"
  echo "Creating virtualenv for temporary requirements generation."
  # make virtualenv (capture directory)
  VENVDIR="$(mktemp -d)"
  virtualenv "${VENVDIR}"

  # activate virtualenv
  source "${VENVDIR}/bin/activate"

  # install requirements
  echo "Installing requirements"
  pip install -r "${REQUIREMENTS}"

  # deactivate virtualenv
  deactivate

  # zip directory into output zip
  for subfolder in "${VENVDIR}/lib/python2.7/site-packages" "${VENVDIR}/lib64/python2.7/site-packages"
  do
    if [[ -d "${subfolder}" ]]
    then
      echo "Adding library packages from ${subfolder} to ${OUTPUT_FILENAME}"
      pushd "${subfolder}" >/dev/null
      zip -9ruq "${OUTPUT_FILENAME}" *
      popd >/dev/null

      # remove pip, setuptools, wheel, and easy_install as needed
      #zip -9d
      zip -qd "${OUTPUT_FILENAME}" 'easy_install.py*' \
                                   'pkg_resources/*' \
                                   'pip/*' \
                                   'pip-*.dist-info/*' \
                                   'setuptools/*' \
                                   'setuptools-*.dist-info/*' \
                                   'wheel/*' \
                                   'wheel-*.dist-info/*'
    fi
  done

  echo "Removing temporary virtualenv directory in ${VENVDIR}"
  rm -rf "${VENVDIR}"
fi
