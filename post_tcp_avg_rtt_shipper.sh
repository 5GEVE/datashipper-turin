#!/usr/bin/env bash

IWFREPO_HOST=localhost
IWFREPO_PORT=8087
SITE_ID=1

dataShipperId=ITALY_TURIN.LATENCY_USERPLANE.tcp_avg_rtt
ipAddress=10.50.7.24
username=root
password=password
captureInterface=ens4

# Do not change anything below this line
generate_post_data()
{
  cat <<EOF
{
  "dataShipperId": "${dataShipperId}",
  "ipAddress": "${ipAddress}",
  "username": "${username}",
  "password": "${password}",
  "metricType": "LATENCY_USERPLANE",
  "configurationScript": "EXECUTE_COMMAND /opt/datashipper/add_input_config \$\$topic_name; \
EXECUTE_COMMAND nohup /opt/datashipper/collect-tcp-avg-rtt -m -i ${captureInterface} \
-d ${dataShipperId} \
-o /opt/datashipper/output/\$\$topic_name.csv \
>/dev/null 2>&1 < /dev/null &;",
  "stopConfigScript": "EXECUTE_COMMAND pkill --full --oldest \$\$topic_name; \
EXECUTE_COMMAND rm /opt/datashipper/configs/\$\$topic_name.yml; \
EXECUTE_COMMAND sleep 2 && rm /opt/datashipper/output/\$\$topic_name.csv;"
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
