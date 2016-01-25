#!/bin/bash

set -o errexit
REPO_DEB_URL='https://raw.githubusercontent.com/flavio-fernandes/pipework/master/pipework'
PIPEWORK=$(dirname "${BASH_SOURCE}")/pipework

set -x 
wget --output-document="${PIPEWORK}" "${REPO_DEB_URL}" 2>/dev/null
chmod +x ${PIPEWORK}
