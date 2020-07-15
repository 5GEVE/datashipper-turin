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
-d <seconds>  Set capture duration
" | column -t -s ";"
}

while getopts ":hi:d:" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    i )
      IFACE=${OPTARG}
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
tshark --interface ${IFACE} -q -z conv,tcp --autostop duration:${DUR}

# With iftop

# With ifstat