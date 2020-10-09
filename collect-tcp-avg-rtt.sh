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
UNIT=s
MULTIPLIER=1
INTERFACE=$(ip route | awk '$1 == "default" {print $5; exit}')
DUR=1
VERBOSE=0
OUT="tcp-avg-rtt.csv"

# Help command output
usage(){
echo "
${__base}.sh [OPTION...]
-h; Print this help and exit
-d; Set device id (default: ${DEVICE_ID})
-m; Set rtt measurement in milliseconds instead of seconds (default: ${UNIT})
-i <name>; Set interface name (default: ${INTERFACE})
-a <address-array>; Set host addresses to capture, ex. 10.1.1.3,10.1.1.4 (default: all)
-p <port>; Set port to capture, only TCP (default: all)
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

while getopts ":hd:mi:a:p:t:o:v" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    d )
      DEVICE_ID=${OPTARG}
      ;;
    m )
      UNIT=ms
      MULTIPLIER=1000
      ;;
    i )
      INTERFACE=${OPTARG}
      ;;
    a )
      IFS=',' read -ra ADDRESS <<< "${OPTARG}"
      ;;
    p )
      PORT=${OPTARG}
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
log "unit: $UNIT"
log "multiplier: $MULTIPLIER"
log "interface: $INTERFACE"
[ -v ADDRESS ] && log "address(es): ${ADDRESS[*]}"
[ -v PORT ] && log "port: $PORT"
log "duration: $DUR second(s)"
log "output file: $OUT"
log "verbose: $VERBOSE"

# Prepare arguments for Tshark
ARGS=(--interface "${INTERFACE}" --autostop "duration:${DUR}" -q -z "io,stat,0,AVG(tcp.analysis.ack_rtt)tcp.analysis.ack_rtt")
if [ -v ADDRESS ]; then
  ARGS+=(host "${ADDRESS}")
  for a in "${ADDRESS[@]:1}"
  do
    ARGS+=(or host "${a}")
  done
fi
if [ -v PORT ]; then
  if [ -v ADDRESS ]; then
    ARGS+=(and tcp port "${PORT}")
  else
    ARGS+=(tcp port "${PORT}")
  fi
fi
log "tshark args: ${ARGS[*]}"

log "csv headers: metric_value;timestamp;unit;device_id;context"
while true
do
  value=$(tshark "${ARGS[@]}" 2>/dev/null | awk '/\|\s+AVG\s+\|/ {getline;getline;print $6}')
  timestamp=$(echo "scale=2; $(date +%s%N)/1000000" | bc)
  timestamp="${timestamp//./,}"
  log "value measured in $DUR second(s): $value"
  if [ "${value}" ] && [ "${value}" != 0.000000 ]; then
    rtt=$(echo "$value*$MULTIPLIER" | bc | awk '{printf "%.3f", $0}')
    log "rtt: $rtt $UNIT"
    csvline="${rtt};${timestamp};${UNIT};$DEVICE_ID;"
    log "csvline: $csvline"
    echo "$csvline" >> "${OUT}"
  else
    log "no value, skip write"
  fi
done
