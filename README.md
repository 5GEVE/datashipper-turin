# datashipper-turin

A collection of scripts to collect and publish infrastructure metrics on the 5G EVE platform.

## Install on site

Install everything by running the provided Ansible playbook:
```shell script
ansible-playbook -i "<host-ip-address>," install-filebeat.yml
```
*Note*: do not forget the comma after the `<host-ip-address>`

## Collectors

### [collect-data-rate.sh](collect-data-rate.sh)

Script to collect data rate for a use-case.
Traffic can be filtered by host and port.
Run `./collect-data-rate.sh -h` for available options.

*Requirements:*
- Install Tshark: `sudo apt install tshark`
- Add your user to `wireshark` group: `gpasswd -a $USER wireshark`
- Install Basic Calculator and GNU Awk: `sudo apt install bc gawk`

To test the script, let's generate some traffic.
Open a terminal and run:
```shell script
nc -vvlnp 12345 >/dev/null
```

The above will listen for incoming traffic.
`12345` is the port number.

Open another terminal and run:
```shell script
dd if=/dev/zero bs=1M | nc -vvn 127.0.0.1 12345
```
The above will send traffic to the previously created endpoint.

Run the script to collect traffic and compute data rate:

```shell script
./collect-data-rate.sh -i lo -p 12345 -a 127.0.0.1 -t 3 -o output/data-rate.csv -v
```

### [collect-tcp-avg-rtt.sh](collect-tcp-avg-rtt.sh)

Script to collect the average initial rtt (irtt) of TCP connections for a use-case.
Traffic can be filtered by host and port.
Run `./collect-tcp-avg-rtt.sh -h` for available options.

The script relies on `tcp.analysis.initial_rtt` field computed by Tshark.
To collect samples, the script needs to capture the TCP handshake at the beginning of new sessions (if TCP sessions are very long new values can be not available for a long time).
Thus, the script can produce a limited number of samples, not consistent with the `-t` parameter. 
Field `tcp.analysis.ack_rtt` could also be used but it doesn't work on mirrored traffic captures: only TCP connections to or from the capturing host work with this field.

*Requirements:*
- Install Tshark: `sudo apt install tshark`
- Add your user to `wireshark` group: `gpasswd -a $USER wireshark`
- Install Basic Calculator and GNU Awk: `sudo apt install bc gawk`

## Filebeat

Install [filebeat](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation.html).
Edit [filebeat.yml](filebeat.yml) and set the Kafka host and port.

```yaml
output.kafka:
  hosts: ["<host>:<port>"]
```

Move to the repo folder and run:

```shell script
filebeat -e
```

### As a Systemd service

If you want to run filebeat as a systemd service, override the default configuration file:

```shell script
sudo cp ./filebeat.yml /etc/filebeat/filebeat.yml
```

Then, set the absolute path for the file to monitor, for example:

```yaml
    paths:
        - /home/ubuntu/datashipper-turin/output/data-rate.csv
```

Start and optionally enable (start on boot) the service:

```shell script
sudo systemctl start filebeat.service
sudo systemctl enable filebeat.service
```

### Test with Kafka

Move to folder [kafka-docker](kafka-docker) and run

```shell script
export DOCKER_HOST_IP=<host-ip-address>
docker-compose up -d
```

*Note* Set `DOCKER_HOST_IP` if you want to reach Kafka from outside your machine.

Now you have a Kafka broker and a zookeeper instance on your local machine.
Set host and port in your `filebeat.yml` like this:

```
output.kafka:
  hosts: ["localhost:9092"]
```

Run filebeat like shown above. In the log you should see something like:

```
2020-08-18T15:23:56.040+0200    INFO    [publisher_pipeline_output]     pipeline/output.go:111      Connection to kafka(localhost:9092) established
```

Then, run the [collection script](collect-data-rate.sh) as shown above.
The filebeat will monitor the output file, read any new line and send it to Kafka in JSON format.

To read Kafka messages you need to install a Kafka client.
We use [kafkacat](https://github.com/edenhill/kafkacat).

If you are on Ubuntu, simply run:

```shell script
sudo apt install kafkacat

# List topics
kafkacat -b localhost:9092 -L

# Read messages from topics
kafkacat -b kafka-test.polito.it:9092 -C -t user_data_rate
```
