#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename "${__file}" .sh)"
#__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app

# defaults
CONFIGS_DIR="/opt/datashipper/configs"
OUTPUT_DIR="/opt/datashipper/output"

# Help command output
usage(){
echo "
${__base}.sh [OPTION...] TOPIC
-h; Print this help and exit
-c <configs_dir>; Configs directory (default: ${CONFIGS_DIR})
-o <configs_dir>; Output directory (default: ${OUTPUT_DIR})
TOPIC; The name of the topic to be added
" | column -t -s ";"
}

while getopts ":hc:o:" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    c )
      CONFIGS_DIR=${OPTARG}
      ;;
    o )
      OUTPUT_DIR=${OPTARG}
      ;;
    \? )
      usage
      exit 2
      ;;
  esac
done
shift $((OPTIND-1))
if [ -z "${1:-}" ]; then
  echo "Missing topic name (required)"
  usage
  exit 2
else
  TOPIC="${1:-}"
fi

generate_yaml()
{
  cat <<EOF
- type: log
  tail_files: true
  fields:
    topic_id: ${TOPIC}
  paths:
    - ${OUTPUT_DIR}/${TOPIC}.csv
EOF
}
generate_yaml > "${CONFIGS_DIR}/${TOPIC}.yml"
