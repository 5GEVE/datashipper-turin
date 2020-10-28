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
REMOVE=0

# Help command output
usage(){
echo "
Adds an input configuration for Filebeat
The file to be monitored gets the name of the TOPIC (without any extension)
${__base}.sh [OPTION...] TOPIC
TOPIC; The name of the topic
-h; Print this help and exit
-c <configs_dir>; Configs directory (default: ${CONFIGS_DIR})
-o <output_dir>; Output directory (default: ${OUTPUT_DIR})
-r; Removes the configuration and kills any process associated to it
" | column -t -s ";"
}

while getopts ":hc:o:r" opt; do
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
    r )
      REMOVE=1
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
  fields:
    topic_id: ${TOPIC}
  paths:
    - ${OUTPUT_DIR}/${TOPIC}
EOF
}

if [ "${REMOVE}" = 0 ]; then
  generate_yaml > "${CONFIGS_DIR}/${TOPIC}.yml"
else
  pkill --full --oldest "${TOPIC}"
  [ -e "${CONFIGS_DIR}/${TOPIC}.yml" ] && rm "${CONFIGS_DIR}/${TOPIC}.yml"
fi
