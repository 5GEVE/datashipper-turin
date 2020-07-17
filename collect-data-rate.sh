#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
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
" | column -t -s ";"
}

# defaults
INTERFACE=$(ip route | awk '$1 == "default" {print $5; exit}')
PORT=80
DUR=1
while getopts ":hi:p:d:" opt; do
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
    \? )
      usage
      exit 2
      ;;
  esac
done
shift $((OPTIND-1))

# With Tshark
#tshark --interface ${INTERFACE} \
#        -f "tcp port ${PORT}" \
#        -q \
#        -z conv,tcp \
#        --autostop duration:${DUR}

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
while true
do
  rate=$(iftop -nN -p -i "${INTERFACE}" -f "tcp port ${PORT}" -t -L 0 -s "${DUR}" 2>/dev/null | awk '/send and receive/ {print $8}')
  echo "${rate}"
done

# With ifstat (http://gael.roualland.free.fr/ifstat/)
# Nice to parse, does not support filters.
#ifstat2 -t -i ${INTERFACE} ${DUR}
