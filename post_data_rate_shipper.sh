#!/usr/bin/env bash

# This needs jq

HOST=localhost
PORT=8087
SITE_ID=1

generate_post_data()
{
  cat <<EOF
{
  "dataShipperId": "ITALY_TURIN.BANDWIDTH.data-rate",
  "ipAddress": "10.50.7.24",
  "username": "root",
  "password": "password",
  "configurationScript": "EXECUTE_COMMAND /opt/datashipper/add_input_config \$\$topic_name; \
EXECUTE_COMMAND /opt/datashipper/collect-data-rate -b -i ens4 \
-d \$\$dataShipperId \
-a \$\$vnf.419b1884-aea1-4cad-8647-c2cec55287b9.extcp.cp_tracker_ext_in.ipaddress \
-o /opt/datashipper/output/\$\$topic_name.csv;",
  "stopConfigScript": "EXECUTE_COMMAND pkill --full --oldest \$\$topic_name; \
EXECUTE_COMMAND rm /opt/datashipper/configs/\$\$topic_name.yml; \
EXECUTE_COMMAND sleep 2 && rm /opt/datashipper/output/\$\$topic_name.csv;",
  "metricType": "BANDWIDTH"
}
EOF
}

SITES_LINK=$(curl --request POST \
  --url http://${HOST}:${PORT}/dataShippers \
  --header 'content-type: application/json' \
  --data "$(generate_post_data)" | jq -r ._links.site.href);

curl --request PUT \
  --url "${SITES_LINK}" \
  --header 'content-type: text/uri-list' \
  --data http://${HOST}:${PORT}/sites/"${SITE_ID}";
