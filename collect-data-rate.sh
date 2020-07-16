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
echo "\
${__base}.sh [OPTION...]
-h            Print this help and exit
-i <name>     Set interface name
-p <port>     Set tcp port to capture
-d <seconds>  Set capture duration
" | column -t -s ";"
}

while getopts ":hi:p:d:" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    i )
      IFACE=${OPTARG}
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
tshark --interface ${IFACE} \
        -f "tcp port ${PORT}" \
        -q \
        -z conv,tcp \
        --autostop duration:${DUR}

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
#iftop -nN -p -i ${IFACE} -f "tcp port ${PORT}" -t -L 0 -s ${DUR}

# With ifstat (http://gael.roualland.free.fr/ifstat/)
# Nice to parse, does not support filters.
#ifstat2 -t -i ${IFACE} ${DUR}
