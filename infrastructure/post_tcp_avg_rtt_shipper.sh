#!/usr/bin/env bash
set -euo pipefail

IWFREPO_HOST=localhost
IWFREPO_PORT=8087
SITE_ID=1

dataShipperId=ITALY_TURIN.LATENCY_USERPLANE.tcp_avg_rtt
ipAddress=10.50.7.24
username=root
password=password
captureInterface=br_floating
metricType=LATENCY_USERPLANE
scriptName=collect_tcp_avg_rtt

# Do not change anything below this line
generate_post_data()
{
  cat <<EOF
{
  "dataShipperId": "${dataShipperId}",
  "ipAddress": "${ipAddress}",
  "username": "${username}",
  "password": "${password}",
  "metricType": "${metricType}",
  "configurationScript": "EXECUTE_COMMAND sudo /opt/datashipper/add_input_config \$\$topic_name; \
EXECUTE_COMMAND nohup sudo /opt/datashipper/${scriptName} -m -i ${captureInterface} \
-d ${dataShipperId} \
-a \$\$vnfIpAddresses \
-o /opt/datashipper/output/\$\$topic_name \
>/dev/null 2>&1 < /dev/null &;",
  "stopConfigScript": "EXECUTE_COMMAND sudo /opt/datashipper/add_input_config -r \$\$topic_name;"
}
EOF
}

SITES_LINK=$(curl --request POST \
  --url http://${IWFREPO_HOST}:${IWFREPO_PORT}/dataShippers \
  --header 'content-type: application/json' \
  --data "$(generate_post_data)" | jq -r ._links.site.href);

curl --request PUT \
  --url "${SITES_LINK}" \
  --header 'content-type: text/uri-list' \
  --data http://${IWFREPO_HOST}:${IWFREPO_PORT}/sites/"${SITE_ID}";
