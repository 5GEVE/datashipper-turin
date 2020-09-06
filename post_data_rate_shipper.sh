#!/usr/bin/env bash

# This needs jq, uuidgen (from e2fsprogs)

HOST=localhost
PORT=8087
SITE_ID=2 # Italy default
N=1 # Number of shippers to be generated

generate_post_data()
{
  cat <<EOF
{
  "dataShipperId": "SPAIN_5TONIC.CPU_CONSUMPTION.example",
  "ipAddress": "10.9.8.208",
  "username": "user",
  "password": "root",
  "configurationScript": "INSTALL_FILEBEAT \$\$ipAddress \$\$username:\$\$password \$\$metric_id \$\$topic_name \$\$broker_ip_address \$\$unit \$\$interval nil /var/log/\$\$metric_id.log;",
  "stopConfigScript": "EXECUTE_COMMAND \$\$ipAddress \$\$username:\$\$password sudo systemctl stop filebeat && echo end > /home/user/end;",
  "metricType": "CPU_CONSUMPTION"
}
EOF
}

for ((i=1;i<=N;i++));
do
  printf "generating shipper %s\n" "${i}"
  SITES_LINK=$(curl --request POST \
    --url http://${HOST}:${PORT}/dataShippers \
    --header 'content-type: application/json' \
    --data "$(generate_post_data)" | jq -r ._links.site.href);

  curl --request PUT \
    --url "${SITES_LINK}" \
    --header 'content-type: text/uri-list' \
    --data http://${HOST}:${PORT}/sites/"${SITE_ID}";
done
