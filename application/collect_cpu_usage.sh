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
DEVICE_ID=$(hostname -f)
DUR=1
VERBOSE=0
OUT="cpu.csv"

# Help command output
usage(){
echo "
Collects the overall CPU usage in percentage (%)
${__base}.sh [OPTION...]
-h; Print this help and exit
-d; Set device id (default: ${DEVICE_ID})
-t <seconds>; Set sampling time in seconds (default: ${DUR})
-o <filename>; Set output file name (default: ${OUT})
-v; Set verbose output
" | column -t -s ";"
}

function log() {
  if [ "${VERBOSE}" = 1 ]; then
    echo -e "$(date --iso-8601='seconds') - $*"
  fi
}

while getopts ":hd:t:o:v" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    d )
      DEVICE_ID=${OPTARG}
      ;;
    t )
      DUR=${OPTARG}
      ;;
    o )
      OUT=${OPTARG}
      ;;
    v )
      VERBOSE=1
      ;;
    \? )
      usage
      exit 2
      ;;
  esac
done
shift $((OPTIND-1))

log "device id: $DEVICE_ID"
log "duration: $DUR second(s)"
log "output file: $OUT"
log "verbose: $VERBOSE"

log "csv headers: metric_value,timestamp,unit,device_id,context"
while true
do
  csvline="$(mpstat "${DUR}" 1 | awk 'NR==4{ print 100 - $NF; }'),$(date +%s),%,${DEVICE_ID},"
  log "csvline: $csvline"
  echo "$csvline" >> "${OUT}"
done
