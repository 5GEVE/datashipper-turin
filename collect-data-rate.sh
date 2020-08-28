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

# Help command output
usage(){
echo "
${__base}.sh [OPTION...]
-h; Print this help and exit
-d; Set device id (default: hostname -f)
-b; Set rate measurement in bits per second (default: Bytes)
-i <name>; Set interface name (default: gateway interface from 'ip route')
-a <address>; Set host address to capture. Use multiple -a to capture multiple addresses. (default: all)
-p <port>; Set port to capture (default: all)
-u; Set UDP capture for port selected with '-p' (default: tcp)
-t <seconds>; Set sampling time in seconds (default: 1)
-o <filename>; Set output file name (default: data-rate.csv)
-v; Set verbose output
" | column -t -s ";"
}

function log() {
  if [ "${VERBOSE}" = 1 ]; then
    echo -e "$(date --iso-8601='seconds') - $*"
  fi
}

# defaults
DEVICE_ID=$(hostname -f)
UNIT=Bps
MULTIPLIER=1
INTERFACE=$(ip route | awk '$1 == "default" {print $5; exit}')
PROTO=tcp
DUR=1
VERBOSE=0
OUT="data-rate.csv"
while getopts ":hd:bi:a:p:ut:o:v" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    d )
      DEVICE_ID=${OPTARG}
      ;;
    b )
      UNIT=bps
      MULTIPLIER=8
      ;;
    i )
      INTERFACE=${OPTARG}
      ;;
    a )
      ADDRESS+=("${OPTARG}")
      ;;
    p )
      PORT=${OPTARG}
      ;;
    u )
      PROTO=udp
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
log "protocol: $PROTO"
log "duration: $DUR second(s)"
log "output file: $OUT"
log "verbose: $VERBOSE"

# Prepare arguments for Tshark
ARGS=(--interface "${INTERFACE}" --autostop "duration:${DUR}" -q -z "io,stat,0,BYTES")
if [ -v ADDRESS ]; then
  ARGS+=(host "${ADDRESS}")
  for a in "${ADDRESS[@]:1}"
  do
    ARGS+=(or host "${a}")
  done
fi
if [ -v PORT ]; then
  if [ -v ADDRESS ]; then
    ARGS+=(and "${PROTO}" port "${PORT}")
  else
    ARGS+=("${PROTO}" port "${PORT}")
  fi
fi
log "tshark args: ${ARGS[*]}"

# Initialize output file. Use , as separator.
echo "metric_value,timestamp,unit,device_id,context" > "${OUT}"
while true
do
  bytes=$(tshark "${ARGS[@]}" 2>/dev/null | awk '/\|\s+BYTES\s+\|/ {getline;getline;print $6}')
  timestamp=$(echo "scale=2; $(date +%s%N)/1000000" | bc)

  log "bytes measured in $DUR seconds: $bytes"
  [ -z "${bytes}" ] && rate=0 || rate=$(echo "scale=2; $bytes*$MULTIPLIER/$DUR" | bc)
  log "rate: $rate $UNIT"
  csvline="${rate},${timestamp},${UNIT},$DEVICE_ID,"
  log "csvline: $csvline"
  echo "$csvline" >> "${OUT}"
done
