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
-i <name>     Set interface name (default: gateway interface from 'ip route')
-p <port>     Set tcp port to capture (default: 80)
-d <seconds>  Set capture duration in seconds (default: 1)
-o <filename> Set output file name (default: data-rate.csv)
-v            Set verbose output
" | column -t -s ";"
}

# defaults
INTERFACE=$(ip route | awk '$1 == "default" {print $5; exit}')
PORT=80
DUR=1
VERBOSE=0
OUT="data-rate.csv"
while getopts ":hi:p:d:o:v" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    i )
      INTERFACE=${OPTARG}
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

# Initialize output file. Use ; as separator.
echo "timestamp;rate" > "${OUT}"

while true
do
  # With Tshark
  # You should add your user to wireshark group: gpasswd -a $USER wireshark
  bytes=$(tshark --interface "${INTERFACE}" \
          -f "tcp port ${PORT}" \
          --autostop duration:"${DUR}" \
          -q \
          -z io,stat,0,BYTES \
          2>/dev/null | awk '/\|\s+BYTES\s+\|/ {getline;getline;print $6}')
  log "bytes=$bytes"
  [ -z "${bytes}" ] && rate=0 || rate=$(echo "scale=2; $bytes/$DUR" | bc)
  log "rate=$rate"
  echo "$(date --iso-8601='seconds');${rate}" >> "${OUT}"
done

# With iftop
# -n                  don't do hostname lookups
# -N                  don't convert port numbers to services
# -p                  run in promiscuous mode
# -i interface        listen on named interface
# -f filter code      use filter code to select packets to count (default: none, but only IP packets are counted)
# -t                  use text interface without ncurses
# -s num              print one single text output afer num seconds, then quit
# -L num              number of lines to print
# WARNING: if filter does not match anything, it never exits
#while true
#do
#  rate=$(iftop -nN -p -i "${INTERFACE}" -f "tcp port ${PORT}" -t -L 0 -s "${DUR}" 2>/dev/null | awk '/send and receive/ {print $8}')
#  echo "$(date --iso-8601='seconds');${rate}" >> "${OUT}"
#done

# With ifstat (http://gael.roualland.free.fr/ifstat/)
# Nice to parse, does not support filters.
#ifstat2 -t -i ${INTERFACE} ${DUR}
