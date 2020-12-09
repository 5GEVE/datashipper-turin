#!/usr/bin/env bash

# service reliability is defined as
# packets(rtt < latency_constraint)/total_packets * 100

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
INTERFACE=$(ip route | awk '$1 == "default" {print $5; exit}')
DUR=10
CONSTRAINT=30
VERBOSE=0
OUT="service-reliability.csv"

# Help command output
usage(){
echo "
${__base}.sh [OPTION...]
-h; Print this help and exit
-d; Set device id (default: ${DEVICE_ID})
-i <name>; Set interface name (default: ${INTERFACE})
-a <address-array>; Set host addresses to capture, ex. 10.1.1.3,10.1.1.4 (default: all)
-p <port>; Set port to capture, only TCP (default: all)
-t <seconds>; Set sampling time in seconds (default: ${DUR})
-c <milliseconds>; Latency constraint in milliseconds (default: ${CONSTRAINT})
-o <filename>; Set output file name (default: ${OUT})
-v; Set verbose output
" | column -t -s ";"
}

function log() {
  if [ "${VERBOSE}" = 1 ]; then
    echo -e "$(date --iso-8601='seconds') - $*"
  fi
}

while getopts ":hd:i:a:p:t:c:o:v" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    d )
      DEVICE_ID=${OPTARG}
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
    c )
      CONSTRAINT=$(echo "scale=3; ${OPTARG}/1000" | bc)
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

log "device id: ${DEVICE_ID}"
log "interface: ${INTERFACE}"
[ -v ADDRESS ] && log "address(es): ${ADDRESS[*]}"
[ -v PORT ] && log "port: ${PORT}"
log "duration: ${DUR} second(s)"
log "output file: ${OUT}"
log "verbose: ${VERBOSE}"

# Prepare arguments for Tshark
ARGS=(--interface "${INTERFACE}" --autostop "duration:${DUR}" -q \
  -z "io,stat,0,COUNT(tcp.analysis.ack_rtt)tcp.analysis.ack_rtt < ${CONSTRAINT},COUNT(tcp.analysis.ack_rtt)tcp.analysis.ack_rtt")
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

log "csv headers: metric_value,timestamp,unit,device_id,context"
in_time=0
total=0
while true
do
  IFS=" " read -r -a arr <<< "$(tshark "${ARGS[@]}" 2>/dev/null | awk '/\|\s+COUNT\s+\|/ {getline;getline;print $6" "$8}')"
  timestamp=$(date +%s)
  in_time=$((in_time+arr[0]))
  log "in_time: ${in_time}"
  total=$((total+arr[1]))
  log "total: ${total}"
  value=$(echo "scale=6; ${in_time}/${total} * 100" | bc)
  log "value measured in ${DUR} second(s): ${value}"
  csvline="${value},${timestamp},%,${DEVICE_ID},"
  log "csvline: ${csvline}"
  echo "${csvline}" >> "${OUT}"
done
