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
echo "Usage: sudo ${__base}.sh"
}

while getopts ":h" opt; do
  case ${opt} in
    h )
      usage
      exit 0
      ;;
    \? )
      usage
      exit 2
      ;;
  esac
done

if [ "$EUID" -ne 0 ]; then
	usage
	exit 1
fi

function log() {
  echo -e "$(date --iso-8601='seconds') - $*"
}

log "install dependencies..."
apt install tshark bc gawk procps
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.8.1-amd64.deb
dpkg -i filebeat-7.8.1-amd64.deb

DATA_RATE="/opt/data-rate"
log "create ${DATA_RATE} and install script..."
log "install scripts in ${DATA_RATE}"
sudo mkdir -p "${DATA_RATE}"
sudo cp collect-data-rate.sh "${DATA_RATE}/collect-data-rate"
sudo chmod -R 755 "${DATA_RATE}"

TCP_AVG_RTT="/opt/tcp_avg_rtt"
log "create ${TCP_AVG_RTT} and install script..."
log "install scripts in ${TCP_AVG_RTT}"
sudo mkdir -p "${TCP_AVG_RTT}"
sudo cp collect-tcp-avg-rtt.sh "${TCP_AVG_RTT}/collect-tcp-avg-rtt"
sudo chmod -R 755 "${TCP_AVG_RTT}"

log "install filebeat configuration..."
mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.bak
cp filebeat.yml /etc/filebeat/filebeat.yml