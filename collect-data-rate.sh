#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename "${__file}" .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app

#if [ "$EUID" -ne 0 ]
#	then echo "Must be root"
#	exit 1
#fi

# Help command output
usage(){
echo "
${__base}.sh [OPTION...]
-h            Print this help and exit
-b            Set rate measurement in bits per second (default: bytes)
-i <name>     Set interface name (default: gateway interface from 'ip route')
-a <address>  Set host address to capture (default: all)
-p <port>     Set tcp port to capture (default: all)
-d <seconds>  Set capture duration in seconds (default: 1)
-o <filename> Set output file name (default: data-rate.csv)
-v            Set verbose output
" | column -t -s ";"
}

# defaults
UNIT=Bps
MULTIPLIER=1
INTERFACE=$(ip route | awk '$1 == "default" {print $5; exit}')
DUR=1
VERBOSE=0
OUT="data-rate.csv"
while getopts ":hbi:a:p:d:o:v" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    b )
      UNIT=bps
      MULTIPLIER=8
      ;;
    i )
      INTERFACE=${OPTARG}
      ;;
    a )
      ADDRESS=${OPTARG}
      ;;
    p )
      PORT=${OPTARG}
      ;;
    d )
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

function log() {
  if [ "${VERBOSE}" = 1 ]; then
    datestring=$(date --iso-8601='seconds')
    echo -e "$datestring - $*"
  fi
}

log "multiplier $MULTIPLIER"
log "interface $INTERFACE"
log "duration $DUR second(s)"
log "output file $OUT"
log "verbose $VERBOSE"

# Prepare arguments for Tshark
ARGS=(--interface "${INTERFACE}" --autostop "duration:${DUR}" -q -z "io,stat,0,BYTES")
if [ -v ADDRESS ] && [ -v PORT  ]; then
  ARGS+=(-f "host ${ADDRESS} and tcp port ${PORT}")
elif [ -v ADDRESS ]; then
  ARGS+=(-f "host ${ADDRESS}")
elif [ -v PORT ]; then
  ARGS+=(-f "tcp port ${PORT}")
fi
log "tshark args: ${ARGS[*]}"

# Initialize output file. Use , as separator.
echo "metric_value,timestamp,unit,device_id,context" > "${OUT}"
while true
do
  # With Tshark
  # You should add your user to wireshark group: gpasswd -a $USER wireshark
  bytes=$(tshark "${ARGS[@]}" 2>/dev/null | awk '/\|\s+BYTES\s+\|/ {getline;getline;print $6}')
  timestamp=$(echo "scale=2; $(date +%s%N)/1000000" | bc)

  log "bytes=$bytes"
  [ -z "${bytes}" ] && rate=0 || rate=$(echo "scale=2; $bytes*$MULTIPLIER/$DUR" | bc)
  log "rate=$rate"
  echo "${rate},${timestamp},${UNIT},$(hostname -f)," >> "${OUT}"
done
